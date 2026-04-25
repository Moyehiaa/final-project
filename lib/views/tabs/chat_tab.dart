import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/chat_input_bar.dart';

class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(),
      child: Consumer<ChatViewModel>(
        builder: (context, vm, _) {
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: const Text(
                  "Chat",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: kText,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: vm.messages.length,
                  itemBuilder: (_, i) {
                    final m = vm.messages[i];
                    return ChatBubble(text: m.text, isMe: m.isMe);
                  },
                ),
              ),
              ChatInputBar(onSend: vm.send),
            ],
          );
        },
      ),
    );
  }
}
