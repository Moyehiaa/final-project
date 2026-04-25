import 'package:flutter/material.dart';
import '../const.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const ChatBubble({super.key, required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? kPrimary : kSurface;
    final fg = isMe ? Colors.white : kText;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: isMe
              ? null
              : Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Text(
          text,
          style: TextStyle(color: fg, height: 1.3, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
