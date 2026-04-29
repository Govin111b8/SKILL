import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../settings/settings_screen.dart';
import '../kyc/kyc_screen.dart';
import '../contacts/my_contacts_screen.dart';
import '../profile/edit_professional_profile_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../favorites/favorites_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _dashData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/dashboard', auth: true);
      _dashData = res['data'];
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _updateContactStatus(String contactId, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiService.put('/contacts/$contactId/status', {'status': status}, auth: true);
      _load();
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Contact ${status == 'accepted' ? 'accepted' : 'declined'}'),
          backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
        ));
      }
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final cs = Theme.of(context).colorScheme;
    final isPro = auth.isProfessional;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
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
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Chip(
                      label: Text((user?['role'] ?? 'customer').toString().toUpperCase(), style: const TextStyle(fontSize: 11)),
                      backgroundColor: cs.primaryContainer,
                    ),
                    if (user?['location'] != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                      Text(user!['location'], style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ]),
                ]),
              ),
            ),
            // Quick action buttons
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  _actionButton(Icons.mail, 'Contacts', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyContactsScreen()))),
                  const SizedBox(width: 8),
                  if (!isPro) ...[
                    _actionButton(Icons.favorite, 'Saved', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
                    const SizedBox(width: 8),
                  ],
                  _actionButton(Icons.verified_user_rounded, 'KYC', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen()))),
                  const SizedBox(width: 8),
                  _actionButton(Icons.settings, 'Settings', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                  if (isPro) ...[
                    const SizedBox(width: 8),
                    _actionButton(Icons.edit, 'Edit Profile', () async {
                      if (_dashData?['profile'] != null) {
                        final result = await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => EditProfessionalProfileScreen(profile: _dashData!['profile']),
                        ));
                        if (result == true) _load();
                      }
                    }),
                    const SizedBox(width: 8),
                    _actionButton(Icons.photo_library, 'Portfolio', () {
                      final profileId = _dashData?['profile']?['id'];
                      if (profileId != null) {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PortfolioScreen(professionalId: profileId, isOwner: true),
                        ));
                      }
                    }),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 16),
            // Stats
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_error != null)
              Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
                const Icon(Icons.cloud_off, size: 36, color: Colors.grey),
                const SizedBox(height: 8),
                Text('Could not load dashboard', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _load, child: const Text('Retry')),
              ])))
            else if (isPro) ..._buildProDashboard(context, cs)
            else ..._buildCustomerDashboard(context, cs),
            const SizedBox(height: 16),
            // Sign out
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                onTap: () {
                  auth.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _bookingColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'disputed': return Colors.deepOrange;
      case 'in_progress': case 'scheduled': return Colors.blue;
      case 'accepted': case 'quoted': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  String _money(num v) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(v);
  }

  List<Widget> _buildProDashboard(BuildContext context, ColorScheme cs) {
    final stats = _dashData?['stats'] ?? {};
    final profile = _dashData?['profile'];
    final completeness = _dashData?['completeness'] ?? 0;
    final requests = (_dashData?['recentRequests'] as List?) ?? [];
    final earnings = (_dashData?['earnings'] as Map?) ?? {};
    final funnel = (_dashData?['funnel'] as Map?) ?? {};

    return [
      // Completeness bar
      if (completeness < 100)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Profile Completeness', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('$completeness%', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
              ]),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: completeness / 100, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 6),
              Text('Complete your profile to rank higher', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ]),
          ),
        ),
      if (completeness < 100) const SizedBox(height: 12),
      // Availability quick toggle
      _AvailabilityCard(
        current: profile?['availability_status']?.toString() ?? 'offline',
        onChanged: (status) async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            await ApiService.put('/professionals/me/availability', {'availability_status': status}, auth: true);
            await _load();
            if (mounted) {
              messenger.showSnackBar(SnackBar(
                content: Text('You are now $status'),
                backgroundColor: status == 'available' ? Colors.green : (status == 'busy' ? Colors.orange : Colors.grey.shade700),
                duration: const Duration(seconds: 1),
              ));
            }
          } catch (e) {
            if (mounted) messenger.showSnackBar(SnackBar(
              content: Text('$e'), backgroundColor: Colors.red));
          }
        },
      ),
      const SizedBox(height: 12),
      // Stats grid
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.3,
        children: [
          _statCard('Views', '${stats['views'] ?? 0}', Icons.visibility, cs.primary),
          _statCard('Contacts', '${stats['contacts'] ?? 0}', Icons.phone, Colors.green),
          _statCard('Rating', '${stats['rating'] ?? '0.0'}', Icons.star, Colors.amber),
          _statCard('Reviews', '${stats['reviews'] ?? 0}', Icons.rate_review, Colors.pink),
          _statCard('Jobs', '${stats['completedJobs'] ?? 0}', Icons.check_circle, Colors.indigo),
          _statCard('Trust', '${profile?['trust_score'] ?? 0}', Icons.verified_user, Colors.teal),
        ],
      ),
      const SizedBox(height: 16),
      // Earnings
      _EarningsCard(
        lifetime: _money((earnings['lifetime'] ?? 0) as num),
        thisMonth: _money((earnings['thisMonth'] ?? 0) as num),
        last7d: _money((earnings['last7d'] ?? 0) as num),
        pipeline: _money((earnings['pipeline'] ?? 0) as num),
      ),
      const SizedBox(height: 12),
      // Funnel
      _FunnelCard(funnel: funnel),
      const SizedBox(height: 16),
      // Recent requests
      Text('Recent Contact Requests', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      if (requests.isEmpty)
        const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No contact requests yet'))))
      else
        ...requests.take(5).map((req) => Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text((req['customer_name'] ?? '?')[0].toUpperCase())),
                title: Text(req['customer_name'] ?? 'Customer'),
                subtitle: Text('${req['contact_type']} • ${req['status']}', style: const TextStyle(fontSize: 12)),
                trailing: req['status'] == 'pending'
                  ? const Chip(label: Text('Pending', style: TextStyle(fontSize: 11)), backgroundColor: Color(0xFFFEF3C7))
                  : const Chip(label: Text('Done', style: TextStyle(fontSize: 11)), backgroundColor: Color(0xFFD1FAE5)),
              ),
              if (req['message'] != null && req['message'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(req['message'], style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              if (req['status'] == 'pending')
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateContactStatus(req['id'], 'declined'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                      child: const Text('Decline', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _updateContactStatus(req['id'], 'accepted'),
                      child: const Text('Accept', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ]),
            ]),
          ),
        )),
    ];
  }

  List<Widget> _buildCustomerDashboard(BuildContext context, ColorScheme cs) {
    final stats = _dashData?['stats'] ?? {};
    final contacts = (_dashData?['recentContacts'] as List?) ?? [];
    final reviews = (_dashData?['reviewsGiven'] as List?) ?? [];
    final bookings = (_dashData?['recentBookings'] as List?) ?? [];

    return [
      // Stats grid (2x3)
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.3,
        children: [
          _statCard('Active', '${stats['activeBookings'] ?? 0}', Icons.work_outline, cs.primary),
          _statCard('Done', '${stats['completedBookings'] ?? 0}', Icons.check_circle, Colors.green),
          _statCard('Spent', _money((stats['totalSpent'] ?? 0) as num), Icons.account_balance_wallet, Colors.indigo),
          _statCard('Saved', '${stats['favorites'] ?? 0}', Icons.favorite, Colors.pink),
          _statCard('Contacts', '${stats['totalContacts'] ?? 0}', Icons.phone, Colors.teal),
          _statCard('Reviews', '${stats['totalReviews'] ?? 0}', Icons.star, Colors.amber),
        ],
      ),
      if (bookings.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('Recent Bookings', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...bookings.take(5).map((b) => Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _bookingColor(b['status'] ?? '').withValues(alpha: 0.15),
              child: Icon(Icons.work_outline, color: _bookingColor(b['status'] ?? ''), size: 18),
            ),
            title: Text(b['title'] ?? 'Booking', maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${b['professional_name'] ?? '?'} • ${(b['status'] ?? '').toString().replaceAll('_', ' ')}', style: const TextStyle(fontSize: 12)),
            trailing: Text(
              b['final_amount'] != null ? _money(b['final_amount'] as num) : (b['quoted_amount'] != null ? _money(b['quoted_amount'] as num) : ''),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        )),
      ],
      const SizedBox(height: 16),
      Text('Recent Contacts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      if (contacts.isEmpty)
        const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No contacts yet. Search for professionals!'))))
      else
        ...contacts.take(5).map((c) => Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: CircleAvatar(child: Text((c['professional_name'] ?? '?')[0].toUpperCase())),
            title: Text(c['professional_name'] ?? 'Professional'),
            subtitle: Text('${c['contact_type']} • ${c['status']}', style: const TextStyle(fontSize: 12)),
          ),
        )),
      if (reviews.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('Reviews Given', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...reviews.take(5).map((r) => Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: CircleAvatar(child: Text((r['professional_name'] ?? '?')[0].toUpperCase())),
            title: Text(r['professional_name'] ?? 'Professional'),
            subtitle: Text(r['comment'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              Text('${r['rating']}'),
            ]),
          ),
        )),
      ],
    ];
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withAlpha(60),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: cs.primary, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ),
    );
  }
}

/// Quick toggle for a professional's availability_status (available / busy / offline).
class _AvailabilityCard extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _AvailabilityCard({required this.current, required this.onChanged});

  static const _opts = [
    ('available', 'Online', Icons.circle, Color(0xFF10B981)),
    ('busy', 'Busy', Icons.do_not_disturb_on, Color(0xFFF59E0B)),
    ('offline', 'Offline', Icons.power_settings_new, Color(0xFF94A3B8)),
  ];

  @override
  Widget build(BuildContext context) {
    final cur = _opts.firstWhere((o) => o.$1 == current, orElse: () => _opts[2]);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(cur.$3, color: cur.$4, size: 18),
            const SizedBox(width: 8),
            const Text('Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: cur.$4.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(cur.$2, style: TextStyle(color: cur.$4, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              for (final o in _opts)
                ButtonSegment<String>(
                  value: o.$1,
                  label: Text(o.$2, style: const TextStyle(fontSize: 12)),
                  icon: Icon(o.$3, size: 14, color: o.$4),
                ),
            ],
            selected: {current},
            onSelectionChanged: (s) => onChanged(s.first),
            showSelectedIcon: false,
            style: ButtonStyle(visualDensity: VisualDensity.compact),
          ),
        ]),
      ),
    );
  }
}

/// Earnings overview: lifetime / month / 7d / pipeline.
class _EarningsCard extends StatelessWidget {
  final String lifetime;
  final String thisMonth;
  final String last7d;
  final String pipeline;
  const _EarningsCard({required this.lifetime, required this.thisMonth, required this.last7d, required this.pipeline});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.account_balance_wallet, color: cs.primary, size: 18),
            const SizedBox(width: 8),
            const Text('Earnings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            Text('INR', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _metric('This Month', thisMonth, const Color(0xFF10B981))),
            const SizedBox(width: 8),
            Expanded(child: _metric('Last 7 Days', last7d, const Color(0xFF3B82F6))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _metric('Lifetime', lifetime, const Color(0xFF8B5CF6))),
            const SizedBox(width: 8),
            Expanded(child: _metric('Pipeline', pipeline, const Color(0xFFF59E0B))),
          ]),
        ]),
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}

/// Booking conversion funnel.
class _FunnelCard extends StatelessWidget {
  final Map funnel;
  const _FunnelCard({required this.funnel});

  @override
  Widget build(BuildContext context) {
    final total = (funnel['totalBookings'] ?? 0) as int;
    final stages = <(String, int, Color)>[
      ('Requested', (funnel['requested'] ?? 0) as int, const Color(0xFF94A3B8)),
      ('Quoted', (funnel['quoted'] ?? 0) as int, const Color(0xFF8B5CF6)),
      ('Accepted', (funnel['accepted'] ?? 0) as int, const Color(0xFF6366F1)),
      ('Scheduled', (funnel['scheduled'] ?? 0) as int, const Color(0xFF3B82F6)),
      ('In Progress', (funnel['inProgress'] ?? 0) as int, const Color(0xFF0EA5E9)),
      ('Completed', (funnel['completed'] ?? 0) as int, const Color(0xFF10B981)),
    ];
    final maxVal = stages.fold<int>(0, (m, s) => s.$2 > m ? s.$2 : m);
    final conv = (funnel['conversionPct'] ?? 0).toString();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.bar_chart, color: Color(0xFF6366F1), size: 18),
            const SizedBox(width: 8),
            const Text('Booking Funnel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text('$conv% conversion', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 4),
          Text('$total total bookings', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 12),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('No bookings yet — accept your first request to start tracking.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
            )
          else
            ...stages.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                SizedBox(width: 88, child: Text(s.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                Expanded(
                  child: Stack(children: [
                    Container(height: 18, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                    FractionallySizedBox(
                      widthFactor: maxVal == 0 ? 0 : (s.$2 / maxVal).clamp(0.02, 1.0),
                      child: Container(height: 18, decoration: BoxDecoration(color: s.$3, borderRadius: BorderRadius.circular(4))),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 28, child: Text('${s.$2}', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: s.$3))),
              ]),
            )),
        ]),
      ),
    );
  }
}
