import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

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

  Future<void> _showClaimDialog(Map<String, dynamic> warranty) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Claim Warranty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Service: ${warranty['service_name'] ?? 'N/A'}'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for claim',
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit Claim')),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      try {
        await ApiService.post(
          '/warranties/${warranty['id']}/claim',
          {'reason': reasonController.text.trim()},
          auth: true,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Warranty claim submitted successfully')),
          );
          _load(); // Refresh list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit claim: $e')),
          );
        }
      }
    }
    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _warranties.where((w) => !_isExpired(w)).length;
    final expiringSoon = _warranties.where((w) {
      final days = _daysLeft(w);
      return days >= 0 && days <= 30;
    }).length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const PremiumAppBar(title: 'Warranty Tracker'),
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: _loading
              ? const PremiumLoadingList(itemCount: 4, itemHeight: 168)
              : _warranties.isEmpty
                  ? const PremiumEmptyState(
                      icon: Icons.verified_user_outlined,
                      title: 'No active warranties',
                      subtitle: 'Warranties can be added after service completion for extended protection.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.xxxl),
                        children: [
                          PremiumHeroHeader(
                            title: '$activeCount active coverages',
                            subtitle: expiringSoon > 0
                                ? '$expiringSoon warranties are expiring soon. Claim support before they lapse.'
                                : 'Track every protection plan and raise claims with confidence.',
                            icon: Icons.shield_rounded,
                            gradient: expiringSoon > 0 ? AppColors.warmGradient : AppColors.successGradient,
                            chips: [
                              PremiumStatChip(
                                label: '$activeCount active',
                                icon: Icons.verified_rounded,
                                color: Colors.white,
                              ),
                              PremiumStatChip(
                                label: '$expiringSoon expiring soon',
                                icon: Icons.schedule_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ),
                          const PremiumSectionTitle(
                            title: 'Your protection plans',
                            subtitle: 'Premium coverage summary with live expiry timelines.',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: Column(
                              children: _warranties
                                  .map((w) => Padding(
                                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                        child: _buildWarrantyCard(context, w),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
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
    final color = _expiryColor(daysLeft, isExpired);
    final progress = _expiryProgress(daysLeft, isExpired);

    return PremiumGlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      gradient: [
        Colors.white.withAlpha(225),
        color.withAlpha(10),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  isExpired ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      warranty['service_name']?.toString() ?? 'Service Warranty',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (warranty['professional_name'] != null)
                      Text(
                        'By ${warranty['professional_name']}',
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
              PremiumStatusPill(
                label: isExpired ? 'Expired' : '$daysLeft days left',
                color: color,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (expiresAt != null)
            Text(
              'Expires on ${_formatDate(expiresAt)}',
              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Coverage timeline',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    isExpired ? 'Coverage ended' : _timelineLabel(daysLeft),
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
          if (!isExpired && warranty['claimable'] == true) ...[
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: PremiumGradientButton(
                label: 'Claim Warranty',
                icon: Icons.support_agent_rounded,
                colors: _claimGradient(daysLeft),
                onPressed: () { _showClaimDialog(warranty); },
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isExpired(Map<String, dynamic> warranty) {
    final expiresAt = DateTime.tryParse(warranty['expires_at']?.toString() ?? '');
    return expiresAt != null && expiresAt.isBefore(DateTime.now());
  }

  int _daysLeft(Map<String, dynamic> warranty) {
    final expiresAt = DateTime.tryParse(warranty['expires_at']?.toString() ?? '');
    return expiresAt != null ? expiresAt.difference(DateTime.now()).inDays : 0;
  }

  Color _expiryColor(int daysLeft, bool isExpired) {
    if (isExpired) return AppColors.error;
    if (daysLeft < 7) return AppColors.error;
    if (daysLeft <= 30) return AppColors.warning;
    return AppColors.success;
  }

  double _expiryProgress(int daysLeft, bool isExpired) {
    if (isExpired) return 0;
    final normalized = (daysLeft / 90).clamp(0, 1);
    return normalized.toDouble();
  }

  List<Color> _claimGradient(int daysLeft) {
    if (daysLeft < 7) return AppColors.warmGradient;
    if (daysLeft <= 30) return const [AppColors.warning, AppColors.accent];
    return AppColors.primaryGradient;
  }

  String _timelineLabel(int daysLeft) {
    if (daysLeft < 7) return 'Urgent attention';
    if (daysLeft <= 30) return 'Expiring soon';
    return 'Protected';
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
