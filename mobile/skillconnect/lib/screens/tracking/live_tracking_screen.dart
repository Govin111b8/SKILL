import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/realtime_service.dart';

/// Live job tracking screen — shows real-time provider location and status
/// during active bookings (similar to Swiggy/Zomato tracking).
class LiveTrackingScreen extends StatefulWidget {
  final String bookingId;
  final String professionalName;

  const LiveTrackingScreen({
    super.key,
    required this.bookingId,
    required this.professionalName,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking')),
      body: Column(
        children: [
          // Provider info + ETA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.person, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 8),
                Text(widget.professionalName,
                    style: Theme.of(context).textTheme.titleMedium),
                if (_eta != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ETA: $_eta',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status timeline
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _statusSteps.length,
              itemBuilder: (context, i) {
                final (_, label, icon) = _statusSteps[i];
                final isComplete = i <= _currentStep;
                final isCurrent = i == _currentStep;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isComplete
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                          ),
                          child: Icon(
                            icon,
                            size: 18,
                            color: isComplete ? Colors.white : Colors.grey,
                          ),
                        ),
                        if (i < _statusSteps.length - 1)
                          Container(
                            width: 2,
                            height: 40,
                            color: i < _currentStep
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                fontSize: 15,
                                color: isComplete ? null : Colors.grey,
                              ),
                            ),
                            if (isCurrent && _status == 'on_the_way' && _eta != null)
                              Text('Arriving in $_eta', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Open chat with provider
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Message'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Call provider
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
