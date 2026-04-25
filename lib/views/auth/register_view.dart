import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
import '../../models/user_role.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/primary_button.dart';
import '../shell/deaf_shell_view.dart';
import '../shell/caregiver_shell_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
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
            "Create account",
            style: TextStyle(color: kText, fontWeight: FontWeight.w900),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AuthTextField(
                controller: _name,
                label: "Full name",
                hint: "Ahmed Mohamed",
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              AuthTextField(
                controller: _confirm,
                label: "Confirm password",
                hint: "••••••••",
                obscure: true,
              ),
              const SizedBox(height: 10),

              if (_password.text.isNotEmpty &&
                  _confirm.text.isNotEmpty &&
                  _password.text != _confirm.text)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kDanger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    "Passwords do not match",
                    style: TextStyle(color: kDanger),
                  ),
                ),

              if (auth.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
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
                ),

              const Spacer(),

              PrimaryButton(
                label: "Create account",
                loading: auth.isLoading,
                onPressed: () async {
                  if (_password.text != _confirm.text) {
                    // quick client-side check
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Passwords do not match")),
                    );
                    return;
                  }

                  final ok = await auth.register(
                    name: _name.text,
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
