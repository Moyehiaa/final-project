import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/sound_detection_viewmodel.dart';

class SoundAlertHomePanel extends StatelessWidget {
  const SoundAlertHomePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SoundDetectionViewModel>();

    final label = vm.lastLabel;
    final score = vm.lastScore;
    final info = _SoundUiInfo.fromLabel(label);

    final hasSound = label != 'No sound' && label != 'other';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: hasSound ? info.color : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (hasSound ? info.color : Colors.black).withOpacity(0.22),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                hasSound ? info.icon : Icons.hearing_disabled_rounded,
                size: 90,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                hasSound ? info.title : 'LISTENING',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasSound
                    ? info.message
                    : vm.isListening
                    ? 'Waiting for important sounds'
                    : 'Tap start to begin detection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
              if (hasSound) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Confidence ${(score * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        ElevatedButton.icon(
          onPressed: vm.isListening ? vm.stop : vm.start,
          icon: Icon(
            vm.isListening
                ? Icons.stop_circle_rounded
                : Icons.play_circle_fill_rounded,
          ),
          label: Text(vm.isListening ? 'Stop Listening' : 'Start Listening'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Recent Alerts',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),

        const SizedBox(height: 12),

        if (vm.messages.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'No alerts yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          ...vm.messages.take(5).map((message) {
            final itemInfo = _SoundUiInfo.fromLabel(message.label);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: itemInfo.color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: itemInfo.color.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: itemInfo.color,
                    child: Icon(itemInfo.icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemInfo.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${(message.score * 100).toStringAsFixed(0)}% confidence',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
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
          color: Colors.grey,
        );
    }
  }
}
