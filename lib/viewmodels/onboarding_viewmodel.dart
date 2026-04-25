import 'package:flutter/material.dart';
import '../models/onboarding_model.dart';

class OnboardingViewModel extends ChangeNotifier {
  final PageController controller = PageController();
  int index = 0;

  final List<OnboardingModel> pages = const [
    OnboardingModel(
      title: "Awareness, without sound",
      subtitle:
          "Understand surrounding sounds\nwith visual alerts and vibration.",
      imagePath: "assets/onboarding/ob1.png",
    ),
    OnboardingModel(
      title: "Critical sounds, instantly visible",
      subtitle:
          "Fire alarm, doorbell, vehicles, dog barking,\nand name calling detected quickly.",
      imagePath: "assets/onboarding/ob2.png",
    ),
    OnboardingModel(
      title: "Connected & protected",
      subtitle: "Chat with a caregiver and use SOS\nfor emergencies anytime.",
      imagePath: "assets/onboarding/ob3.png",
    ),
  ];

  bool get isLast => index == pages.length - 1;

  void onPageChanged(int i) {
    index = i;
    notifyListeners();
  }

  Future<void> next() async {
    if (!isLast) {
      await controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> back() async {
    if (index > 0) {
      await controller.previousPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
