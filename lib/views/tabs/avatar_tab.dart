import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../const.dart';
import '../../viewmodels/sound_detection_viewmodel.dart';
import '../../widgets/primary_button.dart';

class AvatarTab extends StatelessWidget {
  const AvatarTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SoundDetectionViewModel>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sound Detection",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Icon(
                  vm.isListening ? Icons.graphic_eq_rounded : Icons.mic_off,
                  size: 60,
                  color: kAccent,
                ),
                const SizedBox(height: 12),
                Text(
                  vm.lastLabel,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Confidence: ${vm.lastScore.toStringAsFixed(2)}",
                  style: const TextStyle(color: kText2),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          PrimaryButton(
            label: vm.isListening ? "Stop Listening" : "Start Listening",
            onPressed: () {
              vm.isListening ? vm.stop() : vm.start();
            },
          ),
        ],
      ),
    );
  }
}
