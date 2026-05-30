import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/booking_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/app_components.dart';
import '../../widgets/premium_ui.dart';
import '../messages/chat_screen.dart';
import '../reviews/post_service_rating_screen.dart';
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

  int _getStepIndex(String status) {
    switch (status) {
      case 'requested': return 0;
      case 'quoted': return 1;
      case 'accepted': return 2;
      case 'scheduled': return 3;
      case 'in_progress': return 4;
      case 'completed': return 6; // All done
      default: return 0;
    }
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
      // Use the new delightful multi-step rating experience
      final result = await Navigator.push<bool>(context, MaterialPageRoute(
        builder: (_) => PostServiceRatingScreen(
          bookingId: _booking!.id,
          professionalName: _booking!.professionalName ?? 'Professional',
          serviceName: _booking!.description ?? 'Service',
        ),
      ));
      if (result == true && mounted) _load();
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Booking', style: TextStyle(fontWeight: FontWeight.w800)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: AppColors.primaryGradient),
          ),
        ),
        actions: [
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
        ],
      ),
      body: PremiumBackground(
        child: SafeArea(
          top: false,
          child: _loading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    PremiumHeroHeader(
                      title: 'Booking Details',
                      subtitle: 'Preparing your premium booking view with latest status and actions.',
                      icon: Icons.receipt_long_rounded,
                      gradient: AppColors.heroGradient,
                      chips: [
                        PremiumStatChip(label: 'Real-time', icon: Icons.sync_rounded, color: Colors.white),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: PremiumLoadingList(itemCount: 4, itemHeight: 140),
                    ),
                  ],
                )
              : _error != null
                  ? RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const PremiumHeroHeader(
                            title: 'Booking Details',
                            subtitle: 'We could not load the latest information for this booking right now.',
                            icon: Icons.receipt_long_rounded,
                            gradient: AppColors.heroGradient,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: PremiumEmptyState(
                              icon: Icons.cloud_off_rounded,
                              title: 'Unable to load booking',
                              subtitle: _error!,
                              actionLabel: 'Retry',
                              onAction: _load,
                              gradient: AppColors.warmGradient,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(onRefresh: _load, child: _buildBody(isPro)),
        ),
      ),
    );
  }

  Widget _buildBody(bool isPro) {
    final b = _booking!;
    final statusColor = bookingStatusColor(b.status);
    final otherName = isPro ? (b.customerName ?? 'Customer') : (b.professionalName ?? 'Professional');
    final actions = _availableActions(isPro);
    final amount = b.finalAmount ?? b.quotedAmount;

    // Determine current step for the step indicator
    final stepIndex = _getStepIndex(b.status);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        PremiumHeroHeader(
          title: b.title,
          subtitle: b.description ?? 'A premium service journey with live status updates and guided actions.',
          icon: Icons.receipt_long_rounded,
          gradient: AppColors.heroGradient,
          trailing: _DetailAmountCard(amount: amount),
          chips: [
            PremiumStatChip(label: prettyStatus(b.status), icon: Icons.flag_rounded, color: Colors.white),
            PremiumStatChip(label: otherName, icon: isPro ? Icons.person_rounded : Icons.verified_user_rounded, color: Colors.white),
          ],
        ),
        if (b.status != 'cancelled' && b.status != 'disputed')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: PremiumGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Journey Progress',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  StepIndicator(
                    currentStep: stepIndex,
                    steps: const ['Requested', 'Quoted', 'Accepted', 'Scheduled', 'In Progress', 'Done'],
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
          child: Row(
            children: [
              Expanded(
                child: PremiumMetricCard(
                  label: 'Status',
                  value: prettyStatus(b.status),
                  icon: Icons.flag_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PremiumMetricCard(
                  label: 'Created',
                  value: DateFormat('MMM d').format(b.createdAt.toLocal()),
                  icon: Icons.schedule_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          child: PremiumGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PremiumStatusPill(label: prettyStatus(b.status), color: statusColor),
                    const Spacer(),
                    if (amount != null)
                      Text(
                        '₹${amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.primaryGradient),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Center(
                        child: Text(
                          otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPro ? 'Customer' : 'Professional',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            otherName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (b.description != null && b.description!.trim().isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(110),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: Colors.white.withAlpha(150)),
                    ),
                    child: Text(
                      b.description!,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                _kv(Icons.event, 'Scheduled', b.scheduledFor != null ? DateFormat('MMM d, y • h:mm a').format(b.scheduledFor!.toLocal()) : 'To be confirmed'),
                if (b.serviceAddress != null) _kv(Icons.location_on_outlined, 'Address', b.serviceAddress!),
                if (b.categoryName != null) _kv(Icons.category_outlined, 'Service', b.categoryName!),
                _kv(Icons.access_time, 'Created', DateFormat('MMM d, y • h:mm a').format(b.createdAt.toLocal())),
              ],
            ),
          ),
        ),
        if (actions.isNotEmpty) ...[
          const PremiumSectionTitle(
            title: 'Available Actions',
            subtitle: 'Take the next step in this booking journey.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: PremiumGlassCard(
              child: Column(
                children: [
                  for (final a in actions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Opacity(
                        opacity: _acting ? 0.6 : 1,
                        child: IgnorePointer(
                          ignoring: _acting,
                          child: PremiumGradientButton(
                            label: a.label,
                            icon: a.icon,
                            colors: a.danger ? AppColors.warmGradient : AppColors.primaryGradient,
                            onPressed: () => _runAction(a),
                          ),
                        ),
                      ),
                    ),
                  if (_acting)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: aColor(actions),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Processing update...',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
        const PremiumSectionTitle(
          title: 'Timeline',
          subtitle: 'Every booking movement, beautifully organized.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: PremiumGlassCard(
            child: Column(
              children: [
                for (int i = 0; i < b.statusLog.length; i++)
                  _TimelineTile(
                    log: b.statusLog[i],
                    isLast: i == b.statusLog.length - 1,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _kv(IconData icon, String k, String v) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(110),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withAlpha(150)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(18),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              k,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(v, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    ),
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

Color aColor(List<_Action> actions) => actions.any((a) => !a.danger) ? AppColors.primary : AppColors.error;

class _DetailAmountCard extends StatelessWidget {
  final double? amount;

  const _DetailAmountCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Column(
        children: [
          Text(
            amount != null ? '₹${amount!.toStringAsFixed(0)}' : '—',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Amount',
            style: TextStyle(
              color: Colors.white.withAlpha(215),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final BookingStatusLog log;
  final bool isLast;

  const _TimelineTile({required this.log, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = bookingStatusColor(log.toStatus);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: AppShadows.sm(color),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 70,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color.withAlpha(160), color.withAlpha(0)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(110),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: Colors.white.withAlpha(150)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          prettyStatus(log.toStatus),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                      PremiumStatusPill(label: prettyStatus(log.toStatus), color: color),
                    ],
                  ),
                  if (log.note != null && log.note!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      log.note!,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.45),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    DateFormat('MMM d, h:mm a').format(log.createdAt.toLocal()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
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
