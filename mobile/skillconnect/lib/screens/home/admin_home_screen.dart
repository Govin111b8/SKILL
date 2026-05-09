import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    final name = user?['name'] ?? 'Admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            Text(
              'Welcome, $name 🔐',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Platform overview & management',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Platform stats
            Row(
              children: [
                _StatCard(
                  icon: Icons.people_rounded,
                  label: 'Total Users',
                  value: '—',
                  color: const Color(0xFF6366F1),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.event_note_rounded,
                  label: 'Active Bookings',
                  value: '—',
                  color: const Color(0xFF06B6D4),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Revenue',
                  value: '₹ —',
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.gavel_rounded,
                  label: 'Open Disputes',
                  value: '—',
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Quick actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _ActionTile(
              icon: Icons.people_rounded,
              title: 'Manage Users',
              subtitle: 'View, edit, or suspend user accounts',
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.verified_user_rounded,
              title: 'KYC Review',
              subtitle: 'Review pending verification requests',
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.assessment_rounded,
              title: 'View Reports',
              subtitle: 'Analytics, revenue, and growth reports',
              color: const Color(0xFF06B6D4),
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.gavel_rounded,
              title: 'Disputes',
              subtitle: 'Review and resolve open disputes',
              color: const Color(0xFFEF4444),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
