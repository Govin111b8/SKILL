import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/kyc_catalog.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/trust_badge.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _myDocs = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.get('/kyc/me', auth: true);
      _myDocs = r['data'] ?? [];
      _summary = (r['user'] as Map<String, dynamic>?) ?? {};
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _add(KycDocType doc) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmitSheet(doc: doc),
    );
    if (result == null) return;
    try {
      final r = await ApiService.post('/kyc/submit', result, auth: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: r['success'] == false ? Colors.red.shade600 : Colors.green.shade600,
          content: Text(r['message'] ?? 'Submitted'),
        ));
      }
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')));
    }
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove document?'),
        content: const Text('You will need to re-verify if you remove this document.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.delete('/kyc/$id', auth: true);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Map<String, dynamic>? _docFor(String code) {
    try { return _myDocs.firstWhere((d) => d['doc_type'] == code) as Map<String, dynamic>; } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final role = (auth.user?['role'] as String?) ?? 'customer';
    final available = kycDocsForRole(role);
    final byCategory = <String, List<KycDocType>>{};
    for (final d in available) { (byCategory[d.category] ??= []).add(d); }

    final lvl = (_summary['kyc_level'] ?? 0) as int;
    final score = ((_summary['trust_score'] ?? 0) as num).toInt();
    final verifiedCount = _myDocs.where((d) => d['status'] == 'verified').length;
    final pendingCount = _myDocs.where((d) => d['status'] == 'pending').length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const PremiumAppBar(title: 'KYC & Verification'),
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: _loading
              ? const PremiumLoadingList(itemCount: 5, itemHeight: 132)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.xxxl),
                    children: [
                      PremiumHeroHeader(
                        title: _heroTitle(lvl, verifiedCount),
                        subtitle: _nextStepHint(lvl, score),
                        icon: lvl >= 2 ? Icons.verified_user_rounded : Icons.shield_outlined,
                        gradient: _heroGradient(lvl),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TrustBadge(kycLevel: lvl, trustScore: score),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              '$score/100',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Trust score',
                              style: TextStyle(
                                color: Colors.white.withAlpha(220),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        chips: [
                          PremiumStatChip(
                            label: 'Level $lvl',
                            icon: Icons.workspace_premium_rounded,
                            color: Colors.white,
                          ),
                          PremiumStatChip(
                            label: '$verifiedCount verified',
                            icon: Icons.verified_rounded,
                            color: Colors.white,
                          ),
                          PremiumStatChip(
                            label: pendingCount > 0 ? '$pendingCount pending' : 'Secure vault',
                            icon: pendingCount > 0 ? Icons.schedule_rounded : Icons.lock_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: PremiumGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.alt_route_rounded, color: AppColors.primary),
                                  SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Verification journey',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _buildJourneyStep(
                                index: 1,
                                title: 'Phone verified',
                                subtitle: 'Start building trust with a verified mobile number.',
                                complete: lvl >= 1,
                                active: lvl == 0,
                                color: AppColors.info,
                              ),
                              _buildJourneyConnector(lvl >= 1),
                              _buildJourneyStep(
                                index: 2,
                                title: 'Government ID',
                                subtitle: 'Aadhaar, PAN, or another identity document.',
                                complete: lvl >= 2,
                                active: lvl == 1,
                                color: AppColors.success,
                              ),
                              _buildJourneyConnector(lvl >= 2),
                              _buildJourneyStep(
                                index: 3,
                                title: 'Pro-grade trust',
                                subtitle: 'Add business or credential docs for maximum visibility.',
                                complete: lvl >= 3,
                                active: lvl == 2,
                                color: AppColors.accent,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
                          child: PremiumGlassCard(
                            gradient: [
                              AppColors.errorLight.withAlpha(225),
                              Colors.white.withAlpha(205),
                            ],
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withAlpha(18),
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                  ),
                                  child: const Icon(Icons.error_outline_rounded, color: AppColors.error),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      for (final cat in byCategory.keys) ...[
                        PremiumSectionTitle(
                          title: cat,
                          subtitle: 'Tap a document to add or manage verification.',
                          trailing: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _catColor(cat).withAlpha(18),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Icon(_catIcon(cat), color: _catColor(cat)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Column(
                            children: [
                              for (final doc in byCategory[cat]!) ...[
                                _docTile(doc),
                                const SizedBox(height: AppSpacing.md),
                              ],
                            ],
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
                        child: PremiumGlassCard(
                          gradient: [
                            AppColors.warningLight.withAlpha(235),
                            Colors.white.withAlpha(210),
                          ],
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: AppColors.warmGradient),
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                ),
                                child: const Icon(Icons.shield_moon_outlined, color: Colors.white),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Privacy & Security',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Document numbers are masked everywhere. Originals are encrypted at rest. We never share your KYC data with third parties — only verification status is shown publicly.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

  Widget _docTile(KycDocType doc) {
    final existing = _docFor(doc.code);
    final status = existing?['status'] as String?;
    final masked = existing?['doc_number'] as String?;
    final color = _statusColor(status);
    final icon = _statusIcon(status);
    final statusLabel = _statusLabel(status);

    return PremiumGlassCard(
      onTap: status == null ? () => _add(doc) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: status == null
                  ? [AppColors.primary.withAlpha(22), AppColors.accent.withAlpha(18)]
                  : [color.withAlpha(18), color.withAlpha(8)],
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Center(
              child: Text(doc.emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        doc.label,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (status != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withAlpha(14),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: color.withAlpha(70)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 14, color: color),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  masked ?? doc.hint,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: status == null ? AppColors.primary.withAlpha(10) : color.withAlpha(10),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Text(
                          status == null
                              ? 'Ready to add'
                              : status == 'verified'
                                  ? 'Securely verified and visible'
                                  : status == 'pending'
                                      ? 'Under review by our verification team'
                                      : 'Needs attention before approval',
                          style: TextStyle(
                            color: status == null ? AppColors.primary : color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (status == null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.primaryGradient),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: AppShadows.sm(AppColors.primary),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, color: Colors.white, size: 16),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              'Add',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                        onPressed: () => _delete(existing!['id'] as String),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String s) {
    final (c, lbl, ic) = switch (s) {
      'verified' => (const Color(0xFF10B981), 'Verified', Icons.check_circle_rounded),
      'pending'  => (const Color(0xFFF59E0B), 'Pending',  Icons.access_time_rounded),
      'rejected' => (const Color(0xFFEF4444), 'Rejected', Icons.error_rounded),
      _          => (const Color(0xFF94A3B8), s,          Icons.help_outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withAlpha(30), borderRadius: BorderRadius.circular(100)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ic, size: 12, color: c),
        const SizedBox(width: 3),
        Text(lbl, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  String _levelLabel(int l) => switch (l) { 0 => 'Get verified to unlock more', 1 => 'Phone verified', 2 => 'Government ID verified', _ => 'Pro-grade trust' };
  String _nextStepHint(int l, int s) {
    if (l >= 3) return 'You have full Pro-grade verification.';
    if (l >= 2) return 'Add a credential or business doc to reach Level 3.';
    if (l >= 1) return 'Add a government ID (Aadhaar, PAN) to reach Level 2.';
    return 'Verify your phone number to reach Level 1.';
  }

  IconData _catIcon(String cat) => switch (cat) {
    'Identity' => Icons.fingerprint_rounded,
    'Employment' => Icons.work_outline_rounded,
    'Business' => Icons.store_mall_directory_rounded,
    'Credential' => Icons.workspace_premium_rounded,
    _ => Icons.folder_outlined,
  };

  String _heroTitle(int level, int verifiedCount) {
    if (level >= 3) return 'Verified like a pro';
    if (verifiedCount > 0) return 'Almost fully verified';
    return 'Start your verification';
  }

  List<Color> _heroGradient(int level) {
    if (level >= 3) return AppColors.successGradient;
    if (level >= 2) return const [AppColors.primary, AppColors.info, AppColors.accent];
    return AppColors.heroGradient;
  }

  Widget _buildJourneyStep({
    required int index,
    required String title,
    required String subtitle,
    required bool complete,
    required bool active,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: AppDurations.normal,
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: complete || active
                ? LinearGradient(colors: [color, color.withAlpha(190)])
                : null,
            color: complete || active ? null : Colors.white,
            border: Border.all(
              color: complete || active ? Colors.transparent : AppColors.borderLight,
            ),
            boxShadow: complete || active ? AppShadows.sm(color) : null,
          ),
          child: Icon(
            complete ? Icons.check_rounded : Icons.circle_outlined,
            color: complete || active ? Colors.white : AppColors.borderDark,
            size: 18,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. $title',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyConnector(bool complete) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: AppSpacing.xs, bottom: AppSpacing.xs),
      child: Container(
        width: 2,
        height: 20,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: complete
                ? [AppColors.success.withAlpha(180), AppColors.primary.withAlpha(120)]
                : [AppColors.borderLight, AppColors.borderLight],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String? status) => switch (status) {
    'verified' => AppColors.success,
    'pending' => AppColors.warning,
    'rejected' => AppColors.error,
    _ => AppColors.primary,
  };

  IconData _statusIcon(String? status) => switch (status) {
    'verified' => Icons.shield_rounded,
    'pending' => Icons.schedule_rounded,
    'rejected' => Icons.cancel_rounded,
    _ => Icons.add_circle_outline_rounded,
  };

  String _statusLabel(String? status) => switch (status) {
    'verified' => 'Verified',
    'pending' => 'Pending',
    'rejected' => 'Rejected',
    _ => 'Add document',
  };

  Color _catColor(String cat) => switch (cat) {
    'Identity' => AppColors.primary,
    'Employment' => AppColors.info,
    'Business' => AppColors.warning,
    'Credential' => AppColors.accent,
    _ => AppColors.primary,
  };
}

class _SubmitSheet extends StatefulWidget {
  final KycDocType doc;
  const _SubmitSheet({required this.doc});

  @override
  State<_SubmitSheet> createState() => _SubmitSheetState();
}

class _SubmitSheetState extends State<_SubmitSheet> {
  final _form = GlobalKey<FormState>();
  final _num = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() { _num.dispose(); _name.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
        child: PremiumBackground(
          child: Container(
            margin: const EdgeInsets.only(top: AppSpacing.huge),
            decoration: const BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: PremiumGlassCard(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.borderLight,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary.withAlpha(18), AppColors.accent.withAlpha(12)],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                ),
                                child: Center(
                                  child: Text(widget.doc.emoji, style: const TextStyle(fontSize: 28)),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.doc.label,
                                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      widget.doc.hint,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        TextFormField(
                          controller: _num,
                          decoration: InputDecoration(
                            labelText: 'Document number',
                            hintText: widget.doc.exampleFormat ?? 'Enter number',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            filled: true,
                            fillColor: Colors.white.withAlpha(150),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          autofocus: true,
                          validator: (v) => widget.doc.clientValidate(v ?? ''),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _name,
                          decoration: InputDecoration(
                            labelText: 'Name as on document (optional)',
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            filled: true,
                            fillColor: Colors.white.withAlpha(150),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.infoLight.withAlpha(210),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.info.withAlpha(50)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lock_outline_rounded, color: AppColors.info, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Format will be re-validated server-side. Document numbers are masked on display and stored hashed.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade900,
                                    height: 1.45,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: PremiumGradientButton(
                            label: 'Submit for verification',
                            icon: Icons.verified_rounded,
                            onPressed: () {
                              if (!_form.currentState!.validate()) return;
                              Navigator.pop(context, {
                                'doc_type': widget.doc.code,
                                'doc_number': _num.text.trim(),
                                if (_name.text.trim().isNotEmpty) 'holder_name': _name.text.trim(),
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
