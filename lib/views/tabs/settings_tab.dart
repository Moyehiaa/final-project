import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sound2sign/viewmodels/auth_viewmodel.dart';
import '../../const.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../widgets/settings_tile.dart';
import '../auth/role_selection_view.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(),
      child: Consumer<SettingsViewModel>(
        builder: (context, vm, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Settings",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 12),

                SettingsTile(
                  icon: Icons.vibration_rounded,
                  title: "Vibration",
                  subtitle: "Enable vibration alerts",
                  trailing: Switch(
                    value: vm.vibration,
                    activeThumbColor: kAccent,
                    onChanged: vm.setVibration,
                  ),
                ),
                const SizedBox(height: 10),

                SettingsTile(
                  icon: Icons.notifications_rounded,
                  title: "Notifications",
                  subtitle: "Enable push notifications",
                  trailing: Switch(
                    value: vm.notifications,
                    activeThumbColor: kAccent,
                    onChanged: vm.setNotifications,
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_rounded, color: kAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          auth.currentUser?.email ?? "Not logged in",
                          style: const TextStyle(color: kText2),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      auth.logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RoleSelectionView(),
                        ),
                        (_) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: kDanger.withOpacity(0.6)),
                      foregroundColor: kDanger,
                    ),
                    child: const Text(
                      "Logout",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
