import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/models.dart';

class ContactButtonsRow extends StatelessWidget {
  final Professional professional;
  const ContactButtonsRow({super.key, required this.professional});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = professional;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Get in Touch', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        // WhatsApp
        if (p.whatsappNumber != null && p.whatsappNumber!.isNotEmpty)
          _ContactButton(
            icon: Icons.chat,
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
            onTap: () => _launch('https://wa.me/${p.whatsappNumber}'),
          ),
        // Phone (email has phone from user record)
        if (p.email != null)
          _ContactButton(
            icon: Icons.email,
            label: 'Email',
            color: cs.primary,
            onTap: () => _launch('mailto:${p.email}'),
          ),
        // Instagram
        if (p.instagramHandle != null && p.instagramHandle!.isNotEmpty)
          _ContactButton(
            icon: Icons.camera_alt,
            label: 'Instagram',
            color: const Color(0xFFE4405F),
            onTap: () => _launch('https://instagram.com/${p.instagramHandle}'),
          ),
        // Website
        if (p.websiteUrl != null && p.websiteUrl!.isNotEmpty)
          _ContactButton(
            icon: Icons.language,
            label: 'Website',
            color: cs.secondary,
            onTap: () => _launch(p.websiteUrl!),
          ),
        const SizedBox(height: 24),
        // In-app message CTA
        FilledButton.icon(
          onPressed: () {
            // Navigate to messaging — can reuse existing chat navigation
            Navigator.pushNamed(context, '/messages');
          },
          icon: const Icon(Icons.message),
          label: const Text('Send Message'),
        ),
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ContactButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
