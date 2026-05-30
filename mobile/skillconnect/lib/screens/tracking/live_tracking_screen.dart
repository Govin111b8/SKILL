import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/realtime_service.dart';
import '../messages/chat_screen.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

/// Live job tracking screen — shows real-time provider location and status
/// during active bookings (similar to Swiggy/Zomato tracking).
class LiveTrackingScreen extends StatefulWidget {
  final String bookingId;
  final String professionalName;
  final String? professionalUserId;
  final String? professionalPhone;

  const LiveTrackingScreen({
    super.key,
    required this.bookingId,
    required this.professionalName,
    this.professionalUserId,
    this.professionalPhone,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  String _status = 'assigned';
  String? _eta;
  double? _providerLat;
  double? _providerLng;
  StreamSubscription<Map<String, dynamic>>? _trackingSub;

  final _statusSteps = [
    ('assigned', 'Professional Assigned', Icons.person_pin),
    ('on_the_way', 'On the Way', Icons.directions_car),
    ('arrived', 'Arrived at Location', Icons.location_on),
    ('in_progress', 'Work in Progress', Icons.build),
    ('completed', 'Job Completed', Icons.check_circle),
  ];

  @override
  void initState() {
    super.initState();
    _trackingSub = RealtimeService.instance.on('booking_tracking').listen((event) {
      if (event['booking_id'] == widget.bookingId) {
        setState(() {
          _status = event['status']?.toString() ?? _status;
          _eta = event['eta']?.toString();
          _providerLat = (event['lat'] as num?)?.toDouble();
          _providerLng = (event['lng'] as num?)?.toDouble();
        });
      }
    });
  }

  @override
  void dispose() {
    _trackingSub?.cancel();
    super.dispose();
  }

  int get _currentStep {
    final idx = _statusSteps.indexWhere((s) => s.$1 == _status);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final current = _statusSteps[_currentStep];
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const PremiumAppBar(title: 'Live Tracking'),
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.huge, AppSpacing.lg, AppSpacing.xl),
                  children: [
                    PremiumGlassCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      gradient: [
                        Colors.white.withAlpha(235),
                        Colors.white.withAlpha(170),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: AppColors.primaryGradient),
                                  shape: BoxShape.circle,
                                  boxShadow: AppShadows.md(AppColors.primary),
                                ),
                                child: const Icon(Icons.person_rounded, color: Colors.white, size: 34),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.professionalName,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Booking #${widget.bookingId.substring(0, widget.bookingId.length > 8 ? 8 : widget.bookingId.length)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    PremiumStatusPill(
                                      label: current.$2,
                                      color: _stepColor(_currentStep),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: AppColors.primaryGradient),
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              boxShadow: AppShadows.lg(AppColors.primary),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _eta != null ? 'ETA • $_eta' : 'Live ETA updating',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        _eta != null
                                            ? _status == 'on_the_way'
                                                ? 'Your professional is on the move.'
                                                : 'Stay ready — the journey is in progress.'
                                            : 'We’ll update the arrival estimate in real time.',
                                        style: TextStyle(
                                          color: Colors.white.withAlpha(220),
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(28),
                                    borderRadius: BorderRadius.circular(AppRadius.xl),
                                  ),
                                  child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 28),
                                ),
                              ],
                            ),
                          ),
                          if (_providerLat != null && _providerLng != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                _infoChip(
                                  icon: Icons.my_location_rounded,
                                  label: 'Lat ${_providerLat!.toStringAsFixed(4)}',
                                  color: AppColors.info,
                                ),
                                _infoChip(
                                  icon: Icons.explore_rounded,
                                  label: 'Lng ${_providerLng!.toStringAsFixed(4)}',
                                  color: AppColors.accent,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const PremiumSectionTitle(
                      title: 'Service journey',
                      subtitle: 'Track each step just like your favorite delivery apps.',
                    ),
                    ...List.generate(_statusSteps.length, (i) => _buildTimelineCard(context, i)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        label: 'Message',
                        icon: Icons.chat_bubble_outline_rounded,
                        color: cs.surface,
                        foreground: cs.onSurface,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                otherName: widget.professionalName,
                                otherUserId: widget.professionalUserId,
                                bookingId: widget.bookingId,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildActionButton(
                        label: 'Call',
                        icon: Icons.call_rounded,
                        color: AppColors.primary,
                        foreground: Colors.white,
                        onTap: () async {
                          final phone = widget.professionalPhone;
                          if (phone != null && phone.isNotEmpty) {
                            final uri = Uri(scheme: 'tel', path: phone);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Phone number not available')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, int i) {
    final (_, label, icon) = _statusSteps[i];
    final isComplete = i <= _currentStep;
    final isCurrent = i == _currentStep;
    final color = _stepColor(i);

    return Padding(
      padding: EdgeInsets.only(bottom: i == _statusSteps.length - 1 ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1400),
                  tween: Tween(begin: 0.9, end: isCurrent ? 1.08 : 1.0),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) => Transform.scale(scale: value, child: child),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isComplete
                          ? LinearGradient(colors: [color, color.withAlpha(180)])
                          : null,
                      color: isComplete ? null : Colors.white.withAlpha(180),
                      border: Border.all(
                        color: isComplete ? Colors.transparent : AppColors.borderLight,
                        width: 1.6,
                      ),
                      boxShadow: isCurrent ? AppShadows.lg(color) : (isComplete ? AppShadows.sm(color) : null),
                    ),
                    child: Icon(icon, size: 18, color: isComplete ? Colors.white : Colors.grey.shade500),
                  ),
                ),
                if (i < _statusSteps.length - 1)
                  Container(
                    width: 4,
                    height: 66,
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: i < _currentStep
                            ? [color, _stepColor(i + 1)]
                            : [AppColors.borderLight, AppColors.borderLight],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: PremiumGlassCard(
              gradient: isCurrent
                  ? [color.withAlpha(20), Colors.white.withAlpha(190)]
                  : [Colors.white.withAlpha(215), Colors.white.withAlpha(165)],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w800,
                            color: isComplete ? AppColors.surfaceDark : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        PremiumStatusPill(label: 'Current', color: color)
                      else if (isComplete)
                        PremiumStatusPill(label: 'Done', color: color),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isCurrent
                        ? _currentStep == 1 && _eta != null
                            ? 'Arriving in $_eta'
                            : 'This is the active step for your booking right now.'
                        : isComplete
                            ? 'Completed successfully.'
                            : 'Up next in your service timeline.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color foreground,
    required Future<void> Function() onTap,
  }) {
    return GestureDetector(
      onTap: () { onTap(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: color == Colors.white || color == Theme.of(context).colorScheme.surface
              ? Border.all(color: AppColors.borderLight)
              : null,
          boxShadow: color == Colors.white || color == Theme.of(context).colorScheme.surface
              ? AppShadows.sm(AppColors.primary.withAlpha(40))
              : AppShadows.md(color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Color _stepColor(int index) {
    switch (index) {
      case 0:
        return AppColors.info;
      case 1:
        return AppColors.primary;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.accent;
      default:
        return AppColors.success;
    }
  }
}
