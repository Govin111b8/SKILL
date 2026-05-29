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
import '../bookings/service_history_screen.dart';
import '../trust/neighbourhood_trust_screen.dart';

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
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF1B6EF3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Hero profile card ────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B6EF3), Color(0xFF7C3AED)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(children: [
                    // Avatar row
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Avatar
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withAlpha(120), width: 3),
                          gradient: const LinearGradient(colors: [Color(0xFF818CF8), Color(0xFF6366F1)]),
                        ),
                        child: Center(
                          child: Text(
                            (user?['name'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name + role
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const SizedBox(height: 6),
                          Text(user?['name'] ?? 'User',
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(user?['email'] ?? '',
                              style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                (user?['role'] ?? 'customer').toString().toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (user?['location'] != null) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.location_on_rounded, size: 13, color: Colors.white.withAlpha(180)),
                              const SizedBox(width: 2),
                              Text(user!['location'],
                                  style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200))),
                            ],
                          ]),
                        ]),
                      ),
                      // Settings icon
                      IconButton(
                        icon: const Icon(Icons.settings_rounded, color: Colors.white),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    // Quick action pills row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        _ProfilePill(Icons.mail_outline_rounded, 'Contacts', const Color(0xFF06B6D4),
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyContactsScreen()))),
                        const SizedBox(width: 8),
                        if (!isPro) ...[
                          _ProfilePill(Icons.favorite_outline_rounded, 'Saved', const Color(0xFFEF4444),
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
                          const SizedBox(width: 8),
                          _ProfilePill(Icons.history_rounded, 'History', const Color(0xFF8B5CF6),
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceHistoryScreen()))),
                          const SizedBox(width: 8),
                        ],
                        _ProfilePill(Icons.verified_user_rounded, 'KYC', const Color(0xFF10B981),
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycScreen()))),
                        if (isPro) ...[
                          const SizedBox(width: 8),
                          _ProfilePill(Icons.edit_rounded, 'Edit Profile', const Color(0xFFF59E0B), () async {
                            if (_dashData?['profile'] != null) {
                              final result = await Navigator.push(context, MaterialPageRoute(
                                builder: (_) => EditProfessionalProfileScreen(profile: _dashData!['profile']),
                              ));
                              if (result == true) _load();
                            } else {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('Create your professional profile first via the home tab'),
                                backgroundColor: Colors.orange,
                              ));
                            }
                          }),
                          const SizedBox(width: 8),
                          _ProfilePill(Icons.photo_library_rounded, 'Portfolio', const Color(0xFF6366F1), () {
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
                  ]),
                ),
              ),
            ),
            // ── Stats + content ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Stats
                if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                else if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(children: [
                      Icon(Icons.cloud_off_rounded, size: 40, color: Colors.red.shade400),
                      const SizedBox(height: 8),
                      Text('Could not load dashboard', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      OutlinedButton(onPressed: _load, child: const Text('Retry')),
                    ]),
                  )
                else if (isPro) ..._buildProDashboard(context, cs)
                else ..._buildCustomerDashboard(context, cs),
                const SizedBox(height: 20),
                // Sign out
                GestureDetector(
                  onTap: () {
                    auth.logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Text('Sign Out', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w700, fontSize: 15)),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded, color: Colors.red.shade400),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
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
          _statCard('Trust', '${profile?['trust_score'] ?? 0}', Icons.verified_user, Colors.teal,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NeighbourhoodTrustScreen()))),
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
    final bookings = (_dashData?['recentBookings'] as List?) ?? [];

    return [
      // ── Colorful stat tiles (2-column) ────────────────────────
      Row(children: [
        _GradientStatTile(
          label: 'Active Jobs',
          value: '${stats['activeBookings'] ?? 0}',
          icon: Icons.work_outline_rounded,
          gradient: const [Color(0xFF6366F1), Color(0xFF818CF8)],
        ),
        const SizedBox(width: 10),
        _GradientStatTile(
          label: 'Completed',
          value: '${stats['completedBookings'] ?? 0}',
          icon: Icons.check_circle_outline_rounded,
          gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _GradientStatTile(
          label: 'Total Spent',
          value: _money((stats['totalSpent'] ?? 0) as num),
          icon: Icons.account_balance_wallet_rounded,
          gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
        ),
        const SizedBox(width: 10),
        _GradientStatTile(
          label: 'Reviews',
          value: '${stats['totalReviews'] ?? 0}',
          icon: Icons.star_rounded,
          gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _GradientStatTile(
          label: 'Saved Pros',
          value: '${stats['favorites'] ?? 0}',
          icon: Icons.favorite_rounded,
          gradient: const [Color(0xFFEF4444), Color(0xFFF87171)],
        ),
        const SizedBox(width: 10),
        _GradientStatTile(
          label: 'Contacts',
          value: '${stats['totalContacts'] ?? 0}',
          icon: Icons.people_alt_rounded,
          gradient: const [Color(0xFF06B6D4), Color(0xFF67E8F9)],
        ),
      ]),

      // ── Recent bookings ───────────────────────────────────────
      if (bookings.isNotEmpty) ...[
        const SizedBox(height: 20),
        _sectionTitle('Recent Bookings', Icons.receipt_long_rounded, const Color(0xFF6366F1)),
        const SizedBox(height: 10),
        ...bookings.take(4).map((b) => _BookingItemCard(booking: b, colorFn: _bookingColor, moneyFn: _money)),
      ],
    ];
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    // kept for _buildProDashboard compatibility — unused in consumer path
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

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            if (onTap != null) const Icon(Icons.chevron_right, size: 12, color: Colors.grey),
          ]),
        ),
      ),
    );
  }
}

// ── Gradient stat tile used in consumer dashboard ─────────────────────────────

class _GradientStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const _GradientStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: gradient.first.withAlpha(60), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

// ── Booking item card ─────────────────────────────────────────────────────────

class _BookingItemCard extends StatelessWidget {
  final Map booking;
  final Color Function(String) colorFn;
  final String Function(num) moneyFn;

  const _BookingItemCard({required this.booking, required this.colorFn, required this.moneyFn});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final status = (b['status'] ?? '').toString();
    final color = colorFn(status);
    final amount = b['final_amount'] != null
        ? moneyFn(b['final_amount'] as num)
        : (b['quoted_amount'] != null ? moneyFn(b['quoted_amount'] as num) : '');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.work_outline_rounded, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b['title'] ?? 'Booking', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text('${b['professional_name'] ?? '?'} • ${status.replaceAll('_', ' ')}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ])),
        if (amount.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ]),
    );
  }
}

// ── Profile pill quick action ──────────────────────────────────────────────

class _ProfilePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ProfilePill(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
