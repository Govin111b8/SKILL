import 'package:flutter/material.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../models/review.dart';

class DashboardScreen extends StatefulWidget {
  final AuthProvider auth;
  const DashboardScreen({super.key, required this.auth});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Contact> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.get('/contacts');
      final list = data is List ? data : (data['contacts'] ?? []);
      setState(() {
        _contacts = (list as List).map((j) => Contact.fromJson(j)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int contactId, String status) async {
    try {
      await ApiService.put('/contacts/$contactId/status', {'status': status});
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = widget.auth.user!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user.name.split(' ').first}'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => widget.auth.logout()),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                // User info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      CircleAvatar(radius: 30, backgroundColor: cs.primary, child: Text(user.name[0].toUpperCase(), style: TextStyle(fontSize: 24, color: cs.onPrimary))),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(user.email, style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
                          child: Text(user.role.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary)),
                        ),
                      ])),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // Contacts
                Text(user.isProfessional ? 'Contact Requests' : 'My Contacts', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                if (_contacts.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(children: [
                        Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('No contacts yet', style: TextStyle(color: Colors.grey[600])),
                      ]),
                    ),
                  )
                else
                  ..._contacts.map((c) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(
                            c.contactType == 'call' ? Icons.phone : c.contactType == 'quote_request' ? Icons.request_quote : Icons.message,
                            color: cs.primary, size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            user.isProfessional ? (c.customerName ?? 'Customer #${c.customerId}') : (c.professionalName ?? 'Professional #${c.professionalId}'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          )),
                          _statusBadge(c.status),
                        ]),
                        const SizedBox(height: 8),
                        Text(c.message, style: TextStyle(color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (user.isProfessional && c.status == 'pending') ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: OutlinedButton(onPressed: () => _updateStatus(c.id, 'declined'), child: const Text('Decline'))),
                            const SizedBox(width: 12),
                            Expanded(child: FilledButton(onPressed: () => _updateStatus(c.id, 'accepted'), child: const Text('Accept'))),
                          ]),
                        ],
                      ]),
                    ),
                  )),
              ]),
            ),
    );
  }

  Widget _statusBadge(String status) {
    final colors = {
      'pending': Colors.orange,
      'accepted': Colors.green,
      'declined': Colors.red,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: (colors[status] ?? Colors.grey).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors[status] ?? Colors.grey)),
    );
  }
}
