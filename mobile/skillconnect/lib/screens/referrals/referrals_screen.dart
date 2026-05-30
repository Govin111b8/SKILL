import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _earnings = [];
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
      final meRes = await ApiService.get('/referrals/me', auth: true);
      final earningsRes = await ApiService.get('/referrals/earnings', auth: true);
      _summary = Map<String, dynamic>.from((meRes['data'] as Map?) ?? const {});
      final data = earningsRes['data'];
      final items = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['earnings'] as List? ?? data['referrals'] as List? ?? const [])
              : const [];
      _earnings = items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral code copied.')));
  }

  void _shareCode(String code) {
    HapticFeedback.mediumImpact();
    final referralLink = 'https://skillconnect.app/ref/$code';
    Share.share('Join SkillConnect with my referral code $code and unlock rewards.\n$referralLink');
  }

  String _formatDate(dynamic raw) {
    final value = raw?.toString() ?? '';
    if (value.isEmpty) return 'Just now';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM yyyy').format(parsed.toLocal());
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'credited':
      case 'successful':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.accent;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'credited':
        return 'Successful';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary ?? const <String, dynamic>{};
    final code = (summary['code'] ?? summary['referral_code'] ?? 'SKILLPRO').toString();
    final referralLink = 'https://skillconnect.app/ref/$code';
    final totalReferrals = (summary['total_referrals'] ?? summary['referrals_count'] ?? _earnings.length).toString();
    final pending = ((summary['pending_earnings'] ?? 0) as num).toDouble();
    final credited = ((summary['credited_earnings'] ?? summary['total_credited'] ?? 0) as num).toDouble();

    return PremiumScrollScaffold(
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.success,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
          children: [
            PremiumHeroHeader(
              title: 'Refer & Earn',
              subtitle: 'Share and earn rewards',
              icon: Icons.card_giftcard_rounded,
              gradient: const [Color(0xFF059669), Color(0xFF10B981)],
              chips: [
                PremiumStatChip(
                  label: '$totalReferrals referrals',
                  color: Colors.white,
                  icon: Icons.group_rounded,
                ),
                PremiumStatChip(
                  label: _currency.format(credited),
                  color: Colors.white,
                  icon: Icons.currency_rupee_rounded,
                ),
              ],
              trailing: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(24),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: Colors.white.withAlpha(50)),
                ),
                child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 34),
              ),
            ),
            if (_loading) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: PremiumLoadingList(itemCount: 5, itemHeight: 120),
              ),
            ] else if (_error != null) ...[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: PremiumEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load referrals',
                  subtitle: _error!,
                  actionLabel: 'Try again',
                  onAction: _load,
                  gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: PremiumGlassCard(
                  gradient: const [Color(0xFF065F46), Color(0xFF047857)],
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Code',
                        style: TextStyle(
                          color: Colors.white.withAlpha(190),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFECFDF5), Color(0xFFA7F3D0)],
                        ).createShader(bounds),
                        child: Text(
                          code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.4,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Use this code or share your premium invite link.',
                        style: TextStyle(
                          color: Colors.white.withAlpha(190),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: PremiumGlassCard(
                              onTap: () => _copyCode(code),
                              gradient: [Colors.white.withAlpha(22), Colors.white.withAlpha(10)],
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.lg),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Copy',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: PremiumGradientButton(
                              label: 'Share',
                              icon: Icons.share_rounded,
                              colors: const [Color(0xFF34D399), Color(0xFF10B981)],
                              onPressed: () => _shareCode(code),
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: PremiumGlassCard(
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  child: Column(
                    children: [
                      const PremiumSectionTitle(
                        title: 'Scan to Join',
                        subtitle: 'Invite instantly with your referral QR',
                      ),
                      QrImageView(
                        data: referralLink,
                        size: 180,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.surfaceDark),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.surfaceDark),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        referralLink,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: _PremiumReferralStatCard(
                        label: 'Total Referrals',
                        value: totalReferrals,
                        icon: Icons.people_alt_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _PremiumReferralStatCard(
                        label: 'Successful',
                        value: _earnings.where((item) {
                          final status = (item['status'] ?? '').toString().toLowerCase();
                          return status == 'credited' || status == 'successful';
                        }).length.toString(),
                        icon: Icons.verified_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _PremiumReferralStatCard(
                        label: 'Earnings',
                        value: _currency.format(credited + pending),
                        icon: Icons.savings_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const PremiumSectionTitle(
                title: 'Referral History',
                subtitle: 'Track every successful share and reward',
              ),
              if (_earnings.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: PremiumEmptyState(
                    icon: Icons.group_add_rounded,
                    title: 'No referral activity yet',
                    subtitle: 'Share your code to start earning referral credits.',
                    actionLabel: 'Share code',
                    onAction: () => _shareCode(code),
                    gradient: const [Color(0xFF065F46), Color(0xFF10B981)],
                  ),
                )
              else
                ..._earnings.map((item) {
                  final status = (item['status'] ?? 'pending').toString();
                  final color = _statusColor(status);
                  final amount = ((item['amount'] ?? 0) as num).toDouble();
                  final name = item['name']?.toString() ?? item['user_name']?.toString() ?? 'Referred user';
                  final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                    child: PremiumGlassCard(
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  _formatDate(item['date'] ?? item['created_at']),
                                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                PremiumStatusPill(label: _statusLabel(status), color: color),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _currency.format(amount),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                status.toLowerCase() == 'pending' ? 'Pending reward' : 'Reward credited',
                                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}

class _PremiumReferralStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PremiumReferralStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
