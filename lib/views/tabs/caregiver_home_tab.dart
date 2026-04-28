import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sound2sign/widgets/link_manager_card.dart';
import '../../widgets/link_request_card.dart';
import '../../const.dart';
import '../../viewmodels/auth_viewmodel.dart';

class CaregiverHomeTab extends StatelessWidget {
  const CaregiverHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;

    if (user == null) {
      return const Center(child: Text("User not found"));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome back",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: kText,
            ),
          ),
          Text(
            user.name.toUpperCase(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: kText,
            ),
          ),
          LinkManagerCard(currentUserId: user.uid),

          const SizedBox(height: 6),

          LinkRequestCard(currentUserId: user.uid),

          const SizedBox(height: 6),

          const Text(
            "Monitor the linked deaf user and receive sound alerts.",
            style: TextStyle(color: kText2, height: 1.4),
          ),

          const SizedBox(height: 18),

          _LinkedDeafUserCard(
            linkedUserId: user.linkedUserId,
            linkedUserEmail: user.linkedUserEmail,
          ),

          const SizedBox(height: 22),

          const Text(
            "Notifications",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: kText,
            ),
          ),

          const SizedBox(height: 10),

          _DeafNotificationsList(
            caregiverId: user.uid,
            deafUserId: user.linkedUserId,
          ),
        ],
      ),
    );
  }
}

class _LinkedDeafUserCard extends StatelessWidget {
  final String? linkedUserId;
  final String? linkedUserEmail;

  const _LinkedDeafUserCard({
    required this.linkedUserId,
    required this.linkedUserEmail,
  });

  @override
  Widget build(BuildContext context) {
    if (linkedUserId == null || linkedUserId!.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.link_off_rounded, color: Colors.orange, size: 34),
            const SizedBox(height: 12),
            const Text(
              "No deaf user connected yet",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: kText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              linkedUserEmail == null || linkedUserEmail!.isEmpty
                  ? "You are not linked to any deaf user."
                  : "Waiting for: $linkedUserEmail",
              style: const TextStyle(color: kText2, height: 1.4),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(linkedUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingCard();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _errorCard("Linked deaf user profile not found");
        }

        final data = snapshot.data!.data() ?? {};

        final name = data['name'] ?? 'Deaf User';
        final email = data['email'] ?? '';
        final isOnline = data['isOnline'] == true;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.hearing_disabled_rounded,
                  color: kAccent,
                  size: 32,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: kText,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(color: kText2, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline ? "Online" : "Offline",
                          style: TextStyle(
                            color: isOnline ? Colors.green : kText2,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _loadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }
}

class _DeafNotificationsList extends StatelessWidget {
  final String caregiverId;
  final String? deafUserId;

  const _DeafNotificationsList({
    required this.caregiverId,
    required this.deafUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (deafUserId == null || deafUserId!.isEmpty) {
      return _emptyBox("No notifications because no deaf user is connected.");
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('alerts')
          .where('toUserId', isEqualTo: caregiverId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _emptyBox(
            "Could not load notifications. Check Firestore index/rules.",
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _emptyBox("No sound notifications yet.");
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();

            final message = data['message'] ?? 'Sound detected';
            final label = data['soundLabel'] ?? '';
            final score = data['score'];
            final seen = data['seen'] == true;

            final timestamp = data['createdAt'];
            String timeText = '';

            if (timestamp is Timestamp) {
              final time = timestamp.toDate();
              timeText =
                  "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
            }

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: seen ? kSurface : kAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: seen
                      ? Colors.black.withOpacity(0.05)
                      : kAccent.withOpacity(0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    seen
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_rounded,
                    color: seen ? kText2 : kAccent,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: const TextStyle(
                            color: kText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "$label ${score == null ? '' : '(${score.toStringAsFixed(2)})'}",
                          style: const TextStyle(color: kText2, fontSize: 12),
                        ),

                        if (timeText.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            timeText,
                            style: const TextStyle(color: kText2, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Text(text, style: const TextStyle(color: kText2, height: 1.4)),
    );
  }
}
