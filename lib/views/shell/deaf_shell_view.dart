import 'package:flutter/material.dart';

import '../../const.dart';
import '../tabs/avatar_tab.dart';
import '../tabs/chat_tab.dart';
import '../tabs/deaf_home_tab.dart';
import '../tabs/settings_tab.dart';

class DeafShellView extends StatefulWidget {
  const DeafShellView({super.key});

  @override
  State<DeafShellView> createState() => _DeafShellViewState();
}

class _DeafShellViewState extends State<DeafShellView> {
  int _index = 0;

  final List<Widget> _tabs = const [
    HomeTab(),
    AvatarTab(),
    ChatTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: _tabs[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.hearing_outlined),
            selectedIcon: Icon(Icons.hearing_rounded),
            label: 'Avatar',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
