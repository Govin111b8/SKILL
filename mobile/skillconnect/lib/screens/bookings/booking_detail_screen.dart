import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/booking_service.dart';
import '../messages/chat_screen.dart';
import 'bookings_list_screen.dart' show bookingStatusColor, prettyStatus;

class BookingDetailScreen extends StatefulWidget {
  /// Pass either [bookingId] (fetches from API) or [booking] (uses directly, still refreshes).
  final String? bookingId;
  final Booking? booking;
  const BookingDetailScreen({super.key, this.bookingId, this.booking})
      : assert(bookingId != null || booking != null, 'Provide bookingId or booking');

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Booking? _booking;
  bool _loading = true;
  String? _error;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    if (widget.booking != null) {
      _booking = widget.booking;
      _loading = false;
      // Still refresh in background for latest status
      _refreshSilent();
    } else {
      _load();
    }
  }

  Future<void> _refreshSilent() async {
    try {
      final fresh = await BookingService.get(widget.booking!.id);
      if (mounted) setState(() => _booking = fresh);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final id = widget.bookingId ?? widget.booking!.id;
      _booking = await BookingService.get(id);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  // Allowed transitions per role for each current state
  List<_Action> _availableActions(bool isPro) {
    final s = _booking!.status;
    final actions = <_Action>[];
    if (isPro) {
      if (s == 'requested') {
        actions.add(_Action('Send Quote', 'quoted', Icons.local_offer, askAmount: true));
        actions.add(_Action('Decline', 'cancelled', Icons.close, danger: true, askReason: true));
      } else if (s == 'accepted') {
        actions.add(_Action('Schedule', 'scheduled', Icons.event, askDate: true));
      } else if (s == 'scheduled') {
        actions.add(_Action('Start Job', 'in_progress', Icons.play_arrow));
      } else if (s == 'in_progress') {
        actions.add(_Action('Mark Completed', 'completed', Icons.check_circle, askAmount: true, amountLabel: 'Final amount'));
      }
    } else {
      // customer
      if (s == 'quoted') {
        actions.add(_Action('Accept Quote', 'accepted', Icons.check));
        actions.add(_Action('Decline', 'cancelled', Icons.close, danger: true, askReason: true));
      } else if (s == 'requested' || s == 'accepted' || s == 'scheduled') {
        actions.add(_Action('Cancel', 'cancelled', Icons.cancel, danger: true, askReason: true));
      } else if (s == 'completed') {
        actions.add(_Action('Rate & Review', '__review__', Icons.star));
        actions.add(_Action('Raise Dispute', 'disputed', Icons.report_problem, danger: true, askReason: true));
      } else if (s == 'in_progress') {
        actions.add(_Action('Raise Dispute', 'disputed', Icons.report_problem, danger: true, askReason: true));
      }
    }
    return actions;
  }

  Future<void> _runAction(_Action a) async {
    if (a.to == '__review__') {
      await _showReviewDialog();
      return;
    }
    final payload = <String, dynamic>{};
    String? note;

    if (a.askAmount) {
      final ctrl = TextEditingController(text: _booking!.quotedAmount?.toStringAsFixed(0) ?? '');
      final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
        title: Text(a.amountLabel ?? 'Quote amount (₹)'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(prefixText: '₹ ', hintText: '0')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
        ],
      ));
      if (ok != true) return;
      final amt = double.tryParse(ctrl.text);
      if (amt == null || amt <= 0) return;
      if (a.to == 'quoted') {
        payload['quoted_amount'] = amt;
      } else if (a.to == 'completed') {
        payload['final_amount'] = amt;
      }
    }

    if (a.askDate) {
      final date = await showDatePicker(context: context,
          firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDate: DateTime.now().add(const Duration(days: 1)));
      if (date == null) return;
      if (!mounted) return;
      final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
      if (time == null) return;
      payload['scheduled_for'] = DateTime(date.year, date.month, date.day, time.hour, time.minute).toIso8601String();
    }

    if (a.askReason) {
      final ctrl = TextEditingController();
      if (!mounted) return;
      final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
        title: Text(a.danger ? 'Reason' : 'Note'),
        content: TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Brief reason...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ));
      if (ok != true) return;
      note = ctrl.text.trim();
      if (a.to == 'cancelled' && note.isNotEmpty) payload['cancellation_reason'] = note;
    }

    if (mounted) setState(() => _acting = true);
    try {
      HapticFeedback.mediumImpact();
      await BookingService.transition(_booking!.id, a.to, note: note, payload: payload.isEmpty ? null : payload);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Updated to ${prettyStatus(a.to)}'), backgroundColor: Colors.green));
      if (mounted && !context.read<AuthService>().isProfessional && _booking?.status == 'completed') {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showReviewDialog());
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$e'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _acting = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isPro = auth.isProfessional;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking'), actions: [
        if (_booking != null)
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Open chat',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ChatScreen(
                otherUserId: isPro ? _booking!.customerId : _booking!.professionalId,
                otherName: isPro ? (_booking!.customerName ?? 'Customer') : (_booking!.professionalName ?? 'Pro'),
                bookingId: _booking!.id,
                openWith: isPro ? 'customer' : 'professional',
              ),
            )),
          ),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : RefreshIndicator(onRefresh: _load, child: _buildBody(isPro)),
    );
  }

  Widget _buildBody(bool isPro) {
    final b = _booking!;
    final statusColor = bookingStatusColor(b.status);
    final otherName = isPro ? (b.customerName ?? 'Customer') : (b.professionalName ?? 'Professional');
    final actions = _availableActions(isPro);
    final cs = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(prettyStatus(b.status), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          if (b.quotedAmount != null)
            Text('₹${(b.finalAmount ?? b.quotedAmount)!.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.primary)),
        ]),
        const SizedBox(height: 14),
        Text(b.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (b.description != null) ...[
          const SizedBox(height: 8),
          Text(b.description!, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
        ],
        const Divider(height: 28),
        Row(children: [
          CircleAvatar(backgroundColor: cs.primaryContainer, child: Text(otherName[0].toUpperCase(), style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isPro ? 'Customer' : 'Professional', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            Text(otherName, style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ]),
        if (b.scheduledFor != null) ...[
          const SizedBox(height: 12),
          _kv(Icons.event, 'Scheduled', DateFormat('MMM d, y • h:mm a').format(b.scheduledFor!.toLocal())),
        ],
        if (b.serviceAddress != null) _kv(Icons.location_on_outlined, 'Address', b.serviceAddress!),
        if (b.categoryName != null) _kv(Icons.category_outlined, 'Service', b.categoryName!),
        _kv(Icons.access_time, 'Created', DateFormat('MMM d, y • h:mm a').format(b.createdAt.toLocal())),
      ]))),
      if (actions.isNotEmpty) ...[
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          for (final a in actions)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: SizedBox(
              height: 48,
              child: a.danger
                  ? OutlinedButton.icon(
                      onPressed: _acting ? null : () => _runAction(a),
                      icon: Icon(a.icon, color: Colors.red),
                      label: Text(a.label, style: const TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                    )
                  : FilledButton.icon(
                      onPressed: _acting ? null : () => _runAction(a),
                      icon: Icon(a.icon),
                      label: Text(a.label),
                    ),
            )),
        ]))),
      ],
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        for (final log in b.statusLog)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 10, height: 10, margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(color: bookingStatusColor(log.toStatus), shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(prettyStatus(log.toStatus), style: const TextStyle(fontWeight: FontWeight.w600)),
              if (log.note != null && log.note!.isNotEmpty)
                Text(log.note!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              Text(DateFormat('MMM d, h:mm a').format(log.createdAt.toLocal()),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ])),
          ])),
      ]))),
    ]);
  }

  Widget _kv(IconData icon, String k, String v) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: Colors.grey.shade600),
      const SizedBox(width: 8),
      Text('$k: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      Expanded(child: Text(v, style: const TextStyle(fontSize: 13))),
    ]),
  );

  Future<void> _showReviewDialog() async {
    if (_booking == null) return;
    double rating = 5;
    final ctrl = TextEditingController();
    bool submitting = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (_, setS) => AlertDialog(
        title: const Text('Rate your experience'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: RatingBar.builder(
            initialRating: rating, minRating: 1, allowHalfRating: false, itemCount: 5, itemSize: 36,
            itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (v) => setS(() => rating = v),
          )),
          const SizedBox(height: 16),
          TextField(controller: ctrl, maxLines: 3,
              decoration: const InputDecoration(hintText: 'Share details (optional)')),
        ]),
        actions: [
          TextButton(onPressed: submitting ? null : () => Navigator.pop(ctx, false), child: const Text('Later')),
          FilledButton(
            onPressed: submitting ? null : () async {
              setS(() => submitting = true);
              try {
                await ApiService.post('/reviews', {
                  'professional_id': _booking!.professionalId,
                  'booking_id': _booking!.id,
                  'rating': rating.toInt(),
                  if (ctrl.text.trim().isNotEmpty) 'comment': ctrl.text.trim(),
                }, auth: true);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                setS(() => submitting = false);
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
              }
            },
            child: submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit'),
          ),
        ],
      )),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Thanks for your feedback!'), backgroundColor: Colors.green));
    }
  }
}

class _Action {
  final String label;
  final String to;
  final IconData icon;
  final bool danger;
  final bool askAmount;
  final bool askDate;
  final bool askReason;
  final String? amountLabel;
  _Action(this.label, this.to, this.icon, {this.danger = false, this.askAmount = false, this.askDate = false, this.askReason = false, this.amountLabel});
}
