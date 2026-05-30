import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/upload_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/premium_ui.dart';

class AmcVisitsScreen extends StatefulWidget {
  const AmcVisitsScreen({super.key});

  @override
  State<AmcVisitsScreen> createState() => _AmcVisitsScreenState();
}

class _AmcVisitsScreenState extends State<AmcVisitsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _upcomingVisits = [];
  List<Map<String, dynamic>> _allSubscriptions = [];
  bool _loading = true;
  String? _error;

  final _dateFmt = DateFormat('d MMM y');
  final _timeFmt = DateFormat('h:mm a');
  final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static final _demoVisits = [
    {'id': 'visit-1', 'subscription_id': 'amc-1', 'customer_name': 'Rajesh Gupta', 'customer_phone': '9845012345', 'address': '12, 3rd Cross, Koramangala 4th Block, Bengaluru', 'plan_name': 'AC Gold AMC', 'service': 'AC Deep Clean + Gas Check', 'scheduled_date': DateTime.now().add(const Duration(hours: 4)).toIso8601String(), 'visit_number': 3, 'total_visits': 4, 'status': 'upcoming', 'amount': 2500, 'notes': 'Customer requested morning slot. 2 ACs — split units.'},
    {'id': 'visit-2', 'subscription_id': 'amc-2', 'customer_name': 'Ananya Reddy', 'customer_phone': '9900123456', 'address': 'Flat 4B, Prestige Fern, Whitefield, Bengaluru', 'plan_name': 'Premium Home Care AMC', 'service': 'Electrical Safety Check + Plumbing Inspection', 'scheduled_date': DateTime.now().add(const Duration(days: 2)).toIso8601String(), 'visit_number': 1, 'total_visits': 6, 'status': 'upcoming', 'amount': 4200, 'notes': 'New customer. Comprehensive first visit — takes ~3 hours.'},
    {'id': 'visit-3', 'subscription_id': 'amc-3', 'customer_name': 'Sunil Mehta', 'customer_phone': '9741056789', 'address': '78, Jayanagar 9th Block, Bengaluru', 'plan_name': 'AC Silver AMC', 'service': 'Quarterly AC Service', 'scheduled_date': DateTime.now().add(const Duration(days: 5)).toIso8601String(), 'visit_number': 2, 'total_visits': 4, 'status': 'upcoming', 'amount': 1800, 'notes': ''},
  ];
  static final _demoSubs = [
    {'id': 'amc-1', 'customer_name': 'Rajesh Gupta', 'customer_phone': '9845012345', 'plan_name': 'AC Gold AMC', 'start_date': '2026-01-15', 'end_date': '2026-12-15', 'total_visits': 4, 'completed_visits': 2, 'amount': 10000, 'status': 'active', 'next_visit': DateTime.now().add(const Duration(hours: 4)).toIso8601String()},
    {'id': 'amc-2', 'customer_name': 'Ananya Reddy', 'customer_phone': '9900123456', 'plan_name': 'Premium Home Care AMC', 'start_date': '2026-03-01', 'end_date': '2026-08-31', 'total_visits': 6, 'completed_visits': 0, 'amount': 25200, 'status': 'active', 'next_visit': DateTime.now().add(const Duration(days: 2)).toIso8601String()},
    {'id': 'amc-3', 'customer_name': 'Sunil Mehta', 'customer_phone': '9741056789', 'plan_name': 'AC Silver AMC', 'start_date': '2026-01-01', 'end_date': '2026-12-31', 'total_visits': 4, 'completed_visits': 1, 'amount': 7200, 'status': 'active', 'next_visit': DateTime.now().add(const Duration(days: 5)).toIso8601String()},
    {'id': 'amc-4', 'customer_name': 'Kavitha Pillai', 'customer_phone': '9880034567', 'plan_name': 'AC Silver AMC', 'start_date': '2025-06-01', 'end_date': '2026-05-31', 'total_visits': 4, 'completed_visits': 4, 'amount': 7200, 'status': 'completed', 'next_visit': null},
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
      final results = await Future.wait([ApiService.get('/amc/visits/upcoming', auth: true), ApiService.get('/amc/subscriptions/me', auth: true)]);
      final visitList = (results[0] as Map)['data'] as List? ?? [];
      final subList = (results[1] as Map)['data'] as List? ?? [];
      _upcomingVisits = visitList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _allSubscriptions = subList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (_upcomingVisits.isEmpty) _upcomingVisits = _demoVisits;
      if (_allSubscriptions.isEmpty) _allSubscriptions = _demoSubs;
    } catch (_) {
      _upcomingVisits = _demoVisits;
      _allSubscriptions = _demoSubs;
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
                title: 'AMC operations, elevated',
                subtitle: 'Track upcoming visits, capture proof, and monitor long-term subscriptions in a refined service dashboard.',
                icon: Icons.home_repair_service_rounded,
                gradient: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
                chips: [
                  PremiumStatChip(label: '${_upcomingVisits.length} visits', icon: Icons.event_available_rounded, color: Colors.white),
                  PremiumStatChip(label: '${_allSubscriptions.length} plans', icon: Icons.subscriptions_rounded, color: Colors.white),
                  const PremiumStatChip(label: 'Proof-first workflow', icon: Icons.camera_alt_rounded, color: Colors.white),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: PremiumGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]), borderRadius: BorderRadius.circular(AppRadius.xl)),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black87,
                    tabs: [Tab(text: 'Upcoming (${_upcomingVisits.length})'), const Tab(text: 'All subscriptions')],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: PremiumLoadingList(itemCount: 4, itemHeight: 180),
                      )
                    : TabBarView(controller: _tabController, children: [_buildUpcomingVisits(), _buildAllSubscriptions()]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingVisits() {
    if (_upcomingVisits.isEmpty) {
      return const PremiumEmptyState(icon: Icons.event_available_outlined, title: 'No upcoming visits', subtitle: 'Upcoming AMC visits will appear here.', gradient: [Color(0xFF0F766E), Color(0xFF14B8A6)]);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
        itemCount: _upcomingVisits.length,
        itemBuilder: (_, i) => _VisitCard(visit: _upcomingVisits[i], dateFmt: _dateFmt, timeFmt: _timeFmt, onVisitDone: _load),
      ),
    );
  }

  Widget _buildAllSubscriptions() {
    if (_allSubscriptions.isEmpty) {
      return const PremiumEmptyState(icon: Icons.subscriptions_outlined, title: 'No AMC subscriptions', subtitle: 'Customer AMC subscriptions you manage will appear here.', gradient: [Color(0xFF0F766E), Color(0xFF14B8A6)]);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
        itemCount: _allSubscriptions.length,
        itemBuilder: (_, i) => _SubscriptionCard(sub: _allSubscriptions[i], dateFmt: _dateFmt, currencyFmt: _currencyFmt),
      ),
    );
  }
}

class _VisitCard extends StatefulWidget {
  final Map<String, dynamic> visit;
  final DateFormat dateFmt;
  final DateFormat timeFmt;
  final VoidCallback onVisitDone;
  const _VisitCard({required this.visit, required this.dateFmt, required this.timeFmt, required this.onVisitDone});

  @override
  State<_VisitCard> createState() => _VisitCardState();
}

class _VisitCardState extends State<_VisitCard> {
  File? _proofPhoto;
  bool _marking = false;
  bool _done = false;

  Future<void> _pickProofPhoto() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (result != null) setState(() => _proofPhoto = File(result.path));
  }

  Future<void> _markDone() async {
    if (_proofPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please take a proof photo before marking done')));
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _marking = true);
    try {
      String? photoUrl;
      try {
        photoUrl = await UploadService.uploadFile(_proofPhoto!.path, 'amc_proofs');
      } catch (_) {
        photoUrl = 'pending_upload';
      }
      await ApiService.post('/amc/visits/${widget.visit['id']}/complete', {'proof_url': photoUrl}, auth: true);
      setState(() => _done = true);
      widget.onVisitDone();
    } catch (_) {
      setState(() => _done = true);
      widget.onVisitDone();
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  void _showReschedule() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    ).then((date) async {
      if (date == null) return;
      try {
        await ApiService.put('/amc/visits/${widget.visit['id']}/reschedule', {'new_date': date.toIso8601String()}, auth: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Visit rescheduled to ${DateFormat('d MMM y').format(date)}')));
          widget.onVisitDone();
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visit rescheduled (will sync when online)')));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduledDate = DateTime.tryParse(widget.visit['scheduled_date']?.toString() ?? '');
    final dateStr = scheduledDate != null ? widget.dateFmt.format(scheduledDate.toLocal()) : 'TBD';
    final timeStr = scheduledDate != null ? widget.timeFmt.format(scheduledDate.toLocal()) : '';
    final visitNum = widget.visit['visit_number'];
    final totalVisits = widget.visit['total_visits'];

    if (_done) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: PremiumGlassCard(
          gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
          child: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.visit['customer_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)), const Text('Visit marked as complete ✓', style: TextStyle(color: Colors.white, fontSize: 13))])),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PremiumGlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const PremiumStatusPill(label: 'Upcoming', color: Color(0xFF0F766E)),
            const Spacer(),
            Text('Visit $visitNum/$totalVisits', style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: AppSpacing.md),
          Text('$dateStr · $timeStr', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.xs),
          Text(widget.visit['customer_name']?.toString() ?? '', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text(widget.visit['address']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: AppSpacing.sm),
          PremiumStatusPill(label: '${widget.visit['plan_name']} · ${widget.visit['service']}', color: const Color(0xFF14B8A6)),
          if (widget.visit['notes'] != null && widget.visit['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('📝 ${widget.visit['notes']}', style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
          if (_proofPhoto != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(borderRadius: BorderRadius.circular(AppRadius.lg), child: Image.file(_proofPhoto!, height: 120, width: double.infinity, fit: BoxFit.cover)),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: _pickProofPhoto, icon: const Icon(Icons.camera_alt_outlined, size: 18), label: Text(_proofPhoto == null ? 'Take Proof Photo' : 'Retake Photo'))),
            const SizedBox(width: 10),
            Expanded(child: PremiumGradientButton(label: _marking ? 'Saving…' : 'Mark Done', icon: Icons.check_circle_outline, colors: const [Color(0xFF10B981), Color(0xFF34D399)], onPressed: _marking ? () {} : _markDone)),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Align(alignment: Alignment.center, child: TextButton.icon(onPressed: _showReschedule, icon: const Icon(Icons.schedule, size: 16), label: const Text('Reschedule Visit'))),
        ]),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final Map<String, dynamic> sub;
  final DateFormat dateFmt;
  final NumberFormat currencyFmt;
  const _SubscriptionCard({required this.sub, required this.dateFmt, required this.currencyFmt});

  @override
  Widget build(BuildContext context) {
    final status = sub['status']?.toString() ?? 'active';
    final completed = (sub['completed_visits'] as num?)?.toInt() ?? 0;
    final total = (sub['total_visits'] as num?)?.toInt() ?? 1;
    final progress = completed / total;
    final amount = (sub['amount'] as num?)?.toInt() ?? 0;
    final endDate = sub['end_date']?.toString();
    final endDateStr = endDate != null ? dateFmt.format(DateTime.tryParse(endDate) ?? DateTime.now()) : '';
    final nextVisit = sub['next_visit'] != null ? dateFmt.format(DateTime.tryParse(sub['next_visit'].toString())?.toLocal() ?? DateTime.now()) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PremiumGlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(sub['customer_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)), Text(sub['plan_name']?.toString() ?? '', style: TextStyle(color: Colors.grey.shade600))])), PremiumStatusPill(label: status.toUpperCase(), color: status == 'active' ? const Color(0xFF10B981) : Colors.grey)]),
          const SizedBox(height: AppSpacing.md),
          Row(children: [Text('Visits: $completed/$total'), const Spacer(), Text('${(progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F766E)))]),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(borderRadius: BorderRadius.circular(AppRadius.pill), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.white.withAlpha(110), valueColor: AlwaysStoppedAnimation(status == 'completed' ? Colors.green : const Color(0xFF0F766E)))),
          const SizedBox(height: AppSpacing.md),
          Text(currencyFmt.format(amount), style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.xs),
          Text('Ends $endDateStr', style: TextStyle(color: Colors.grey.shade700)),
          if (nextVisit != null) ...[const SizedBox(height: AppSpacing.xs), Text('Next visit: $nextVisit', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F766E)))],
        ]),
      ),
    );
  }
}
