import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
import '../../models/user_role.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/role_card.dart';
import 'login_view.dart';
import 'register_view.dart';

class RoleSelectionView extends StatelessWidget {
  const RoleSelectionView({super.key});

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
            "Choose your role",
            style: TextStyle(color: kText, fontWeight: FontWeight.w900),
          ),
          centerTitle: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              RoleCard(
                icon: Icons.hearing_disabled_rounded,
                title: "Deaf user",
                subtitle: "I need sound awareness and sign language support.",
                selected: auth.selectedRole == UserRole.deaf,
                onTap: () => auth.selectRole(UserRole.deaf),
              ),
              const SizedBox(height: 12),
              RoleCard(
                icon: Icons.family_restroom_rounded,
                title: "Caregiver",
                subtitle: "I monitor alerts and chat to support the user.",
                selected: auth.selectedRole == UserRole.caregiver,
                onTap: () => auth.selectRole(UserRole.caregiver),
              ),
              const Spacer(),

              PrimaryButton(
                label: "Continue to Login",
                onPressed: auth.selectedRole == null
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginView()),
                      ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: auth.selectedRole == null
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterView()),
                      ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text("Create an account"),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
