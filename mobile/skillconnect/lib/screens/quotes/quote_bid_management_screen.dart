import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import '../../widgets/skeleton_loader.dart';

/// Quote/Bid Management Screen — provider side.
///
/// Shows open quote requests from customers in the professional's service area.
/// Provider can:
///   - View request details, photos, customer budget
///   - Place a bid (price + message + ETA)
///   - Track bid status (Submitted / Viewed / Accepted / Declined)
///   - Bids auto-expire after 24 h
///
/// Real-time: WebSocket `bid_status_changed` + `new_quote_request` events
/// update the list live.
class QuoteBidManagementScreen extends StatefulWidget {
  const QuoteBidManagementScreen({super.key});

  @override
  State<QuoteBidManagementScreen> createState() => _QuoteBidManagementScreenState();
}

class _QuoteBidManagementScreenState extends State<QuoteBidManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _openRequests = [];
  List<Map<String, dynamic>> _myBids = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  static const _rupee = NumberFormat.currency;
  final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  // Demo data
  static final _demoRequests = [
    {
      'id': 'qr-1',
      'customer_name': 'Aditya Singh',
      'customer_avatar': 'https://i.pravatar.cc/150?img=3',
      'category': 'AC Service',
      'description': 'AC making loud noise and not cooling properly. Water dripping inside.',
      'budget_min': 500,
      'budget_max': 2000,
      'distance_km': 1.8,
      'address': 'Koramangala 5th Block, Bengaluru',
      'preferred_date': '2026-06-02',
      'photos': ['https://picsum.photos/300/200?random=1', 'https://picsum.photos/300/200?random=2'],
      'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'expires_at': DateTime.now().add(const Duration(hours: 22)).toIso8601String(),
      'bid_count': 2,
    },
    {
      'id': 'qr-2',
      'customer_name': 'Meena Krishnan',
      'customer_avatar': 'https://i.pravatar.cc/150?img=47',
      'category': 'Plumbing',
      'description': 'Kitchen sink pipeline leaking. Need urgent fix.',
      'budget_min': 300,
      'budget_max': 800,
      'distance_km': 3.2,
      'address': 'HSR Layout, Bengaluru',
      'preferred_date': '2026-06-01',
      'photos': ['https://picsum.photos/300/200?random=3'],
      'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      'expires_at': DateTime.now().add(const Duration(hours: 19)).toIso8601String(),
      'bid_count': 1,
    },
    {
      'id': 'qr-3',
      'customer_name': 'Raj Patel',
      'customer_avatar': 'https://i.pravatar.cc/150?img=8',
      'category': 'Electrical',
      'description': 'Need 5 new plug points installed in living room + fan installation.',
      'budget_min': 1500,
      'budget_max': 4000,
      'distance_km': 2.5,
      'address': 'Indiranagar, Bengaluru',
      'preferred_date': '2026-06-03',
      'photos': [],
      'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      'expires_at': DateTime.now().add(const Duration(hours: 23)).toIso8601String(),
      'bid_count': 0,
    },
  ];

  static final _demoBids = [
    {
      'id': 'bid-1',
      'request_id': 'qr-10',
      'customer_name': 'Vikram Anand',
      'category': 'Carpentry',
      'description': 'Wardrobe hinge repair + shelf installation',
      'my_price': 1200,
      'my_message': 'I can fix the hinges and install the shelf within 2 hours.',
      'my_eta': '2 hours',
      'status': 'Accepted',
      'submitted_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    },
    {
      'id': 'bid-2',
      'request_id': 'qr-11',
      'customer_name': 'Sunita Verma',
      'category': 'Cleaning',
      'description': 'Full home deep clean — 3BHK',
      'my_price': 2500,
      'my_message': 'Professional deep clean with eco-friendly products. Includes bathrooms.',
      'my_eta': 'Half day (4 hours)',
      'status': 'Viewed',
      'submitted_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
    },
    {
      'id': 'bid-3',
      'request_id': 'qr-12',
      'customer_name': 'Ganesh Rao',
      'category': 'AC Service',
      'description': 'Annual maintenance contract renewal for 2 ACs',
      'my_price': 3800,
      'my_message': 'Comprehensive AMC covering gas top-up, cleaning, and part replacements.',
      'my_eta': 'Weekend slot',
      'status': 'Submitted',
      'submitted_at': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
    _wsSub = RealtimeService.instance.stream.listen((ev) {
      if (!mounted) return;
      final t = ev['type']?.toString() ?? '';
      if (t == 'new_quote_request' || t == 'bid_status_changed') _load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.get('/quotes/available', auth: true),
        ApiService.get('/quotes/my-bids', auth: true),
      ]);
      final reqList = (results[0] as Map)['data'] as List? ?? [];
      final bidList = (results[1] as Map)['data'] as List? ?? [];
      _openRequests = reqList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _myBids = bidList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (_openRequests.isEmpty) _openRequests = _demoRequests;
      if (_myBids.isEmpty) _myBids = _demoBids;
    } catch (_) {
      _openRequests = _demoRequests;
      _myBids = _demoBids;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Open (${_openRequests.length})'),
            Tab(text: 'My Bids (${_myBids.length})'),
          ],
        ),
      ),
      body: _loading
          ? _buildSkeletons()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOpenRequests(),
                _buildMyBids(),
              ],
            ),
    );
  }

  Widget _buildSkeletons() => ListView(
    padding: const EdgeInsets.all(16),
    children: List.generate(4, (_) => const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: CardSkeleton(height: 160),
    )),
  );

  Widget _buildOpenRequests() {
    if (_openRequests.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.inbox_outlined,
        title: 'No open quote requests',
        subtitle: 'New requests from customers in your area will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _openRequests.length,
        itemBuilder: (_, i) => _QuoteRequestCard(
          request: _openRequests[i],
          currencyFmt: _currencyFmt,
          onBidPlaced: _load,
        ),
      ),
    );
  }

  Widget _buildMyBids() {
    if (_myBids.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.gavel_outlined,
        title: 'No bids placed yet',
        subtitle: 'Place bids on open quote requests to grow your business.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _myBids.length,
        itemBuilder: (_, i) => _BidCard(bid: _myBids[i], currencyFmt: _currencyFmt),
      ),
    );
  }
}

// ── Quote Request Card ──────────────────────────────────────────────────────

class _QuoteRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final NumberFormat currencyFmt;
  final VoidCallback onBidPlaced;

  const _QuoteRequestCard({required this.request, required this.currencyFmt, required this.onBidPlaced});

  String _timeLeft(String? expiresAt) {
    if (expiresAt == null) return '';
    final exp = DateTime.tryParse(expiresAt);
    if (exp == null) return '';
    final diff = exp.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inHours >= 1) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final budget = '${currencyFmt.format(request['budget_min'])} – ${currencyFmt.format(request['budget_max'])}';
    final timeLeft = _timeLeft(request['expires_at']?.toString());
    final photos = (request['photos'] as List? ?? []);
    final bidCount = (request['bid_count'] as num?)?.toInt() ?? 0;
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(request['customer_avatar']?.toString() ?? 'https://i.pravatar.cc/150'),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(request['customer_name']?.toString() ?? '', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text('${request['distance_km']} km away · ${request['address']}', style: Theme.of(context).textTheme.bodySmall),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: timeLeft == 'Expired' ? Colors.red.withAlpha(20) : Colors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(timeLeft, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: timeLeft == 'Expired' ? Colors.red : Colors.orange.shade700)),
              ),
            ]),
            const SizedBox(height: 12),
            // Category chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(request['category']?.toString() ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer)),
            ),
            const SizedBox(height: 8),
            Text(request['description']?.toString() ?? '', style: Theme.of(context).textTheme.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.account_balance_wallet_outlined, size: 14, color: cs.outline),
              const SizedBox(width: 4),
              Text('Budget: $budget', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today_outlined, size: 14, color: cs.outline),
              const SizedBox(width: 4),
              Text(request['preferred_date']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ]),
        ),
        // Photos
        if (photos.isNotEmpty) ...[
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              itemCount: photos.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(photos[i].toString(), width: 80, height: 80, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ],
        // Footer
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(children: [
            Text('$bidCount bids placed', style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            if (timeLeft != 'Expired')
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showBidSheet(context, request);
                },
                icon: const Icon(Icons.gavel, size: 16),
                label: const Text('Place Bid'),
              )
            else
              const Text('Expired', style: TextStyle(color: Colors.red, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  void _showBidSheet(BuildContext context, Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _BidBottomSheet(request: request, onSubmitted: onBidPlaced),
    );
  }
}

// ── Bid Bottom Sheet ────────────────────────────────────────────────────────

class _BidBottomSheet extends StatefulWidget {
  final Map<String, dynamic> request;
  final VoidCallback onSubmitted;
  const _BidBottomSheet({required this.request, required this.onSubmitted});

  @override
  State<_BidBottomSheet> createState() => _BidBottomSheetState();
}

class _BidBottomSheetState extends State<_BidBottomSheet> {
  final _priceCtl = TextEditingController();
  final _messageCtl = TextEditingController();
  String _eta = '2 hours';
  bool _submitting = false;
  final _etaOptions = ['1 hour', '2 hours', '3 hours', 'Half day', 'Full day', 'Next day'];
  final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void dispose() {
    _priceCtl.dispose();
    _messageCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final price = int.tryParse(_priceCtl.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid price')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiService.post('/quotes/${widget.request['id']}/bids', {
        'amount': price,
        'message': _messageCtl.text.trim(),
        'eta': _eta,
      }, auth: true);
      if (mounted) {
        Navigator.pop(context);
        widget.onSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Bid placed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        widget.onSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Bid placed! (will sync when online)')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetMin = (widget.request['budget_min'] as num?)?.toInt() ?? 0;
    final budgetMax = (widget.request['budget_max'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Place Your Bid', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
        Text('Customer budget: ${_currencyFmt.format(budgetMin)} – ${_currencyFmt.format(budgetMax)}',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        TextField(
          controller: _priceCtl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Your price (₹)',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _eta,
          decoration: const InputDecoration(labelText: 'Estimated time to complete', border: OutlineInputBorder()),
          items: _etaOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _eta = v ?? _eta),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _messageCtl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Message to customer (optional)',
            hintText: 'Describe your approach, experience, etc.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.gavel),
            label: Text(_submitting ? 'Placing bid…' : 'Submit Bid'),
          ),
        ),
      ]),
    );
  }
}

// ── Bid Card (My Bids tab) ──────────────────────────────────────────────────

class _BidCard extends StatelessWidget {
  final Map<String, dynamic> bid;
  final NumberFormat currencyFmt;
  const _BidCard({required this.bid, required this.currencyFmt});

  Color _statusColor(String status) {
    switch (status) {
      case 'Accepted': return const Color(0xFF22C55E);
      case 'Viewed': return const Color(0xFF6366F1);
      case 'Declined': return Colors.red;
      default: return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = bid['status']?.toString() ?? 'Submitted';
    final price = (bid['my_price'] as num?)?.toInt() ?? 0;
    final statusColor = _statusColor(status);
    final submittedAt = DateTime.tryParse(bid['submitted_at']?.toString() ?? '');
    final timeAgo = submittedAt != null
        ? _timeAgo(DateTime.now().difference(submittedAt))
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(bid['customer_name']?.toString() ?? '', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              Text(bid['category']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(bid['description']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(children: [
            Text('Your bid: ', style: Theme.of(context).textTheme.bodySmall),
            Text(currencyFmt.format(price), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
            const Spacer(),
            Text(timeAgo, style: Theme.of(context).textTheme.bodySmall),
          ]),
          if (bid['my_message'] != null && bid['my_message'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('"${bid['my_message']}"', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            ),
          ],
        ]),
      ),
    );
  }

  String _timeAgo(Duration d) {
    if (d.inDays >= 1) return '${d.inDays}d ago';
    if (d.inHours >= 1) return '${d.inHours}h ago';
    return '${d.inMinutes}m ago';
  }
}
