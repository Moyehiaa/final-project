import 'package:flutter/material.dart';
import '../const.dart';

class PageDots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const PageDots({super.key, required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          height: 8,
          width: active ? 22 : 8,
          decoration: BoxDecoration(
            color: active ? kPrimary : Colors.black.withOpacity(0.12),
            borderRadius: BorderRadius.circular(50),
          ),
        );
      }),
    );
  }
}
