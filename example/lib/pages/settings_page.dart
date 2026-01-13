/// Settings page with logout functionality.
library;

import 'package:flutter/material.dart';
import 'package:routing_composer/routing_composer.dart';
import '../core/services/auth_service.dart';
import '../widgets/common/common.dart';

/// Settings screen with account options and logout.
class SettingsPage extends StatelessWidget {
  final AppRouter router;
  final ExampleAuthService authService;

  const SettingsPage({
    super.key,
    required this.router,
    required this.authService,
  });

  Future<void> _logout(BuildContext context) async {
    await authService.logout();
    await router.clearStackAndGoTo(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          const SettingsSection(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const SettingsSection(title: 'Privacy'),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Privacy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const SettingsSection(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
