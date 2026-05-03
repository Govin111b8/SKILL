import 'package:flutter/material.dart';
import '../../services/storefront_service.dart';
import '../../services/api_service.dart';
import 'storefront_screen.dart';

class StorefrontSetupScreen extends StatefulWidget {
  final String professionalId;
  const StorefrontSetupScreen({super.key, required this.professionalId});

  @override
  State<StorefrontSetupScreen> createState() => _StorefrontSetupScreenState();
}

class _StorefrontSetupScreenState extends State<StorefrontSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;

  final _announcementCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _accentColorCtrl = TextEditingController();
  final _returnPolicyCtrl = TextEditingController();
  final _operatingHoursCtrl = TextEditingController();
  final _operatingDaysCtrl = TextEditingController();
  bool _showRating = true;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _announcementCtrl.dispose();
    _whatsappCtrl.dispose();
    _instagramCtrl.dispose();
    _websiteCtrl.dispose();
    _accentColorCtrl.dispose();
    _returnPolicyCtrl.dispose();
    _operatingHoursCtrl.dispose();
    _operatingDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    try {
      final data = await StorefrontService.fetchStorefront(widget.professionalId);
      _announcementCtrl.text = data['announcement'] ?? '';
      _whatsappCtrl.text = data['whatsapp_number'] ?? '';
      _instagramCtrl.text = data['instagram_handle'] ?? '';
      _websiteCtrl.text = data['website_url'] ?? '';
      _accentColorCtrl.text = data['accent_color'] ?? '#6366F1';
      _returnPolicyCtrl.text = data['return_policy'] ?? '';
      _operatingHoursCtrl.text = data['operating_hours'] ?? '';
      _operatingDaysCtrl.text = data['operating_days'] ?? '';
      _showRating = data['show_rating'] != false;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await StorefrontService.updateStorefront(widget.professionalId, {
        'announcement': _announcementCtrl.text.trim(),
        'whatsapp_number': _whatsappCtrl.text.trim(),
        'instagram_handle': _instagramCtrl.text.trim(),
        'website_url': _websiteCtrl.text.trim(),
        'accent_color': _accentColorCtrl.text.trim(),
        'show_rating': _showRating,
        'return_policy': _returnPolicyCtrl.text.trim(),
        'operating_hours': _operatingHoursCtrl.text.trim(),
        'operating_days': _operatingDaysCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storefront updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Setup Storefront')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Storefront'),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => StorefrontScreen(professionalId: widget.professionalId),
            )),
            child: const Text('Preview'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Announcement
            TextFormField(
              controller: _announcementCtrl,
              decoration: const InputDecoration(labelText: 'Announcement', hintText: 'e.g. 20% off this week!'),
              maxLength: 500,
            ),
            const SizedBox(height: 12),
            // Operating Hours
            TextFormField(
              controller: _operatingHoursCtrl,
              decoration: const InputDecoration(labelText: 'Operating Hours', hintText: 'e.g. 9 AM - 6 PM'),
            ),
            const SizedBox(height: 12),
            // Operating Days
            TextFormField(
              controller: _operatingDaysCtrl,
              decoration: const InputDecoration(labelText: 'Operating Days', hintText: 'e.g. Mon - Sat'),
            ),
            const SizedBox(height: 12),
            // WhatsApp
            TextFormField(
              controller: _whatsappCtrl,
              decoration: const InputDecoration(labelText: 'WhatsApp Number', hintText: '+91XXXXXXXXXX'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            // Instagram
            TextFormField(
              controller: _instagramCtrl,
              decoration: const InputDecoration(labelText: 'Instagram Handle', hintText: 'yourhandle'),
            ),
            const SizedBox(height: 12),
            // Website
            TextFormField(
              controller: _websiteCtrl,
              decoration: const InputDecoration(labelText: 'Website URL', hintText: 'https://example.com'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            // Accent colour
            TextFormField(
              controller: _accentColorCtrl,
              decoration: const InputDecoration(labelText: 'Accent Color (hex)', hintText: '#6366F1'),
              validator: (v) {
                if (v != null && v.isNotEmpty && !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(v)) {
                  return 'Must be hex e.g. #6366F1';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            // Return policy
            TextFormField(
              controller: _returnPolicyCtrl,
              decoration: const InputDecoration(labelText: 'Service Guarantee / Return Policy'),
              maxLines: 3,
              maxLength: 2000,
            ),
            const SizedBox(height: 12),
            // Show rating toggle
            SwitchListTile(
              title: const Text('Show Rating on Storefront'),
              value: _showRating,
              onChanged: (v) => setState(() => _showRating = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Storefront'),
            ),
          ],
        ),
      ),
    );
  }
}
