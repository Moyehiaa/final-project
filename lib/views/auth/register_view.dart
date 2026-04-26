import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../const.dart';
import '../../models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../shell/caregiver_shell_view.dart';
import '../shell/deaf_shell_view.dart';

class RegisterView extends StatefulWidget {
  final UserRole role;

  const RegisterView({super.key, required this.role});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final linkedEmailController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    linkedEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),

              const SizedBox(height: 18),

              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: kText,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                widget.role == UserRole.deaf
                    ? "Register as Deaf User"
                    : "Register as Caregiver",
                style: const TextStyle(color: kText2, height: 1.4),
              ),

              const SizedBox(height: 28),

              _inputField(
                controller: nameController,
                hint: "Full Name",
                icon: Icons.person_outline_rounded,
              ),

              const SizedBox(height: 14),

              _inputField(
                controller: emailController,
                hint: "Email",
                icon: Icons.email_outlined,
                keyboard: TextInputType.emailAddress,
              ),

              const SizedBox(height: 14),

              _inputField(
                controller: passwordController,
                hint: "Password",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),

              const SizedBox(height: 14),

              _inputField(
                controller: linkedEmailController,
                hint: widget.role == UserRole.deaf
                    ? "Caregiver Email"
                    : "Deaf User Email",
                icon: Icons.link_rounded,
                keyboard: TextInputType.emailAddress,
              ),

              const SizedBox(height: 10),

              Text(
                widget.role == UserRole.deaf
                    ? "Enter your caregiver email to link both accounts."
                    : "Enter the deaf user email to link both accounts.",
                style: const TextStyle(color: kText2, fontSize: 12),
              ),

              const SizedBox(height: 16),

              if (vm.error != null) _errorBox(vm.error!),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: vm.isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: vm.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Register",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              )
            : null,
        filled: true,
        fillColor: kSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    final vm = context.read<AuthViewModel>();

    final ok = await vm.register(
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
      role: widget.role,
      linkedEmail: linkedEmailController.text,
    );

    if (!mounted) return;

    if (ok) {
      final user = vm.currentUser!;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => user.role == UserRole.deaf
              ? const DeafShellView()
              : const CaregiverShellView(),
        ),
      );
    }
  }
}
