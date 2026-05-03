import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/booking_service.dart';

/// One-tap rebooking screen.
/// Shows previous bookings and allows instant rebooking with the same professional.
class RebookingSheet extends StatelessWidget {
  final Booking booking;

  const RebookingSheet({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.replay, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Rebook: ${booking.title}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.professionalName ?? 'Same Professional',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                if (booking.categoryName != null) ...[
                  const SizedBox(height: 4),
                  Text(booking.categoryName!, style: Theme.of(context).textTheme.bodySmall),
                ],
                if (booking.serviceAddress != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(booking.serviceAddress!, style: Theme.of(context).textTheme.bodySmall)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _rebook(context),
            icon: const Icon(Icons.flash_on),
            label: const Text('Book Again — 1 Tap'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
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
