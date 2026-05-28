import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';
import 'admin_users_screen.dart';
import 'admin_kyc_screen.dart';
import 'admin_disputes_screen.dart';
import 'admin_complaints_screen.dart';
import 'admin_featured_slots_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get('/admin/stats', auth: true);
      _stats = Map<String, dynamic>.from((res['data'] as Map?) ?? const {});
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats ?? const <String, dynamic>{};
    final activity = (stats['recent_activity'] as List? ?? const []);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))])
            : _error != null
                ? ListView(children: [
                    EmptyStateWidget(
                      icon: Icons.dashboard_outlined,
                      iconColor: Colors.red,
                      title: 'Could not load admin dashboard',
                      subtitle: _error!,
                      actionLabel: 'Retry',
                      onAction: _load,
                    ),
                  ])
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                        children: [
                          _KpiCard(label: 'Total Users', value: '${stats['total_users'] ?? 0}', icon: Icons.people_outline_rounded),
                          _KpiCard(label: 'Active Bookings', value: '${stats['active_bookings'] ?? 0}', icon: Icons.calendar_month_rounded),
                          _KpiCard(label: 'Revenue Today', value: '₹${stats['revenue_today'] ?? 0}', icon: Icons.payments_outlined),
                          _KpiCard(label: 'Open Disputes', value: '${stats['open_disputes'] ?? 0}', icon: Icons.report_problem_outlined),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Quick actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.35,
                        children: [
                          _QuickCard(title: 'Manage Users', icon: Icons.manage_accounts_outlined, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen()))),
                          _QuickCard(title: 'Review KYC', icon: Icons.verified_user_outlined, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminKYCScreen()))),
                          _QuickCard(title: 'Resolve Disputes', icon: Icons.balance_outlined, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDisputesScreen()))),
                          _QuickCard(title: 'Manage Complaints', icon: Icons.report_gmailerrorred_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminComplaintsScreen()))),
                          _QuickCard(title: 'Featured Slots', icon: Icons.star_outline_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFeaturedSlotsScreen()))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Recent activity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      if (activity.isEmpty)
                        const EmptyStateWidget(
                          icon: Icons.history_toggle_off_rounded,
                          title: 'No recent activity',
                          subtitle: 'Recent admin actions will appear here.',
                        )
                      else
                        ...activity.take(5).map((item) {
                          final row = Map<String, dynamic>.from(item as Map);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                            child: ListTile(
                              leading: const Icon(Icons.shield_outlined),
                              title: Text(row['action']?.toString() ?? 'Admin action'),
                              subtitle: Text(row['timestamp']?.toString() ?? row['created_at']?.toString() ?? ''),
                              trailing: Text(row['actor']?.toString() ?? ''),
                            ),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _KpiCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label),
      ]),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
