import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../reviews/write_review_screen.dart';

class MyContactsScreen extends StatefulWidget {
  const MyContactsScreen({super.key});

  @override
  State<MyContactsScreen> createState() => _MyContactsScreenState();
}

class _MyContactsScreenState extends State<MyContactsScreen> {
  List<Contact> _contacts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/contacts', auth: true);
      _contacts = (res['data'] as List).map((e) => Contact.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _updateStatus(String contactId, String status) async {
    try {
      await ApiService.put('/contacts/$contactId/status', {'status': status}, auth: true);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Contact ${status == 'accepted' ? 'accepted' : 'declined'}'),
          backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.read<AuthService>().isProfessional;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Contacts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : _contacts.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No contacts yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                      if (!isPro) ...[
                        const SizedBox(height: 8),
                        Text('Search for professionals to get started', style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _contacts.length,
                        itemBuilder: (_, i) {
                          final c = _contacts[i];
                          return _ContactTile(
                            contact: c,
                            isPro: isPro,
                            cs: cs,
                            onAccept: () => _updateStatus(c.id, 'accepted'),
                            onDecline: () => _updateStatus(c.id, 'declined'),
                            onReview: () async {
                              final result = await Navigator.push(context, MaterialPageRoute(
                                builder: (_) => WriteReviewScreen(
                                  professionalId: c.professionalId,
                                  contactId: c.id,
                                  professionalName: c.professionalName ?? 'Professional',
                                ),
                              ));
                              if (result == true) _load();
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final bool isPro;
  final ColorScheme cs;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onReview;

  const _ContactTile({required this.contact, required this.isPro, required this.cs, required this.onAccept, required this.onDecline, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final name = isPro ? (contact.customerName ?? 'Customer') : (contact.professionalName ?? 'Professional');
    final statusColor = _statusColor(contact.status);
    final typeIcon = _typeIcon(contact.contactType);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: cs.primaryContainer,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(typeIcon, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(_formatType(contact.contactType), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(width: 8),
                  Text(_timeAgo(contact.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                ]),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withAlpha(30), borderRadius: BorderRadius.circular(12)),
              child: Text(contact.status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
            ),
          ]),
          if (contact.message != null && contact.message!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
              child: Text(contact.message!, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ),
          ],
          // Actions for professionals
          if (isPro && contact.status == 'pending') ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDecline,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Decline'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accept'),
                ),
              ),
            ]),
          ],
          // Review button for customers with accepted contacts
          if (!isPro && contact.status == 'accepted') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.rate_review, size: 18),
                label: const Text('Write Review'),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'accepted': return Colors.green;
      case 'declined': return Colors.red;
      default: return Colors.orange;
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'call': return Icons.phone;
      case 'quote_request': return Icons.request_quote;
      default: return Icons.message;
    }
  }

  String _formatType(String t) {
    switch (t) {
      case 'call': return 'Phone Call';
      case 'quote_request': return 'Quote Request';
      default: return 'Message';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
