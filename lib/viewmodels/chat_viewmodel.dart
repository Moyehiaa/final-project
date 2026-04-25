import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';

class ChatViewModel extends ChangeNotifier {
  final List<ChatMessageModel> messages = [
    ChatMessageModel(
      text: "Hi! Are you okay?",
      isMe: false,
      time: DateTime.now(),
    ),
    ChatMessageModel(text: "Yes, I'm fine.", isMe: true, time: DateTime.now()),
  ];

  void send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    messages.add(ChatMessageModel(text: t, isMe: true, time: DateTime.now()));
    notifyListeners();
  }
}
