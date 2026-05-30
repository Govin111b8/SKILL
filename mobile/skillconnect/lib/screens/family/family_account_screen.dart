import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

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
      final data =
          Map<String, dynamic>.from((res['data'] as Map?) ?? const {});
      final members = (data['members'] as List? ?? const []);
      _household = data;
      _members = members
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
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
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text('Add')),
        ],
      ),
    );
    if (phone == null || phone.isEmpty) return;
    try {
      await ApiService.post(
          '/households/me/members', {'phone': phone}, auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member invite sent.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not add member: $e')));
    }
  }

  Future<void> _removeMember(String id) async {
    try {
      await ApiService.delete('/households/me/members/$id', auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Member removed.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove member: $e')));
    }
  }

  Future<void> _editLimit(Map<String, dynamic> member) async {
    final controller =
        TextEditingController(text: (member['spending_limit'] ?? 0).toString());
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update spending limit'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(prefixText: '₹', labelText: 'Monthly limit'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (value == null || value.isEmpty) return;
    try {
      await ApiService.post(
          '/households/me/members',
          {
            'member_id': member['id'],
            'spending_limit': num.tryParse(value) ?? 0,
          },
          auth: true);
      if (!mounted) return;
      setState(() => member['spending_limit'] = num.tryParse(value) ?? 0);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spending limit updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update limit: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final ownerId = (_household?['owner_id'] ?? '').toString();
    final isOwner = auth.user?['id']?.toString() == ownerId ||
        _members.any((m) =>
            m['role'] == 'owner' &&
            m['user_id']?.toString() == auth.user?['id']?.toString());
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMember,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Member',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _load,
            child: _loading
                ? const PremiumLoadingList(itemCount: 4, itemHeight: 80)
                : _error != null
                    ? ListView(children: [
                        PremiumEmptyState(
                          icon: Icons.home_outlined,
                          title: 'Could not load household',
                          subtitle: _error!,
                          actionLabel: 'Retry',
                          onAction: _load,
                          gradient: const [AppColors.error, Color(0xFFFF6B6B)],
                        ),
                      ])
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            100),
                        children: [
                          _buildPageHeader(context),
                          const SizedBox(height: AppSpacing.lg),
                          _buildHouseholdCard(context),
                          const SizedBox(height: AppSpacing.xl),
                          const PremiumSectionTitle(
                            title: 'Family Members',
                            subtitle: 'Manage household members and budgets',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (_members.isEmpty)
                            const PremiumEmptyState(
                              icon: Icons.group_outlined,
                              title: 'No family members added',
                              subtitle:
                                  'Invite household members to manage shared bookings and budgets.',
                            )
                          else
                            ..._members.map((member) {
                              final role =
                                  (member['role'] ?? 'member').toString();
                              final canRemove = isOwner && role != 'owner';
                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: _MemberCard(
                                  member: member,
                                  role: role,
                                  canRemove: canRemove,
                                  isOwner: isOwner,
                                  onRemove: () => _removeMember(
                                      (member['id'] ?? '').toString()),
                                  onEditLimit: () => _editLimit(member),
                                ),
                              );
                            }),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    return Row(children: [
      IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        style: IconButton.styleFrom(
            backgroundColor: Colors.white.withAlpha(20)),
      ),
      const SizedBox(width: AppSpacing.md),
      const Expanded(
        child: Text(
          'Family Account',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5),
        ),
      ),
    ]);
  }

  Widget _buildHouseholdCard(BuildContext context) {
    return PremiumGlassCard(
      gradient: const [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
      child: Row(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient:
                const LinearGradient(colors: AppColors.primaryGradient),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.md(AppColors.primary),
          ),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _household?['name']?.toString() ?? 'My Household',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(children: [
                _HouseholdPill(
                  label: _household?['tier']?.toString() ?? 'Standard',
                  icon: Icons.workspace_premium_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                _HouseholdPill(
                  label: '${_members.length} members',
                  icon: Icons.group_rounded,
                  color: AppColors.primary,
                ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

class _HouseholdPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _HouseholdPill(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final String role;
  final bool canRemove;
  final bool isOwner;
  final VoidCallback onRemove;
  final VoidCallback onEditLimit;
  const _MemberCard({
    required this.member,
    required this.role,
    required this.canRemove,
    required this.isOwner,
    required this.onRemove,
    required this.onEditLimit,
  });

  @override
  Widget build(BuildContext context) {
    final name = member['name']?.toString() ?? 'Member';
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final roleColor =
        role == 'owner' ? AppColors.primary : AppColors.warning;

    return PremiumGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              roleColor.withAlpha(40),
              roleColor.withAlpha(20),
            ]),
            shape: BoxShape.circle,
            border: Border.all(color: roleColor.withAlpha(80), width: 2),
          ),
          child: Center(
            child: Text(initial,
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: roleColor)),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: roleColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(role,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: roleColor,
                        fontSize: 11)),
              ),
              GestureDetector(
                onTap: isOwner ? onEditLimit : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.success.withAlpha(50)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.currency_rupee_rounded,
                        size: 10, color: AppColors.success),
                    Text('${member['spending_limit'] ?? 0}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                            fontSize: 11)),
                    if (isOwner) ...[
                      const SizedBox(width: 2),
                      const Icon(Icons.edit_rounded,
                          size: 9, color: AppColors.success),
                    ],
                  ]),
                ),
              ),
            ]),
          ]),
        ),
        if (canRemove)
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.person_remove_rounded),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.error,
              backgroundColor: AppColors.error.withAlpha(12),
            ),
          ),
      ]),
    );
  }
}
