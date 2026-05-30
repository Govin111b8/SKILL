import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/booking_service.dart';
import '../../services/realtime_service.dart';
import '../bookings/booking_detail_screen.dart';
import '../profile/edit_professional_profile_screen.dart';
import '../schedule/schedule_management_screen.dart';
import '../earnings/earnings_screen.dart';
import '../../widgets/availability_toggle.dart';
import '../quotes/quote_bid_management_screen.dart';
import '../amc/amc_visits_screen.dart';
import '../society/society_screen.dart';
import '../analytics/provider_analytics_screen.dart';

/// Home tab specifically for professionals — shows their incoming requests,
/// active bookings, today's schedule and quick earnings snapshot.
class ProHomeScreen extends StatefulWidget {
  const ProHomeScreen({super.key});

  @override
  State<ProHomeScreen> createState() => _ProHomeScreenState();
}

class _ProHomeScreenState extends State<ProHomeScreen> {
  Map<String, dynamic>? _dash;
  List<Booking> _pending = [];
  List<Booking> _active = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  void initState() {
    super.initState();
    _load();
    _wsSub = RealtimeService.instance.stream.listen((ev) {
      if (!mounted) return;
      final t = ev['type']?.toString() ?? '';
      if (t == 'notification' || t.startsWith('booking_')) _load();
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.get('/dashboard', auth: true),
        BookingService.list(status: 'requested'),
        BookingService.list(status: 'in_progress'),
      ]);
      _dash = (results[0] as Map<String, dynamic>)['data'];
      _pending = results[1] as List<Booking>;
      _active = results[2] as List<Booking>;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final cs = Theme.of(context).colorScheme;

    final proName = (user?['name'] ?? 'Pro').toString().split(' ').first;
    final todayEarnings = (_dash?['earnings']?['last7d'] as num?)?.toDouble() ?? 0;
    final availStatus = _dash?['profile']?['availability_status']?.toString() ?? 'offline';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF6366F1),
        child: CustomScrollView(
          slivers: [
            // ── Dark gradient hero header ─────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF1E1B4B)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top bar
                        Row(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.handyman_rounded,
                                      color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 8),
                                const Text('SkillConnect Pro',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16)),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                              onPressed: _load,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Greeting + status badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Good ${_greeting()} 👋',
                                    style: TextStyle(
                                        color: Colors.white.withAlpha(160), fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    proName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _availBadge(availStatus),
                                ],
                              ),
                            ),
                            // Today earnings pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withAlpha(20)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Today',
                                    style: TextStyle(
                                        color: Colors.white.withAlpha(140),
                                        fontSize: 10),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${_fmt(todayEarnings)}',
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'Earned',
                                    style: TextStyle(
                                        color: Colors.white.withAlpha(140),
                                        fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Body content ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (_error != null)
                _errorCard()
              else ...[

              // Availability toggle
              const AvailabilityToggle(),
              const SizedBox(height: 16),

              // Quick action buttons — first row
              Row(children: [
                Expanded(child: _QuickAction(
                  icon: Icons.calendar_month_rounded,
                  label: 'Schedule',
                  gradient: const [Color(0xFF6366F1), Color(0xFF818CF8)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleManagementScreen())),
                )),
                const SizedBox(width: 10),
                Expanded(child: _QuickAction(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Earnings',
                  gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen())),
                )),
                const SizedBox(width: 10),
                Expanded(child: _QuickAction(
                  icon: Icons.gavel_rounded,
                  label: 'Quotes',
                  gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuoteBidManagementScreen())),
                )),
                const SizedBox(width: 10),
                Expanded(child: _QuickAction(
                  icon: Icons.event_repeat_rounded,
                  label: 'AMC',
                  gradient: const [Color(0xFF0288D1), Color(0xFF29B6F6)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AmcVisitsScreen())),
                )),
              ]),
              const SizedBox(height: 10),
              // Quick action buttons — second row
              Row(children: [
                Expanded(child: _QuickAction(
                  icon: Icons.apartment_rounded,
                  label: 'Society',
                  gradient: const [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SocietyScreen())),
                )),
                const SizedBox(width: 10),
                Expanded(child: _QuickAction(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  gradient: const [Color(0xFF00796B), Color(0xFF4DB6AC)],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderAnalyticsScreen())),
                )),
                const SizedBox(width: 10),
                Expanded(child: _QuickAction(
                  icon: Icons.emergency_rounded,
                  label: 'Emergency',
                  gradient: const [Color(0xFFEF4444), Color(0xFFF87171)],
                  onTap: () => Navigator.pushNamed(context, '/emergency'),
                )),
                const SizedBox(width: 10),
                const Expanded(child: SizedBox()),
              ]),
              const SizedBox(height: 20),

              // Quick stats row
              _quickStats(cs),
              const SizedBox(height: 20),

              // New requests section
              _sectionHeader(context, 'New Requests', _pending.length, const Color(0xFFF59E0B)),
              const SizedBox(height: 8),
              if (_pending.isEmpty)
                _emptyCard('No new booking requests', Icons.inbox_outlined, 'When customers book you, they\'ll appear here.')
              else
                ..._pending.take(5).map((b) => _bookingCard(context, b, isNew: true)),

              const SizedBox(height: 20),

              // Active jobs section
              _sectionHeader(context, 'Active Jobs', _active.length, const Color(0xFF10B981)),
              const SizedBox(height: 8),
              if (_active.isEmpty)
                _emptyCard('No active jobs right now', Icons.work_off_outlined, 'Accept a request to get started.')
              else
                ..._active.take(5).map((b) => _bookingCard(context, b, isNew: false)),

              const SizedBox(height: 20),

              // Recent contacts/requests
              if ((_dash?['recentRequests'] as List?)?.isNotEmpty == true) ...[
                _sectionHeader(context, 'Contact Requests', (_dash!['recentRequests'] as List).length, cs.primary),
                const SizedBox(height: 8),
                ...((_dash!['recentRequests'] as List).take(3)).map((req) => _contactCard(req as Map)),
                const SizedBox(height: 20),
              ],

              // Profile completeness nudge
              if ((_dash?['completeness'] ?? 0) < 80)
                _completenessNudge(context, cs, (_dash?['completeness'] ?? 0) as int),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  Widget _availBadge(String status) {
    final (label, color) = switch (status) {
      'available' => ('● Online', const Color(0xFF10B981)),
      'busy' => ('● Busy', const Color(0xFFF59E0B)),
      _ => ('● Offline', const Color(0xFF94A3B8)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _earningsPill() {
    final e = _dash?['earnings'];
    if (e == null) return const SizedBox.shrink();
    final month = (e['thisMonth'] as num?)?.toDouble() ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Column(children: [
        const Text('This month', style: TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text('₹${_fmt(month)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v/100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v/1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  Widget _quickStats(ColorScheme cs) {
    final stats = _dash?['stats'] ?? {};
    final funnel = _dash?['funnel'] ?? {};
    final earnings = _dash?['earnings'];
    final todayEarnings = (earnings?['last7d'] as num?)?.toDouble() ?? 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Primary KPI row
      Row(children: [
        _kpiCard('Today\'s ₹', '₹${_fmt(todayEarnings)}', Icons.account_balance_wallet_rounded,
            const [Color(0xFF10B981), Color(0xFF34D399)]),
        const SizedBox(width: 10),
        _kpiCard('Pending', '${_pending.length}', Icons.pending_actions_rounded,
            const [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _kpiCard('Rating', '${stats['rating'] ?? '–'}', Icons.star_rounded,
            const [Color(0xFF6366F1), Color(0xFF818CF8)]),
        const SizedBox(width: 10),
        _kpiCard('Jobs Done', '${funnel['completed'] ?? stats['completedJobs'] ?? 0}',
            Icons.check_circle_rounded, const [Color(0xFF0288D1), Color(0xFF29B6F6)]),
      ]),
    ]);
  }

  Widget _kpiCard(String label, String val, IconData icon, List<Color> gradient) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: gradient.first.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(val, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            Text(label, style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11, fontWeight: FontWeight.w600)),
          ])),
        ]),
      ),
    );
  }

  // Keep _pill for possible usage elsewhere
  Widget _pill(String label, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color.withAlpha(180)), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, int count, Color color) {
    return Row(children: [
      Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 8),
      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(width: 8),
      if (count > 0)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(20)),
          child: Text('$count', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
    ]);
  }

  Widget _emptyCard(String title, IconData icon, String subtitle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
            child: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ])),
        ]),
      ),
    );
  }

  Widget _bookingCard(BuildContext context, Booking b, {required bool isNew}) {
    final color = isNew ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    final df = DateFormat('d MMM, h:mm a');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(booking: b))).then((_) => _load()),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              child: Icon(isNew ? Icons.new_releases_rounded : Icons.construction_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(b.customerName ?? 'Customer', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(df.format(b.createdAt.toLocal()), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (b.quotedAmount != null)
                Text('₹${b.quotedAmount!.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: Text(b.status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _contactCard(Map req) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF6366F1).withAlpha(30),
          child: Text((req['customer_name'] ?? '?').toString()[0].toUpperCase(),
              style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
        ),
        title: Text(req['customer_name'] ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${req['contact_type']} • ${req['status']}', style: const TextStyle(fontSize: 12)),
        trailing: req['status'] == 'pending'
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(20)),
                child: const Text('Reply', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w700, fontSize: 12)),
              )
            : null,
      ),
    );
  }

  Widget _completenessNudge(BuildContext context, ColorScheme cs, int pct) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withAlpha(30)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFF6366F1)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Complete your profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          Text('$pct% done — a complete profile gets 3× more bookings', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ])),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () async {
            final profile = _dash?['profile'];
            if (profile == null) return;
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditProfessionalProfileScreen(profile: profile)),
            );
            if (result == true && mounted) _load();
          },
          child: const Text('Go'),
        ),
      ]),
    );
  }

  Widget _errorCard() {
    return Card(
      child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        const Icon(Icons.cloud_off, size: 36, color: Colors.grey),
        const SizedBox(height: 8),
        Text(_error ?? 'Error', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: _load, child: const Text('Retry')),
      ])),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final List<Color>? gradient;

  const _QuickAction({required this.icon, required this.label, required this.onTap, this.gradient});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final grad = gradient ?? [cs.primaryContainer, cs.primaryContainer];
    final useGrad = gradient != null;
    return Material(
      color: useGrad ? Colors.transparent : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: useGrad
                ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: grad)
                : null,
            color: useGrad ? null : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: useGrad ? Colors.white : cs.primary, size: 24),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: useGrad ? Colors.white : cs.onSurface,
              ), textAlign: TextAlign.center),
            ]),
          ),
        ),
      ),
    );
  }
}
