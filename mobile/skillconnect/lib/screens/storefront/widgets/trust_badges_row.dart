import 'package:flutter/material.dart';
import '../../../models/models.dart';

class TrustBadgesRow extends StatelessWidget {
  final Professional professional;
  const TrustBadgesRow({super.key, required this.professional});

  @override
  Widget build(BuildContext context) {
    final p = professional;
    final badges = <_Badge>[];

    if (p.govIdVerified) {
      badges.add(_Badge(icon: Icons.verified_user, label: 'Verified', color: Colors.green));
    }
    if (p.responseTimeHours != null && p.responseTimeHours! < 2) {
      badges.add(_Badge(icon: Icons.flash_on, label: 'Fast Response', color: Colors.orange));
    }
    if (p.averageRating >= 4.5) {
      badges.add(_Badge(icon: Icons.star, label: 'Top Rated', color: Colors.amber));
    }
    if (p.completedJobs >= 50) {
      badges.add(_Badge(icon: Icons.workspace_premium, label: '${p.completedJobs}+ Jobs', color: Colors.blue));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: badges.map((b) => Chip(
          avatar: Icon(b.icon, size: 16, color: b.color),
          label: Text(b.label, style: const TextStyle(fontSize: 12)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        )).toList(),
      ),
    );
  }
}

class _Badge {
  final IconData icon;
  final String label;
  final Color color;
  _Badge({required this.icon, required this.label, required this.color});
}
