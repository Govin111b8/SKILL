import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';
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
    setState(() {
      _loading = true;
      _error = null;
    });
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
      await ApiService.put(
          '/contacts/$contactId/status', {'status': status}, auth: true);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Contact ${status == 'accepted' ? 'accepted' : 'declined'}'),
          backgroundColor:
              status == 'accepted' ? Colors.green : Colors.orange,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.read<AuthService>().isProfessional;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            _buildHeader(context),
            Expanded(
              child: _loading
                  ? const PremiumLoadingList(itemCount: 5, itemHeight: 120)
                  : _error != null
                      ? _buildError()
                      : _contacts.isEmpty
                          ? _buildEmpty(isPro)
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    0,
                                    AppSpacing.lg,
                                    AppSpacing.xxxl),
                                itemCount: _contacts.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.md),
                                itemBuilder: (_, i) {
                                  final c = _contacts[i];
                                  return _ContactTile(
                                    contact: c,
                                    isPro: isPro,
                                    onAccept: () =>
                                        _updateStatus(c.id, 'accepted'),
                                    onDecline: () =>
                                        _updateStatus(c.id, 'declined'),
                                    onReview: () async {
                                      final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => WriteReviewScreen(
                                              professionalId: c.professionalId,
                                              contactId: c.id,
                                              professionalName:
                                                  c.professionalName ??
                                                      'Professional',
                                            ),
                                          ));
                                      if (result == true) _load();
                                    },
                                  );
                                },
                              ),
                            ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      child: Row(children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          style: IconButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(20)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Contacts',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5),
              ),
              Text(
                '${_contacts.length} contact${_contacts.length == 1 ? '' : 's'}',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.primaryGradient),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.sm(AppColors.primary),
          ),
          child: const Icon(Icons.contacts_rounded,
              color: Colors.white, size: 20),
        ),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: PremiumEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Could not load contacts',
        subtitle: _error ?? 'Something went wrong.',
        actionLabel: 'Retry',
        onAction: _load,
        gradient: const [AppColors.error, Color(0xFFFF6B6B)],
      ),
    );
  }

  Widget _buildEmpty(bool isPro) {
    return Center(
      child: PremiumEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No contacts yet',
        subtitle: isPro
            ? 'Customer contact requests will appear here.'
            : 'Search for professionals to get started.',
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final bool isPro;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onReview;

  const _ContactTile({
    required this.contact,
    required this.isPro,
    required this.onAccept,
    required this.onDecline,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final name = isPro
        ? (contact.customerName ?? 'Customer')
        : (contact.professionalName ?? 'Professional');
    final statusColor = _statusColor(contact.status);
    final typeIcon = _typeIcon(contact.contactType);

    return PremiumGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.primary.withAlpha(30),
                AppColors.accent.withAlpha(20),
              ]),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primary.withAlpha(60), width: 2),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: AppSpacing.xs),
              Row(children: [
                Icon(typeIcon, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(_formatType(contact.contactType),
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(width: AppSpacing.sm),
                Text(_timeAgo(contact.createdAt),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400)),
              ]),
            ]),
          ),
          PremiumStatusPill(
            label: contact.status.toUpperCase(),
            color: statusColor,
          ),
        ]),
        if (contact.message != null && contact.message!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(8),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                  color: AppColors.primary.withAlpha(25)),
            ),
            child: Text(
              contact.message!,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4),
            ),
          ),
        ],
        if (isPro && contact.status == 'pending') ...[
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDecline,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Decline',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: AppColors.successGradient),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: AppShadows.sm(AppColors.success),
                ),
                child: TextButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white),
                  label: const Text('Accept',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ]),
        ],
        if (!isPro && contact.status == 'accepted') ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReview,
              icon: const Icon(Icons.rate_review_rounded, size: 16),
              label: const Text('Write Review',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'accepted':
        return AppColors.success;
      case 'declined':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'call':
        return Icons.phone;
      case 'quote_request':
        return Icons.request_quote;
      default:
        return Icons.message;
    }
  }

  String _formatType(String t) {
    switch (t) {
      case 'call':
        return 'Phone Call';
      case 'quote_request':
        return 'Quote Request';
      default:
        return 'Message';
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
