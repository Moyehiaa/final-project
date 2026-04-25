import 'package:flutter/material.dart';
import '../const.dart';

class IllustrationCard extends StatelessWidget {
  final String imagePath;
  const IllustrationCard({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(
            child: Text(
              "Add image: $imagePath",
              style: const TextStyle(color: kText2),
            ),
          ),
        ),
      ),
    );
  }
}
