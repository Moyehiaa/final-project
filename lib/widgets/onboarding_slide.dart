import 'package:flutter/material.dart';
import '../const.dart';
import '../models/onboarding_model.dart';
import 'illustration_card.dart';

class OnboardingSlide extends StatelessWidget {
  final OnboardingModel data;
  const OnboardingSlide({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          IllustrationCard(imagePath: data.imagePath),
          const SizedBox(height: 22),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: kText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.45, color: kText2),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
