import 'package:flutter/material.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  final AuthProvider auth;
  const SettingsScreen({super.key, required this.auth});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlCtrl = TextEditingController(text: ApiService.baseUrl);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('API Server URL', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _urlCtrl,
          decoration: const InputDecoration(
            hintText: 'http://your-server:3000/api',
            prefixIcon: Icon(Icons.cloud_outlined),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () async {
            await ApiService.setBaseUrl(_urlCtrl.text.trim());
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API URL saved!')));
          },
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About SkillConnect'),
          subtitle: const Text('Version 1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout', style: TextStyle(color: Colors.red)),
          onTap: () => widget.auth.logout(),
        ),
      ]),
    );
  }
}
