import 'package:flutter/material.dart';
import '../../../models/models.dart';

class ServiceInfoCard extends StatelessWidget {
  final Professional professional;
  const ServiceInfoCard({super.key, required this.professional});

  @override
  Widget build(BuildContext context) {
    final p = professional;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Availability
        _InfoTile(
          icon: Icons.circle,
          iconColor: p.availabilityStatus == 'available' ? Colors.green : Colors.grey,
          title: 'Availability',
          subtitle: (p.availabilityStatus ?? 'offline').replaceFirst(
            p.availabilityStatus?[0] ?? '',
            (p.availabilityStatus?[0] ?? '').toUpperCase(),
          ),
        ),
        // Operating hours
        if (p.operatingHours != null && p.operatingHours!.isNotEmpty)
          _InfoTile(icon: Icons.access_time, iconColor: cs.primary, title: 'Hours', subtitle: p.operatingHours!),
        // Operating days
        if (p.operatingDays != null && p.operatingDays!.isNotEmpty)
          _InfoTile(icon: Icons.calendar_today, iconColor: cs.primary, title: 'Days', subtitle: p.operatingDays!),
        // Experience
        if (p.yearsOfExperience != null)
          _InfoTile(icon: Icons.work, iconColor: cs.secondary, title: 'Experience', subtitle: '${p.yearsOfExperience} years'),
        // Pricing
        if (p.pricingEstimate != null)
          _InfoTile(icon: Icons.currency_rupee, iconColor: cs.tertiary, title: 'Pricing', subtitle: p.pricingEstimate!),
        // Return policy
        if (p.returnPolicy != null && p.returnPolicy!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Service Guarantee', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(p.returnPolicy!, style: const TextStyle(fontSize: 13)),
        ],
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  const _InfoTile({required this.icon, required this.iconColor, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
    );
  }
}
