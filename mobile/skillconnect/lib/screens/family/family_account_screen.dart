import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/skeleton_loader.dart';

class FamilyAccountScreen extends StatefulWidget {
  const FamilyAccountScreen({super.key});

  @override
  State<FamilyAccountScreen> createState() => _FamilyAccountScreenState();
}

class _FamilyAccountScreenState extends State<FamilyAccountScreen> {
  Map<String, dynamic>? _household;
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get('/households/me', auth: true);
      final data = Map<String, dynamic>.from((res['data'] as Map?) ?? const {});
      final members = (data['members'] as List? ?? const []);
      _household = data;
      _members = members.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addMember() async {
    final controller = TextEditingController();
    final phone = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add family member'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone number'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (phone == null || phone.isEmpty) return;
    try {
      await ApiService.post('/households/me/members', {'phone': phone}, auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member invite sent.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add member: $e')));
    }
  }

  Future<void> _removeMember(String id) async {
    try {
      await ApiService.delete('/households/me/members/$id', auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member removed.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not remove member: $e')));
    }
  }

  Future<void> _editLimit(Map<String, dynamic> member) async {
    final controller = TextEditingController(text: (member['spending_limit'] ?? 0).toString());
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update spending limit'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '₹', labelText: 'Monthly limit'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (value == null || value.isEmpty) return;
    try {
      await ApiService.post('/households/me/members', {
        'member_id': member['id'],
        'spending_limit': num.tryParse(value) ?? 0,
      }, auth: true);
      if (!mounted) return;
      setState(() => member['spending_limit'] = num.tryParse(value) ?? 0);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Spending limit updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update limit: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final ownerId = (_household?['owner_id'] ?? '').toString();
    final isOwner = auth.user?['id']?.toString() == ownerId || _members.any((m) => m['role'] == 'owner' && m['user_id']?.toString() == auth.user?['id']?.toString());
    return Scaffold(
      appBar: AppBar(title: const Text('Family Account')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMember,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Member'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [SizedBox(height: 240, child: Center(child: CircularProgressIndicator()))])
            : _error != null
                ? ListView(children: [
                    EmptyStateWidget(
                      icon: Icons.home_outlined,
                      iconColor: Colors.red,
                      title: 'Could not load household',
                      subtitle: _error!,
                      actionLabel: 'Retry',
                      onAction: _load,
                    ),
                  ])
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_household?['name']?.toString() ?? 'My Household', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text('Tier: ${_household?['tier'] ?? 'Standard'}'),
                          Text('Members: ${_members.length}'),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      Text('Members', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      if (_members.isEmpty)
                        const EmptyStateWidget(
                          icon: Icons.group_outlined,
                          title: 'No family members added',
                          subtitle: 'Invite household members to manage shared bookings and budgets.',
                        )
                      else
                        ..._members.map((member) {
                          final role = (member['role'] ?? 'member').toString();
                          final canRemove = isOwner && role != 'owner';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            child: Row(children: [
                              CircleAvatar(child: Text((member['name'] ?? '').toString().trim().isEmpty ? '?' : (member['name'] ?? '').toString().trim()[0].toUpperCase())),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(member['name']?.toString() ?? 'Member', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Wrap(spacing: 8, runSpacing: 8, children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: role == 'owner' ? Theme.of(context).colorScheme.primary.withAlpha(20) : Colors.orange.withAlpha(20),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(role, style: TextStyle(fontWeight: FontWeight.w700, color: role == 'owner' ? Theme.of(context).colorScheme.primary : Colors.orange.shade700)),
                                    ),
                                    ActionChip(
                                      label: Text('Limit ₹${member['spending_limit'] ?? 0}'),
                                      onPressed: isOwner ? () => _editLimit(member) : null,
                                    ),
                                  ]),
                                ]),
                              ),
                              if (canRemove)
                                IconButton(
                                  onPressed: () => _removeMember((member['id'] ?? '').toString()),
                                  icon: const Icon(Icons.delete_outline_rounded),
                                ),
                            ]),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}
