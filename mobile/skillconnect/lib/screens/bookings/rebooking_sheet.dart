import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/booking_service.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

/// One-tap rebooking screen.
/// Shows previous bookings and allows instant rebooking with the same professional.
class RebookingSheet extends StatelessWidget {
  final Booking booking;

  const RebookingSheet({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      child: PremiumBackground(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(180),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.primaryGradient),
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    boxShadow: AppShadows.lg(AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(24),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: Colors.white.withAlpha(40)),
                        ),
                        child: const Icon(Icons.replay_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Book Again',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withAlpha(225),
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PremiumGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking snapshot',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _DetailRow(
                        icon: Icons.person_rounded,
                        label: 'Professional',
                        value: booking.professionalName ?? 'Same Professional',
                      ),
                      if (booking.categoryName != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _DetailRow(
                          icon: Icons.category_rounded,
                          label: 'Service',
                          value: booking.categoryName!,
                        ),
                      ],
                      if (booking.serviceAddress != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _DetailRow(
                          icon: Icons.location_on_rounded,
                          label: 'Address',
                          value: booking.serviceAddress!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PremiumGradientButton(
                  label: 'Book Again — 1 Tap',
                  icon: Icons.flash_on_rounded,
                  onPressed: () => _rebook(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white.withAlpha(230),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _rebook(BuildContext context) async {
    try {
      await BookingService.create(
        professionalId: booking.professionalId,
        title: booking.title,
        description: booking.description,
        categoryId: booking.categoryId,
        serviceAddress: booking.serviceAddress,
      );
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Booked again! You\'ll get confirmation shortly.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(18),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
