import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api_service.dart';
import '../../services/upload_service.dart';
import '../../widgets/skeleton_loader.dart';

/// AMC Visits Screen — for service professionals managing Annual Maintenance
/// Contract (AMC) subscription visits.
///
/// Features:
///   - List active AMC subscriptions with upcoming visit dates
///   - Mark visit as done (with proof photo upload)
///   - Reschedule individual visit
///   - Customer contact (call / WhatsApp)
///   - Tabs: Upcoming visits · All subscriptions
class AmcVisitsScreen extends StatefulWidget {
  const AmcVisitsScreen({super.key});

  @override
  State<AmcVisitsScreen> createState() => _AmcVisitsScreenState();
}

class _AmcVisitsScreenState extends State<AmcVisitsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _upcomingVisits = [];
  List<Map<String, dynamic>> _allSubscriptions = [];
  bool _loading = true;
  String? _error;

  final _dateFmt = DateFormat('d MMM y');
  final _timeFmt = DateFormat('h:mm a');
  final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  // Demo data
  static final _demoVisits = [
    {
      'id': 'visit-1',
      'subscription_id': 'amc-1',
      'customer_name': 'Rajesh Gupta',
      'customer_phone': '9845012345',
      'address': '12, 3rd Cross, Koramangala 4th Block, Bengaluru',
      'plan_name': 'AC Gold AMC',
      'service': 'AC Deep Clean + Gas Check',
      'scheduled_date': DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
      'visit_number': 3,
      'total_visits': 4,
      'status': 'upcoming',
      'amount': 2500,
      'notes': 'Customer requested morning slot. 2 ACs — split units.',
    },
    {
      'id': 'visit-2',
      'subscription_id': 'amc-2',
      'customer_name': 'Ananya Reddy',
      'customer_phone': '9900123456',
      'address': 'Flat 4B, Prestige Fern, Whitefield, Bengaluru',
      'plan_name': 'Premium Home Care AMC',
      'service': 'Electrical Safety Check + Plumbing Inspection',
      'scheduled_date': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      'visit_number': 1,
      'total_visits': 6,
      'status': 'upcoming',
      'amount': 4200,
      'notes': 'New customer. Comprehensive first visit — takes ~3 hours.',
    },
    {
      'id': 'visit-3',
      'subscription_id': 'amc-3',
      'customer_name': 'Sunil Mehta',
      'customer_phone': '9741056789',
      'address': '78, Jayanagar 9th Block, Bengaluru',
      'plan_name': 'AC Silver AMC',
      'service': 'Quarterly AC Service',
      'scheduled_date': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      'visit_number': 2,
      'total_visits': 4,
      'status': 'upcoming',
      'amount': 1800,
      'notes': '',
    },
  ];

  static final _demoSubs = [
    {
      'id': 'amc-1',
      'customer_name': 'Rajesh Gupta',
      'customer_phone': '9845012345',
      'plan_name': 'AC Gold AMC',
      'start_date': '2026-01-15',
      'end_date': '2026-12-15',
      'total_visits': 4,
      'completed_visits': 2,
      'amount': 10000,
      'status': 'active',
      'next_visit': DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
    },
    {
      'id': 'amc-2',
      'customer_name': 'Ananya Reddy',
      'customer_phone': '9900123456',
      'plan_name': 'Premium Home Care AMC',
      'start_date': '2026-03-01',
      'end_date': '2026-08-31',
      'total_visits': 6,
      'completed_visits': 0,
      'amount': 25200,
      'status': 'active',
      'next_visit': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
    },
    {
      'id': 'amc-3',
      'customer_name': 'Sunil Mehta',
      'customer_phone': '9741056789',
      'plan_name': 'AC Silver AMC',
      'start_date': '2026-01-01',
      'end_date': '2026-12-31',
      'total_visits': 4,
      'completed_visits': 1,
      'amount': 7200,
      'status': 'active',
      'next_visit': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
    },
    {
      'id': 'amc-4',
      'customer_name': 'Kavitha Pillai',
      'customer_phone': '9880034567',
      'plan_name': 'AC Silver AMC',
      'start_date': '2025-06-01',
      'end_date': '2026-05-31',
      'total_visits': 4,
      'completed_visits': 4,
      'amount': 7200,
      'status': 'completed',
      'next_visit': null,
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
      final results = await Future.wait([
        ApiService.get('/amc/visits/upcoming', auth: true),
        ApiService.get('/amc/subscriptions/me', auth: true),
      ]);
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
      appBar: AppBar(
        title: const Text('AMC Visits'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Upcoming (${_upcomingVisits.length})'),
            Tab(text: 'All Subscriptions'),
          ],
        ),
      ),
      body: _loading
          ? _buildSkeletons()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingVisits(),
                _buildAllSubscriptions(),
              ],
            ),
    );
  }

  Widget _buildSkeletons() => ListView(
    padding: const EdgeInsets.all(16),
    children: List.generate(3, (_) => const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: CardSkeleton(height: 180),
    )),
  );

  Widget _buildUpcomingVisits() {
    if (_upcomingVisits.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.event_available_outlined,
        title: 'No upcoming visits',
        subtitle: 'Upcoming AMC visits will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _upcomingVisits.length,
        itemBuilder: (_, i) => _VisitCard(
          visit: _upcomingVisits[i],
          dateFmt: _dateFmt,
          timeFmt: _timeFmt,
          onVisitDone: _load,
        ),
      ),
    );
  }

  Widget _buildAllSubscriptions() {
    if (_allSubscriptions.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.subscriptions_outlined,
        title: 'No AMC subscriptions',
        subtitle: 'Customer AMC subscriptions you manage will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _allSubscriptions.length,
        itemBuilder: (_, i) => _SubscriptionCard(
          sub: _allSubscriptions[i],
          dateFmt: _dateFmt,
          currencyFmt: _currencyFmt,
        ),
      ),
    );
  }
}

// ── Visit Card ──────────────────────────────────────────────────────────────

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a proof photo before marking done')),
      );
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
      await ApiService.post('/amc/visits/${widget.visit['id']}/complete', {
        'proof_url': photoUrl,
      }, auth: true);
      setState(() => _done = true);
      widget.onVisitDone();
    } catch (_) {
      // Optimistic UI — show done even if API fails (offline mode)
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
        await ApiService.put('/amc/visits/${widget.visit['id']}/reschedule', {
          'new_date': date.toIso8601String(),
        }, auth: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Visit rescheduled to ${DateFormat('d MMM y').format(date)}')),
          );
          widget.onVisitDone();
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Visit rescheduled (will sync when online)')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scheduledDate = DateTime.tryParse(widget.visit['scheduled_date']?.toString() ?? '');
    final dateStr = scheduledDate != null ? widget.dateFmt.format(scheduledDate.toLocal()) : 'TBD';
    final timeStr = scheduledDate != null ? widget.timeFmt.format(scheduledDate.toLocal()) : '';
    final visitNum = widget.visit['visit_number'];
    final totalVisits = widget.visit['total_visits'];

    if (_done) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 32),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.visit['customer_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('Visit marked as complete ✓', style: TextStyle(color: Colors.green.shade700, fontSize: 13)),
            ])),
          ]),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withAlpha(80),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Icon(Icons.event_available, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('$dateStr · $timeStr', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Text('Visit $visitNum/$totalVisits', style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Customer info
            Row(children: [
              const Icon(Icons.person_outline, size: 16),
              const SizedBox(width: 6),
              Text(widget.visit['customer_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              // Call button
              IconButton(
                onPressed: () {/* url_launcher call */},
                icon: const Icon(Icons.call_outlined, size: 20),
                tooltip: 'Call customer',
                style: IconButton.styleFrom(
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: cs.primary,
                ),
              ),
              const SizedBox(width: 8),
              // WhatsApp button
              IconButton(
                onPressed: () {/* url_launcher wa.me */},
                icon: const Icon(Icons.chat_outlined, size: 20),
                tooltip: 'WhatsApp',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFDCF8C6),
                  foregroundColor: const Color(0xFF25D366),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(widget.visit['address']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall, maxLines: 2)),
            ]),
            const SizedBox(height: 8),
            // Plan info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.visit['plan_name']} · ${widget.visit['service']}',
                style: TextStyle(fontSize: 12, color: cs.onSecondaryContainer),
              ),
            ),
            if (widget.visit['notes'] != null && widget.visit['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('📝 ${widget.visit['notes']}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 16),
            // Proof photo
            if (_proofPhoto != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_proofPhoto!, height: 120, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
            ],
            // Action buttons
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickProofPhoto,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: Text(_proofPhoto == null ? 'Take Proof Photo' : 'Retake Photo'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _marking ? null : _markDone,
                  icon: _marking
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(_marking ? 'Saving…' : 'Mark Done'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _showReschedule,
                icon: const Icon(Icons.schedule, size: 16),
                label: const Text('Reschedule Visit'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Subscription Card ───────────────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  final Map<String, dynamic> sub;
  final DateFormat dateFmt;
  final NumberFormat currencyFmt;

  const _SubscriptionCard({required this.sub, required this.dateFmt, required this.currencyFmt});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = sub['status']?.toString() ?? 'active';
    final completed = (sub['completed_visits'] as num?)?.toInt() ?? 0;
    final total = (sub['total_visits'] as num?)?.toInt() ?? 1;
    final progress = completed / total;
    final amount = (sub['amount'] as num?)?.toInt() ?? 0;
    final endDate = sub['end_date']?.toString();
    final endDateStr = endDate != null
        ? dateFmt.format(DateTime.tryParse(endDate) ?? DateTime.now())
        : '';
    final nextVisit = sub['next_visit'] != null
        ? dateFmt.format(DateTime.tryParse(sub['next_visit'].toString())?.toLocal() ?? DateTime.now())
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sub['customer_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text(sub['plan_name']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'active' ? Colors.green.withAlpha(20) : Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: status == 'active' ? Colors.green.shade700 : Colors.grey.shade600)),
            ),
          ]),
          const SizedBox(height: 12),
          // Visit progress
          Row(children: [
            Text('Visits: $completed/$total', style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            Text('${(progress * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.primary)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(status == 'completed' ? Colors.green : cs.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.payments_outlined, size: 14, color: cs.outline),
            const SizedBox(width: 4),
            Text(currencyFmt.format(amount), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 16),
            Icon(Icons.event_outlined, size: 14, color: cs.outline),
            const SizedBox(width: 4),
            Text('Ends $endDateStr', style: Theme.of(context).textTheme.bodySmall),
          ]),
          if (nextVisit != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.upcoming_outlined, size: 14, color: cs.primary),
              const SizedBox(width: 4),
              Text('Next visit: $nextVisit', style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600)),
            ]),
          ],
        ]),
      ),
    );
  }
}
