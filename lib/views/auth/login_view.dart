import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
import '../../models/user_role.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/primary_button.dart';
import '../shell/deaf_shell_view.dart';
import '../shell/caregiver_shell_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _routeAfterAuth(BuildContext context, UserRole role) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => role == UserRole.deaf
            ? const DeafShellView()
            : const CaregiverShellView(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBg,
          elevation: 0,
          title: const Text(
            "Login",
            style: TextStyle(color: kText, fontWeight: FontWeight.w900),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AuthTextField(
                controller: _email,
                label: "Email",
                hint: "name@example.com",
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _password,
                label: "Password",
                hint: "••••••••",
                obscure: true,
              ),
              const SizedBox(height: 10),

              if (auth.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kDanger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    auth.error!,
                    style: const TextStyle(color: kDanger),
                  ),
                ),

              const Spacer(),

              PrimaryButton(
                label: "Login",
                loading: auth.isLoading,
                onPressed: () async {
                  final ok = await auth.login(
                    email: _email.text,
                    password: _password.text,
                  );
                  if (!context.mounted) return;
                  if (ok && auth.currentUser != null) {
                    _routeAfterAuth(context, auth.currentUser!.role);
                  }
                },
              ),
              const SizedBox(height: 10),
              Text(
                "Role: ${auth.selectedRole == UserRole.deaf ? "Deaf user" : "Caregiver"}",
                style: const TextStyle(color: kText2),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
