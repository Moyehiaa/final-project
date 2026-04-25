import 'package:flutter/material.dart';
import '../../const.dart';
import '../../widgets/primary_button.dart';

class AvatarTab extends StatelessWidget {
  const AvatarTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Avatar Translator",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: kText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "This module will translate chat messages into Arabic sign language using an animated avatar (coming soon).",
            style: TextStyle(color: kText2, height: 1.35),
          ),
          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            height: 240,
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.sign_language_rounded, size: 52, color: kAccent),
                  SizedBox(height: 10),
                  Text("Avatar Area", style: TextStyle(color: kText2)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          PrimaryButton(
            label: "Demo Translate",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Demo translation (placeholder)")),
              );
            },
          ),
        ],
      ),
    );
  }
}
