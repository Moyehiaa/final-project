import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../const.dart';
import '../../models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../onboarding/onboarding_view.dart';
import '../shell/caregiver_shell_view.dart';
import '../shell/deaf_shell_view.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    final authVm = context.read<AuthViewModel>();

    await authVm.loadCurrentUser();

    if (!mounted) return;

    setState(() {
      _checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;

    if (!_checked) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return const OnboardingView();
    }

    if (user.role == UserRole.deaf) {
      return const DeafShellView();
    }

    return const CaregiverShellView();
  }
}
