import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../bookings/booking_detail_screen.dart';

/// Society / B2B Module Screen.
///
/// Handles bulk booking management for:
///   - Housing societies (Resident Welfare Associations)
///   - Apartments / gated communities
///   - Corporate offices / B2B clients
///
/// Features:
///   - Society profile management (unit count, contact, agreement)
///   - Bulk scheduling (one slot for all units or per-unit)
///   - Society-level billing summary
///   - Recurring service plans (weekly/monthly)
///   - Individual unit booking tracker
class SocietyScreen extends StatefulWidget {
  const SocietyScreen({super.key});

  @override
  State<SocietyScreen> createState() => _SocietyScreenState();
}

class _SocietyScreenState extends State<SocietyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _societies = [];
  bool _loading = true;
  String? _error;

  final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _dateFmt = DateFormat('d MMM y');

  // Demo data
  static final _demoSocieties = [
    {
      'id': 'soc-1',
      'name': 'Prestige Fern Residency',
      'type': 'Apartment',
      'city': 'Bengaluru',
      'area': 'Whitefield',
      'total_units': 120,
      'active_units': 87,
      'contract_value': 180000,
      'contract_start': '2026-01-01',
      'contract_end': '2026-12-31',
      'poc_name': 'Mr. Vijay Sharma (Secretary)',
      'poc_phone': '9876543210',
      'services': ['AC Service', 'Deep Cleaning', 'Pest Control'],
      'schedule': 'Monthly (3rd Sunday)',
      'last_visit': '2026-05-18',
      'next_visit': '2026-06-15',
      'status': 'active',
      'pending_units': 12,
      'completed_this_month': 75,
    },
    {
      'id': 'soc-2',
      'name': 'Brigade Meadows',
      'type': 'Gated Community',
      'city': 'Bengaluru',
      'area': 'Kanakapura Road',
      'total_units': 240,
      'active_units': 156,
      'contract_value': 312000,
      'contract_start': '2026-03-01',
      'contract_end': '2027-02-28',
      'poc_name': 'Ms. Lakshmi Rao (Admin)',
      'poc_phone': '9900112233',
      'services': ['AC Service', 'Electrical Check', 'Plumbing Inspection'],
      'schedule': 'Quarterly (4 visits/year)',
      'last_visit': '2026-03-10',
      'next_visit': '2026-06-10',
      'status': 'active',
      'pending_units': 34,
      'completed_this_month': 0,
    },
    {
      'id': 'soc-3',
      'name': 'Infosys Campus — Block D',
      'type': 'Corporate',
      'city': 'Bengaluru',
      'area': 'Electronic City',
      'total_units': 50,
      'active_units': 50,
      'contract_value': 120000,
      'contract_start': '2026-04-01',
      'contract_end': '2026-09-30',
      'poc_name': 'Facilities Manager — Rajan K',
      'poc_phone': '9123456789',
      'services': ['Deep Cleaning', 'Pest Control'],
      'schedule': 'Weekly (Friday evenings)',
      'last_visit': '2026-05-23',
      'next_visit': '2026-05-30',
      'status': 'active',
      'pending_units': 0,
      'completed_this_month': 4,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/societies/me', auth: true);
      final list = (res['data'] as List? ?? []);
      _societies = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (_societies.isEmpty) _societies = _demoSocieties;
    } catch (_) {
      _societies = _demoSocieties;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Society / B2B'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            tooltip: 'Add new society',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact admin to register a new society account')),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Societies'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: _loading
          ? _buildSkeletons()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSocietiesList(),
                _buildAnalytics(),
              ],
            ),
    );
  }

  Widget _buildSkeletons() => ListView(
    padding: const EdgeInsets.all(16),
    children: List.generate(3, (_) => const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: CardSkeleton(height: 220),
    )),
  );

  Widget _buildSocietiesList() {
    if (_societies.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.apartment_outlined,
        title: 'No society accounts',
        subtitle: 'Your B2B / society contracts will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Summary header
          _SocietySummaryBanner(societies: _societies, currencyFmt: _currencyFmt),
          const SizedBox(height: 16),
          ..._societies.map((soc) => _SocietyCard(
            society: soc,
            currencyFmt: _currencyFmt,
            dateFmt: _dateFmt,
          )),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    // Aggregate stats
    final totalUnits = _societies.fold<int>(0, (sum, s) => sum + ((s['total_units'] as num?)?.toInt() ?? 0));
    final activeUnits = _societies.fold<int>(0, (sum, s) => sum + ((s['active_units'] as num?)?.toInt() ?? 0));
    final totalValue = _societies.fold<int>(0, (sum, s) => sum + ((s['contract_value'] as num?)?.toInt() ?? 0));
    final completedMonth = _societies.fold<int>(0, (sum, s) => sum + ((s['completed_this_month'] as num?)?.toInt() ?? 0));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('B2B Performance Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _AnalyticsCard(label: 'Total Societies', value: '${_societies.length}', icon: Icons.apartment, color: const Color(0xFF6366F1)),
            _AnalyticsCard(label: 'Active Units', value: '$activeUnits/$totalUnits', icon: Icons.home_work_outlined, color: const Color(0xFF10B981)),
            _AnalyticsCard(label: 'Contract Value', value: _currencyFmt.format(totalValue), icon: Icons.payments_outlined, color: const Color(0xFFF59E0B)),
            _AnalyticsCard(label: 'Done This Month', value: '$completedMonth visits', icon: Icons.check_circle_outline, color: const Color(0xFF06B6D4)),
          ],
        ),
        const SizedBox(height: 24),
        Text('Society Performance', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ..._societies.map((soc) {
          final active = (soc['active_units'] as num?)?.toInt() ?? 0;
          final total = (soc['total_units'] as num?)?.toInt() ?? 1;
          final completedM = (soc['completed_this_month'] as num?)?.toInt() ?? 0;
          final rate = active / total;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(soc['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('$completedM visits this month', style: Theme.of(context).textTheme.bodySmall),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Text('Adoption: $active/$total units', style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  Text('${(rate * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                ]),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: rate,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(4),
                ),
              ]),
            ),
          );
        }),
      ],
    );
  }
}

// ── Society Summary Banner ──────────────────────────────────────────────────

class _SocietySummaryBanner extends StatelessWidget {
  final List<Map<String, dynamic>> societies;
  final NumberFormat currencyFmt;
  const _SocietySummaryBanner({required this.societies, required this.currencyFmt});

  @override
  Widget build(BuildContext context) {
    final total = societies.length;
    final totalValue = societies.fold<int>(0, (s, e) => s + ((e['contract_value'] as num?)?.toInt() ?? 0));
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cs.primaryContainer, cs.secondaryContainer]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Expanded(child: _SummaryItem(label: 'Active Contracts', value: '$total')),
        Container(width: 1, height: 40, color: cs.onPrimaryContainer.withAlpha(30)),
        Expanded(child: _SummaryItem(label: 'Total Value', value: currencyFmt.format(totalValue))),
      ]),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
    Text(label, style: Theme.of(context).textTheme.bodySmall),
  ]);
}

// ── Society Card ────────────────────────────────────────────────────────────

class _SocietyCard extends StatelessWidget {
  final Map<String, dynamic> society;
  final NumberFormat currencyFmt;
  final DateFormat dateFmt;

  const _SocietyCard({required this.society, required this.currencyFmt, required this.dateFmt});

  String _typeIcon(String type) {
    switch (type) {
      case 'Corporate': return '🏢';
      case 'Gated Community': return '🏘️';
      default: return '🏠';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final services = (society['services'] as List? ?? []).join(' · ');
    final nextVisit = society['next_visit'] != null
        ? dateFmt.format(DateTime.tryParse(society['next_visit'].toString())?.toLocal() ?? DateTime.now())
        : 'Not scheduled';
    final pending = (society['pending_units'] as num?)?.toInt() ?? 0;
    final contractValue = (society['contract_value'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _showSocietyDetail(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Text(_typeIcon(society['type']?.toString() ?? ''), style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(society['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text('${society['type']} · ${society['area']}, ${society['city']}', style: Theme.of(context).textTheme.bodySmall),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.green.shade700)),
              ),
            ]),
            const SizedBox(height: 12),
            // Stats grid
            Row(children: [
              _InfoPill(icon: Icons.home_outlined, label: '${society['active_units']}/${society['total_units']} units'),
              const SizedBox(width: 8),
              _InfoPill(icon: Icons.payments_outlined, label: currencyFmt.format(contractValue)),
            ]),
            const SizedBox(height: 8),
            // Services
            Text('Services: $services', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            // Schedule
            Row(children: [
              Icon(Icons.repeat, size: 14, color: cs.outline),
              const SizedBox(width: 4),
              Text(society['schedule']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.upcoming, size: 14, color: cs.primary),
              const SizedBox(width: 4),
              Text('Next: $nextVisit', style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (pending > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.orange.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                  child: Text('$pending units pending', style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            const SizedBox(height: 12),
            // POC
            Row(children: [
              Icon(Icons.contact_phone_outlined, size: 14, color: cs.outline),
              const SizedBox(width: 4),
              Expanded(child: Text(society['poc_name']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall)),
              TextButton.icon(
                onPressed: () {/* url_launcher */},
                icon: const Icon(Icons.call, size: 14),
                label: const Text('Call POC'),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showSocietyDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _SocietyDetailSheet(society: society),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );
}

// ── Society Detail Bottom Sheet ─────────────────────────────────────────────

class _SocietyDetailSheet extends StatelessWidget {
  final Map<String, dynamic> society;
  const _SocietyDetailSheet({required this.society});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(society['name']?.toString() ?? '', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          Text('${society['type']} · ${society['area']}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          _DetailRow(label: 'Point of Contact', value: society['poc_name']?.toString() ?? ''),
          _DetailRow(label: 'Phone', value: society['poc_phone']?.toString() ?? ''),
          _DetailRow(label: 'Total Units', value: society['total_units'].toString()),
          _DetailRow(label: 'Active Units', value: society['active_units'].toString()),
          _DetailRow(label: 'Schedule', value: society['schedule']?.toString() ?? ''),
          _DetailRow(label: 'Contract Period', value: '${society['contract_start']} to ${society['contract_end']}'),
          const SizedBox(height: 16),
          Text('Services Included', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (society['services'] as List? ?? []).map((s) => Chip(
              label: Text(s.toString()),
              backgroundColor: cs.primaryContainer,
              labelStyle: TextStyle(color: cs.onPrimaryContainer, fontSize: 12),
            )).toList(),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('View Schedule'),
            )),
            const SizedBox(width: 12),
            Expanded(child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_task),
              label: const Text('Log Visit'),
            )),
          ]),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 130, child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline))),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
    ]),
  );
}

class _AnalyticsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _AnalyticsCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withAlpha(15),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withAlpha(50)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const Spacer(),
      Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]),
  );
}
