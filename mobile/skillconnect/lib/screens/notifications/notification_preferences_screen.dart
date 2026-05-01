import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Smart push notification preferences screen.
/// Lets users control notification categories to avoid annoyance.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _transactional = true; // Always on
  bool _behavioral = true;
  bool _lifecycle = true;
  bool _promotional = false;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _behavioral = prefs.getBool('notif_behavioral') ?? true;
      _lifecycle = prefs.getBool('notif_lifecycle') ?? true;
      _promotional = prefs.getBool('notif_promotional') ?? false;
      _language = prefs.getString('notif_language') ?? 'en';
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool('notif_behavioral', _behavioral),
      prefs.setBool('notif_lifecycle', _lifecycle),
      prefs.setBool('notif_promotional', _promotional),
      prefs.setString('notif_language', _language),
    ]);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved ✓')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Category header
          Text('Notification Categories', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Choose what notifications you receive', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),

          _NotifTile(
            icon: Icons.receipt_long,
            title: 'Booking Updates',
            subtitle: 'Confirmations, assignments, completions',
            value: _transactional,
            onChanged: null, // Always on
            locked: true,
          ),
          _NotifTile(
            icon: Icons.lightbulb_outline,
            title: 'Smart Suggestions',
            subtitle: '"Plumber available nearby", "Need help with yesterday\'s search?"',
            value: _behavioral,
            onChanged: (v) => setState(() => _behavioral = v),
          ),
          _NotifTile(
            icon: Icons.history,
            title: 'Service Reminders',
            subtitle: '"It\'s been 30 days since last service"',
            value: _lifecycle,
            onChanged: (v) => setState(() => _lifecycle = v),
          ),
          _NotifTile(
            icon: Icons.local_offer,
            title: 'Offers & Promotions',
            subtitle: 'Max 1-2 per week',
            value: _promotional,
            onChanged: (v) => setState(() => _promotional = v),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Language preference
          Text('Notification Language', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('English'),
                selected: _language == 'en',
                onSelected: (s) { if (s) setState(() => _language = 'en'); },
              ),
              ChoiceChip(
                label: const Text('తెలుగు (Telugu)'),
                selected: _language == 'te',
                onSelected: (s) { if (s) setState(() => _language = 'te'); },
              ),
              ChoiceChip(
                label: const Text('हिंदी (Hindi)'),
                selected: _language == 'hi',
                onSelected: (s) { if (s) setState(() => _language = 'hi'); },
              ),
            ],
          ),

          const SizedBox(height: 32),
          FilledButton(
            onPressed: _save,
            child: const Text('Save Preferences'),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool locked;

  const _NotifTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: locked ? null : onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
