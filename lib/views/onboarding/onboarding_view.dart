import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
import '../../viewmodels/onboarding_viewmodel.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/page_dots.dart';
import '../../widgets/onboarding_slide.dart';
import '../auth/role_selection_view.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  void _goRole(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: Consumer<OnboardingViewModel>(
        builder: (context, vm, _) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(
              backgroundColor: kBg,
              body: SafeArea(
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => _goRole(context),
                            child: const Text(
                              "Skip",
                              style: TextStyle(color: kText2),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),

                    Expanded(
                      child: PageView.builder(
                        controller: vm.controller,
                        itemCount: vm.pages.length,
                        onPageChanged: vm.onPageChanged,
                        itemBuilder: (_, i) =>
                            OnboardingSlide(data: vm.pages[i]),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 14),
                      child: PageDots(
                        count: vm.pages.length,
                        activeIndex: vm.index,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: PrimaryButton(
                        label: vm.isLast ? "Continue" : "Next",
                        onPressed: () {
                          if (vm.isLast) {
                            _goRole(context);
                          } else {
                            vm.next();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
