import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    (user?['name'] ?? '?')[0].toUpperCase(),
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: cs.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?['name'] ?? 'User', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(user?['email'] ?? '', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Chip(
                  label: Text((user?['role'] ?? 'customer').toString().toUpperCase(), style: const TextStyle(fontSize: 11)),
                  backgroundColor: cs.primaryContainer,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          // Info items
          Card(
            child: Column(children: [
              ListTile(leading: const Icon(Icons.phone), title: const Text('Phone'), subtitle: Text(user?['phone'] ?? 'Not set')),
              const Divider(height: 1),
              ListTile(leading: const Icon(Icons.location_on), title: const Text('Location'), subtitle: Text(user?['location'] ?? 'Not set')),
              const Divider(height: 1),
              ListTile(leading: const Icon(Icons.badge), title: const Text('Role'), subtitle: Text(user?['role'] ?? 'customer')),
            ]),
          ),
          const SizedBox(height: 16),
          // Actions
          Card(
            child: Column(children: [
              ListTile(
                leading: Icon(Icons.settings, color: Colors.grey.shade600),
                title: const Text('Settings'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.help_outline, color: Colors.grey.shade600),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                onTap: () {
                  auth.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
