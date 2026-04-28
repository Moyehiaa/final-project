import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String getChatId(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Stream<List<ChatMessageModel>> messagesStream({
    required String currentUserId,
    required String otherUserId,
  }) {
    final chatId = getChatId(currentUserId, otherUserId);

    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessageModel.fromDoc(doc))
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String currentUserId,
    required String otherUserId,
    required String text,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final chatId = getChatId(currentUserId, otherUserId);

    final chatRef = _db.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    await _db.runTransaction((transaction) async {
      transaction.set(chatRef, {
        'chatId': chatId,
        'members': [currentUserId, otherUserId],
        'lastMessage': cleanText,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(messageRef, {
        'id': messageRef.id,
        'chatId': chatId,
        'senderId': currentUserId,
        'receiverId': otherUserId,
        'text': cleanText,
        'seen': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
