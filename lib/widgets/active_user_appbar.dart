import 'package:flutter/material.dart';
import '../const.dart';

class ActiveUserAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final bool isActive;
  final bool isOnline;
  final VoidCallback onToggleOnline;

  const ActiveUserAppBar({
    super.key,
    required this.userName,
    required this.isActive,
    required this.isOnline,
    required this.onToggleOnline,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: kPrimary,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: kPrimary),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF2ECC71) : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$userName • ${isActive ? "Active" : "Away"}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: onToggleOnline,
          child: Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: isOnline ? const Color(0xFF2ECC71) : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  isOnline ? "Online" : "Offline",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
