import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../const.dart';
import '../../models/chat_message_model.dart';
import '../../models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/chat_input_bar.dart';

class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;

    if (user == null) {
      return const Center(child: Text("User not found"));
    }

    final otherUserId = user.linkedUserId;

    if (otherUserId == null || otherUserId.isEmpty) {
      return Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBg,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            "Chat",
            style: TextStyle(color: kText, fontWeight: FontWeight.w900),
          ),
        ),
        body: const _NoLinkedUserState(),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(),
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBg,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: _ChatAppBarTitle(
            otherUserId: otherUserId,
            currentUserRole: user.role,
          ),
        ),
        body: _ChatBody(currentUserId: user.uid, otherUserId: otherUserId),
      ),
    );
  }
}

class _ChatBody extends StatelessWidget {
  final String currentUserId;
  final String otherUserId;

  const _ChatBody({required this.currentUserId, required this.otherUserId});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ChatMessageModel>>(
            stream: vm.messagesStream(
              currentUserId: currentUserId,
              otherUserId: otherUserId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    "Could not load chat messages",
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              final messages = snapshot.data ?? [];

              if (messages.isEmpty) {
                return const _EmptyChatState();
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final message = messages[i];

                  return ChatBubble(
                    text: message.text,
                    isMe: message.isMe(currentUserId),
                    time: message.time,
                  );
                },
              );
            },
          ),
        ),
        ChatInputBar(
          onSend: (text) {
            return vm.send(
              currentUserId: currentUserId,
              otherUserId: otherUserId,
              text: text,
            );
          },
        ),
      ],
    );
  }
}

class _ChatAppBarTitle extends StatelessWidget {
  final String otherUserId;
  final UserRole currentUserRole;

  const _ChatAppBarTitle({
    required this.otherUserId,
    required this.currentUserRole,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackTitle = currentUserRole == UserRole.deaf
        ? "Caregiver"
        : "Deaf User";

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final name = data?['name'] ?? fallbackTitle;
        final isOnline = data?['isOnline'] == true;

        return Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: kAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                currentUserRole == UserRole.deaf
                    ? Icons.volunteer_activism_rounded
                    : Icons.hearing_disabled_rounded,
                color: kAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kText,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 9,
                        color: isOnline ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isOnline ? "Online" : "Offline",
                        style: const TextStyle(
                          color: kText2,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          "No messages yet.\nStart the conversation now.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kText2,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NoLinkedUserState extends StatelessWidget {
  const _NoLinkedUserState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          "No linked user yet.\nLink a deaf user and caregiver first.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kText2,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
