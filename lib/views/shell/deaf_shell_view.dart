import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../const.dart';
import '../../viewmodels/shell_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/active_user_appbar.dart';
import '../tabs/home_tab.dart';
import '../tabs/chat_tab.dart';
import '../tabs/avatar_tab.dart';
import '../tabs/settings_tab.dart';

class DeafShellView extends StatelessWidget {
  const DeafShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser;

    return ChangeNotifierProvider(
      create: (_) => ShellViewModel(),
      child: Consumer<ShellViewModel>(
        builder: (context, shell, _) {
          final tabs = const [HomeTab(), ChatTab(), AvatarTab(), SettingsTab()];

          return Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(
              backgroundColor: kBg,
              appBar: ActiveUserAppBar(
                userName: user?.name ?? "Deaf User",
                isActive: user?.isActive ?? true,
                isOnline: shell.isOnline,
                onToggleOnline: shell.toggleOnline,
              ),
              body: tabs[shell.tabIndex],
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: shell.tabIndex,
                onTap: shell.setTab,
                selectedItemColor: kAccent,
                unselectedItemColor: Colors.white.withOpacity(0.75),
                backgroundColor: kPrimary,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    label: "Home",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.chat_bubble_rounded),
                    label: "Chat",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.sign_language_rounded),
                    label: "Avatar",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_rounded),
                    label: "Settings",
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
