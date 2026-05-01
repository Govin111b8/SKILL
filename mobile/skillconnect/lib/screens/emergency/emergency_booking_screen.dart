import 'package:flutter/material.dart';
import '../../services/api_service.dart';

/// Emergency mode — priority booking with faster matching and premium pricing.
class EmergencyBookingScreen extends StatefulWidget {
  const EmergencyBookingScreen({super.key});

  @override
  State<EmergencyBookingScreen> createState() => _EmergencyBookingScreenState();
}

class _EmergencyBookingScreenState extends State<EmergencyBookingScreen> {
  String? _selectedService;
  final _descCtl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  final _emergencyServices = [
    ('Plumbing Emergency', Icons.plumbing, 'Burst pipe, leak, no water'),
    ('Electrical Emergency', Icons.electric_bolt, 'Power outage, sparking, short circuit'),
    ('AC Emergency', Icons.ac_unit, 'Not cooling in extreme heat'),
    ('Lock Emergency', Icons.lock_open, 'Locked out, broken lock'),
    ('Appliance Breakdown', Icons.kitchen, 'Fridge, washing machine failure'),
  ];

  Future<void> _submitEmergency() async {
    if (_selectedService == null) return;
    setState(() => _submitting = true);
    try {
      await ApiService.post('/bookings/emergency', {
        'service_type': _selectedService,
        'description': _descCtl.text.trim(),
        'priority': 'urgent',
      }, auth: true);
      setState(() => _submitted = true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _descCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emergency, size: 72, color: Colors.orange),
                const SizedBox(height: 16),
                Text('Emergency Request Sent! 🚨', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text(
                  'We\'re finding the nearest available professional. You\'ll be connected within 5 minutes.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Emergency Booking'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Emergency bookings have priority matching. Higher pricing may apply.',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('What\'s the emergency?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            ...List.generate(_emergencyServices.length, (i) {
              final (name, icon, desc) = _emergencyServices[i];
              final selected = _selectedService == name;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedService = name),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected ? Colors.red : Theme.of(context).dividerColor,
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: selected ? Colors.red.shade50 : null,
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: selected ? Colors.red : Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? Colors.red.shade700 : null)),
                              Text(desc, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        if (selected) const Icon(Icons.check_circle, color: Colors.red),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),
            TextField(
              controller: _descCtl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Brief description (optional)',
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: (_selectedService != null && !_submitting) ? _submitEmergency : null,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.emergency),
              label: Text(_submitting ? 'Submitting...' : 'Request Emergency Service'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
