import 'package:flutter/material.dart';
import '../../services/api_service.dart';

/// Warranty tracking screen — shows active warranties and allows
/// post-service add-on warranty purchases with reminder notifications.
class WarrantyScreen extends StatefulWidget {
  const WarrantyScreen({super.key});

  @override
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends State<WarrantyScreen> {
  List<Map<String, dynamic>> _warranties = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.get('/warranties', auth: true);
      setState(() {
        _warranties = List<Map<String, dynamic>>.from(res['data'] as List? ?? []);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Warranty Tracker')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _warranties.isEmpty
              ? _buildEmpty(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _warranties.length,
                  itemBuilder: (context, i) => _buildWarrantyCard(context, _warranties[i]),
                ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No Active Warranties', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Warranties can be added after service completion for extended protection.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarrantyCard(BuildContext context, Map<String, dynamic> warranty) {
    final expiresAt = DateTime.tryParse(warranty['expires_at']?.toString() ?? '');
    final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());
    final daysLeft = expiresAt != null ? expiresAt.difference(DateTime.now()).inDays : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isExpired ? Icons.warning_amber : Icons.verified_user,
                  color: isExpired ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    warranty['service_name']?.toString() ?? 'Service Warranty',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExpired ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isExpired ? 'Expired' : '$daysLeft days left',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isExpired ? Colors.red : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (warranty['professional_name'] != null)
              Text('By: ${warranty['professional_name']}', style: Theme.of(context).textTheme.bodySmall),
            if (expiresAt != null)
              Text('Expires: ${expiresAt.day}/${expiresAt.month}/${expiresAt.year}',
                  style: Theme.of(context).textTheme.bodySmall),
            if (!isExpired && warranty['claimable'] == true) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to warranty claim flow
                  },
                  icon: const Icon(Icons.support_agent, size: 18),
                  label: const Text('Claim Warranty'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
