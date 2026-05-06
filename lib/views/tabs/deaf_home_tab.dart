import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sound2sign/widgets/link_manager_card.dart';

import '../../const.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/sound_detection_viewmodel.dart';
import '../../widgets/link_request_card.dart';

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
            _LiveSoundAlertCard(soundVm: soundVm),

            const SizedBox(height: 20),

            LinkManagerCard(currentUserId: user.uid),

            const SizedBox(height: 20),

            LinkRequestCard(currentUserId: user.uid),

            const SizedBox(height: 24),

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

            const SizedBox(height: 24),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Recent Sound Alerts",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: kText,
                    ),
                  ),
                ),
                if (soundVm.messages.isNotEmpty)
                  TextButton.icon(
                    onPressed: soundVm.clearMessages,
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: const Text("Clear"),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            if (soundVm.messages.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.notifications_none_rounded, color: kText2),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "No alerts yet. Start listening to detect important sounds.",
                        style: TextStyle(
                          color: kText2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: soundVm.messages.take(8).map((msg) {
                  final info = _SoundUiInfo.fromLabel(msg.label);

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: info.color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: info.color.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: info.color,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(info.icon, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                info.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${(msg.score * 100).toStringAsFixed(0)}% confidence",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: kText2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _LiveSoundAlertCard extends StatelessWidget {
  final SoundDetectionViewModel soundVm;

  const _LiveSoundAlertCard({required this.soundVm});

  @override
  Widget build(BuildContext context) {
    final hasSound =
        soundVm.lastLabel != 'No sound' && soundVm.lastLabel != 'other';

    final info = _SoundUiInfo.fromLabel(soundVm.lastLabel);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: hasSound ? info.color : kSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: hasSound ? info.color : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: (hasSound ? info.color : Colors.black).withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 106,
            height: 106,
            decoration: BoxDecoration(
              color: hasSound
                  ? Colors.white.withOpacity(0.22)
                  : kAccent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSound ? info.icon : Icons.hearing_disabled_rounded,
              size: 58,
              color: hasSound ? Colors.white : kAccent,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hasSound
                ? info.title
                : soundVm.isListening
                ? "LISTENING"
                : "NOT LISTENING",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: hasSound ? Colors.white : kText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSound
                ? info.message
                : soundVm.isListening
                ? "Waiting for important sounds"
                : "Start listening from Avatar tab",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: hasSound ? Colors.white.withOpacity(0.95) : kText2,
            ),
          ),
          if (hasSound) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                "Confidence ${(soundVm.lastScore * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SoundUiInfo {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const _SoundUiInfo({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  factory _SoundUiInfo.fromLabel(String label) {
    switch (label) {
      case 'alarm':
        return const _SoundUiInfo(
          title: 'ALARM',
          message: 'Danger alert. Check now.',
          icon: Icons.warning_amber_rounded,
          color: Color(0xFFD32F2F),
        );
      case 'siren':
        return const _SoundUiInfo(
          title: 'SIREN',
          message: 'Emergency sound nearby.',
          icon: Icons.local_police_rounded,
          color: Color(0xFFC62828),
        );
      case 'baby_cry':
        return const _SoundUiInfo(
          title: 'BABY CRY',
          message: 'Baby may need attention.',
          icon: Icons.child_care_rounded,
          color: Color(0xFF1976D2),
        );
      case 'glass_breaking':
        return const _SoundUiInfo(
          title: 'GLASS BREAKING',
          message: 'Possible danger. Check area.',
          icon: Icons.broken_image_rounded,
          color: Color(0xFFB71C1C),
        );
      case 'knock':
        return const _SoundUiInfo(
          title: 'KNOCK',
          message: 'Someone may be at the door.',
          icon: Icons.front_hand_rounded,
          color: Color(0xFF795548),
        );
      case 'bell':
        return const _SoundUiInfo(
          title: 'BELL',
          message: 'Bell sound detected.',
          icon: Icons.notifications_active_rounded,
          color: Color(0xFFF9A825),
        );
      case 'phone_ring':
        return const _SoundUiInfo(
          title: 'PHONE RING',
          message: 'Your phone may be ringing.',
          icon: Icons.phone_in_talk_rounded,
          color: Color(0xFF2E7D32),
        );
      case 'dog':
        return const _SoundUiInfo(
          title: 'DOG',
          message: 'Dog sound detected.',
          icon: Icons.pets_rounded,
          color: Color(0xFFEF6C00),
        );
      case 'speech':
        return const _SoundUiInfo(
          title: 'SPEECH',
          message: 'Someone may be speaking.',
          icon: Icons.record_voice_over_rounded,
          color: Color(0xFF616161),
        );
      default:
        return const _SoundUiInfo(
          title: 'LISTENING',
          message: 'Waiting for important sounds.',
          icon: Icons.hearing_disabled_rounded,
          color: kAccent,
        );
    }
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
