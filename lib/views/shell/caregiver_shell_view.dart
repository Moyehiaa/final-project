import 'package:flutter/material.dart';

import '../../const.dart';
import '../tabs/caregiver_home_tab.dart';
import '../tabs/chat_tab.dart';
import '../tabs/settings_tab.dart';

class CaregiverShellView extends StatefulWidget {
  const CaregiverShellView({super.key});

  @override
  State<CaregiverShellView> createState() => _CaregiverShellViewState();
}

class _CaregiverShellViewState extends State<CaregiverShellView> {
  int _index = 0;

  final List<Widget> _tabs = const [
    CaregiverHomeTab(),
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
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
