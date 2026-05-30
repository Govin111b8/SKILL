import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/premium_ui.dart';
import '../bookings/booking_detail_screen.dart';

class SocietyScreen extends StatefulWidget {
  const SocietyScreen({super.key});

  @override
  State<SocietyScreen> createState() => _SocietyScreenState();
}

class _SocietyScreenState extends State<SocietyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _societies = [];
  bool _loading = true;
  String? _error;
  final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _dateFmt = DateFormat('d MMM y');

  static final _demoSocieties = [
    {'id': 'soc-1', 'name': 'Prestige Fern Residency', 'type': 'Apartment', 'city': 'Bengaluru', 'area': 'Whitefield', 'total_units': 120, 'active_units': 87, 'contract_value': 180000, 'contract_start': '2026-01-01', 'contract_end': '2026-12-31', 'poc_name': 'Mr. Vijay Sharma (Secretary)', 'poc_phone': '9876543210', 'services': ['AC Service', 'Deep Cleaning', 'Pest Control'], 'schedule': 'Monthly (3rd Sunday)', 'last_visit': '2026-05-18', 'next_visit': '2026-06-15', 'status': 'active', 'pending_units': 12, 'completed_this_month': 75},
    {'id': 'soc-2', 'name': 'Brigade Meadows', 'type': 'Gated Community', 'city': 'Bengaluru', 'area': 'Kanakapura Road', 'total_units': 240, 'active_units': 156, 'contract_value': 312000, 'contract_start': '2026-03-01', 'contract_end': '2027-02-28', 'poc_name': 'Ms. Lakshmi Rao (Admin)', 'poc_phone': '9900112233', 'services': ['AC Service', 'Electrical Check', 'Plumbing Inspection'], 'schedule': 'Quarterly (4 visits/year)', 'last_visit': '2026-03-10', 'next_visit': '2026-06-10', 'status': 'active', 'pending_units': 34, 'completed_this_month': 0},
    {'id': 'soc-3', 'name': 'Infosys Campus — Block D', 'type': 'Corporate', 'city': 'Bengaluru', 'area': 'Electronic City', 'total_units': 50, 'active_units': 50, 'contract_value': 120000, 'contract_start': '2026-04-01', 'contract_end': '2026-09-30', 'poc_name': 'Facilities Manager — Rajan K', 'poc_phone': '9123456789', 'services': ['Deep Cleaning', 'Pest Control'], 'schedule': 'Weekly (Friday evenings)', 'last_visit': '2026-05-23', 'next_visit': '2026-05-30', 'status': 'active', 'pending_units': 0, 'completed_this_month': 4},
  ];

  @override
  void initState() { super.initState(); _tabController = TabController(length: 2, vsync: this); _load(); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

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
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        child: SafeArea(
          child: Column(
            children: [
              PremiumHeroHeader(
                title: 'Society & B2B command center',
                subtitle: 'Monitor contract value, unit adoption, and recurring schedules for apartment and corporate accounts.',
                icon: Icons.apartment_rounded,
                gradient: const [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                trailing: IconButton(
                  icon: const Icon(Icons.add_business_outlined, color: Colors.white),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact admin to register a new society account'))),
                ),
                chips: [
                  PremiumStatChip(label: '${_societies.length} contracts', icon: Icons.business_center_rounded, color: Colors.white),
                  PremiumStatChip(label: _currencyFmt.format(_societies.fold<int>(0, (s, e) => s + ((e['contract_value'] as num?)?.toInt() ?? 0))), icon: Icons.currency_rupee_rounded, color: Colors.white),
                  const PremiumStatChip(label: 'Recurring plans', icon: Icons.repeat_rounded, color: Colors.white),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: PremiumGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)]), borderRadius: BorderRadius.circular(AppRadius.xl)),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black87,
                    tabs: const [Tab(text: 'My Societies'), Tab(text: 'Analytics')],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: _loading ? const Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg), child: PremiumLoadingList(itemCount: 4, itemHeight: 220)) : TabBarView(controller: _tabController, children: [_buildSocietiesList(), _buildAnalytics()])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocietiesList() {
    if (_societies.isEmpty) {
      return const PremiumEmptyState(icon: Icons.apartment_outlined, title: 'No society accounts', subtitle: 'Your B2B / society contracts will appear here.', gradient: [Color(0xFF0EA5E9), Color(0xFF2563EB)]);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
        children: [
          _SocietySummaryBanner(societies: _societies, currencyFmt: _currencyFmt),
          const SizedBox(height: AppSpacing.lg),
          ..._societies.map((soc) => _SocietyCard(society: soc, currencyFmt: _currencyFmt, dateFmt: _dateFmt)),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    final totalUnits = _societies.fold<int>(0, (sum, s) => sum + ((s['total_units'] as num?)?.toInt() ?? 0));
    final activeUnits = _societies.fold<int>(0, (sum, s) => sum + ((s['active_units'] as num?)?.toInt() ?? 0));
    final totalValue = _societies.fold<int>(0, (sum, s) => sum + ((s['contract_value'] as num?)?.toInt() ?? 0));
    final completedMonth = _societies.fold<int>(0, (sum, s) => sum + ((s['completed_this_month'] as num?)?.toInt() ?? 0));
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.1,
          children: [
            PremiumMetricCard(label: 'Total Societies', value: '${_societies.length}', icon: Icons.apartment_rounded, color: const Color(0xFF6366F1)),
            PremiumMetricCard(label: 'Active Units', value: '$activeUnits/$totalUnits', icon: Icons.home_work_rounded, color: const Color(0xFF10B981)),
            PremiumMetricCard(label: 'Contract Value', value: _currencyFmt.format(totalValue), icon: Icons.payments_rounded, color: const Color(0xFFF59E0B)),
            PremiumMetricCard(label: 'Done This Month', value: '$completedMonth visits', icon: Icons.check_circle_rounded, color: const Color(0xFF06B6D4)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        ..._societies.map((soc) {
          final active = (soc['active_units'] as num?)?.toInt() ?? 0;
          final total = (soc['total_units'] as num?)?.toInt() ?? 1;
          final completedM = (soc['completed_this_month'] as num?)?.toInt() ?? 0;
          final rate = active / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: PremiumGlassCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(soc['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800))), Text('$completedM visits this month', style: TextStyle(color: Colors.grey.shade700))]),
                const SizedBox(height: AppSpacing.sm),
                Row(children: [Text('Adoption: $active/$total units'), const Spacer(), Text('${(rate * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB)))]),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(borderRadius: BorderRadius.circular(AppRadius.pill), child: LinearProgressIndicator(value: rate, minHeight: 8, backgroundColor: Colors.white.withAlpha(110), valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)))),
              ]),
            ),
          );
        }),
      ],
    );
  }
}

class _SocietySummaryBanner extends StatelessWidget {
  final List<Map<String, dynamic>> societies;
  final NumberFormat currencyFmt;
  const _SocietySummaryBanner({required this.societies, required this.currencyFmt});
  @override
  Widget build(BuildContext context) {
    final total = societies.length;
    final totalValue = societies.fold<int>(0, (s, e) => s + ((e['contract_value'] as num?)?.toInt() ?? 0));
    return PremiumGlassCard(
      gradient: const [Color(0xFF0EA5E9), Color(0xFF2563EB)],
      child: Row(children: [Expanded(child: _SummaryItem(label: 'Active Contracts', value: '$total', light: true)), Container(width: 1, height: 40, color: Colors.white.withAlpha(50)), Expanded(child: _SummaryItem(label: 'Total Value', value: currencyFmt.format(totalValue), light: true))]),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final bool light;
  const _SummaryItem({required this.label, required this.value, this.light = false});
  @override
  Widget build(BuildContext context) => Column(children: [Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: light ? Colors.white : Colors.black87)), Text(label, style: TextStyle(color: light ? Colors.white.withAlpha(220) : Colors.grey.shade700))]);
}

class _SocietyCard extends StatelessWidget {
  final Map<String, dynamic> society;
  final NumberFormat currencyFmt;
  final DateFormat dateFmt;
  const _SocietyCard({required this.society, required this.currencyFmt, required this.dateFmt});

  String _typeIcon(String type) { switch (type) { case 'Corporate': return '🏢'; case 'Gated Community': return '🏘️'; default: return '🏠'; } }

  @override
  Widget build(BuildContext context) {
    final services = (society['services'] as List? ?? []).join(' · ');
    final nextVisit = society['next_visit'] != null ? dateFmt.format(DateTime.tryParse(society['next_visit'].toString())?.toLocal() ?? DateTime.now()) : 'Not scheduled';
    final pending = (society['pending_units'] as num?)?.toInt() ?? 0;
    final contractValue = (society['contract_value'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PremiumGlassCard(
        onTap: () { HapticFeedback.selectionClick(); _showSocietyDetail(context); },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text(_typeIcon(society['type']?.toString() ?? ''), style: const TextStyle(fontSize: 22)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(society['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)), Text('${society['type']} · ${society['area']}, ${society['city']}', style: TextStyle(color: Colors.grey.shade600))])), const PremiumStatusPill(label: 'ACTIVE', color: Color(0xFF10B981))]),
          const SizedBox(height: AppSpacing.md),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [_InfoPill(icon: Icons.home_outlined, label: '${society['active_units']}/${society['total_units']} units'), _InfoPill(icon: Icons.payments_outlined, label: currencyFmt.format(contractValue))]),
          const SizedBox(height: AppSpacing.sm),
          Text('Services: $services', style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: AppSpacing.sm),
          Text(society['schedule']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Row(children: [Text('Next: $nextVisit', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700)), const Spacer(), if (pending > 0) PremiumStatusPill(label: '$pending units pending', color: Colors.orange)]),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [Expanded(child: Text(society['poc_name']?.toString() ?? '', style: TextStyle(color: Colors.grey.shade700))), TextButton.icon(onPressed: () {}, icon: const Icon(Icons.call, size: 14), label: const Text('Call POC'))]),
        ]),
      ),
    );
  }

  void _showSocietyDetail(BuildContext context) { showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (ctx) => _SocietyDetailSheet(society: society)); }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white.withAlpha(110), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: const Color(0xFF2563EB)), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]));
}

class _SocietyDetailSheet extends StatelessWidget {
  final Map<String, dynamic> society;
  const _SocietyDetailSheet({required this.society});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => PremiumBackground(
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
            PremiumGlassCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(society['name']?.toString() ?? '', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                Text('${society['type']} · ${society['area']}', style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: AppSpacing.lg),
                _DetailRow(label: 'Point of Contact', value: society['poc_name']?.toString() ?? ''),
                _DetailRow(label: 'Phone', value: society['poc_phone']?.toString() ?? ''),
                _DetailRow(label: 'Total Units', value: society['total_units'].toString()),
                _DetailRow(label: 'Active Units', value: society['active_units'].toString()),
                _DetailRow(label: 'Schedule', value: society['schedule']?.toString() ?? ''),
                _DetailRow(label: 'Contract Period', value: '${society['contract_start']} to ${society['contract_end']}'),
                const SizedBox(height: AppSpacing.md),
                Wrap(spacing: 8, runSpacing: 8, children: (society['services'] as List? ?? []).map((s) => PremiumStatusPill(label: s.toString(), color: const Color(0xFF2563EB))).toList()),
                const SizedBox(height: AppSpacing.lg),
                Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.calendar_month_outlined), label: const Text('View Schedule'))), const SizedBox(width: 12), Expanded(child: PremiumGradientButton(label: 'Log Visit', icon: Icons.add_task, colors: const [Color(0xFF0EA5E9), Color(0xFF2563EB)], onPressed: () {}))]),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 130, child: Text(label, style: TextStyle(color: Colors.grey.shade600))), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)))]));
}
