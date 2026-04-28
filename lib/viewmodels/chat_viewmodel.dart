import 'package:flutter/material.dart';

import '../models/chat_message_model.dart';
import '../services/chat_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  Stream<List<ChatMessageModel>> messagesStream({
    required String currentUserId,
    required String otherUserId,
  }) {
    return _chatService.messagesStream(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
    );
  }

  Future<void> send({
    required String currentUserId,
    required String otherUserId,
    required String text,
  }) async {
    await _chatService.sendMessage(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      text: text,
    );
  }
}
