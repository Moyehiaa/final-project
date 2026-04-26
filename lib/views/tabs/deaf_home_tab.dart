import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../const.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/sound_detection_viewmodel.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final soundVm = context.watch<SoundDetectionViewModel>();

    final user = authVm.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not found")));
    }

    return Scaffold(
      backgroundColor: kBg,

      // ✅ APP BAR باسم المستخدم
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Deaf User",
              style: TextStyle(fontSize: 14, color: kText2),
            ),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: kText,
              ),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 caregiver card
            const Text(
              "Your Caregiver",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: kText,
              ),
            ),

            const SizedBox(height: 10),

            _CaregiverCard(
              caregiverId: user.linkedUserId,
              caregiverEmail: user.linkedUserEmail,
            ),

            const SizedBox(height: 20),

            const Text(
              "Avatar Messages",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: kText,
              ),
            ),

            const SizedBox(height: 10),

            if (soundVm.messages.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  "No messages yet. Start listening from Avatar tab.",
                  style: TextStyle(color: kText2),
                ),
              )
            else
              Column(
                children: soundVm.messages.map((msg) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          color: kAccent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "${msg.label} (${msg.score.toStringAsFixed(2)})",
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: kText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 10),

            if (soundVm.messages.isNotEmpty)
              OutlinedButton(
                onPressed: soundVm.clearMessages,
                child: const Text("Clear Messages"),
              ),
          ],
        ),
      ),
    );
  }
}

class _CaregiverCard extends StatelessWidget {
  final String? caregiverId;
  final String? caregiverEmail;

  const _CaregiverCard({
    required this.caregiverId,
    required this.caregiverEmail,
  });

  @override
  Widget build(BuildContext context) {
    if (caregiverId == null || caregiverId!.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          caregiverEmail == null
              ? "No caregiver connected"
              : "Waiting for: $caregiverEmail",
          style: const TextStyle(color: kText2),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(caregiverId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _errorCard();
        }

        final data = snapshot.data!.data()!;
        final name = data['name'] ?? 'Caregiver';
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
                child: const Icon(Icons.person_rounded, color: kAccent),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: kText,
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

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Text(
        "Could not load caregiver data",
        style: TextStyle(color: Colors.red),
      ),
    );
  }
}
