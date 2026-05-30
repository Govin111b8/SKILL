import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class ReportScreen extends StatefulWidget {
  final String reportedUserId;
  final String reportedUserName;

  const ReportScreen({super.key, required this.reportedUserId, required this.reportedUserName});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? _selectedType;
  final _descCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  final _complaintTypes = [
    ('fraud', 'Fraud / Scam', Icons.warning_amber),
    ('harassment', 'Harassment', Icons.report),
    ('spam', 'Spam / Fake Profile', Icons.block),
    ('poor_service', 'Poor Service', Icons.thumb_down),
    ('inappropriate', 'Inappropriate Content', Icons.flag),
    ('other', 'Other', Icons.more_horiz),
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a complaint type'), backgroundColor: Colors.orange));
      return;
    }
    if (_descCtrl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Description must be at least 10 characters'), backgroundColor: Colors.orange));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
        titlePadding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
        contentPadding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
        actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.error.withAlpha(230), const Color(0xFFDC2626)]),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text(
                'Submit Report?',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to report this user? False reports may result in action against your account.',
          style: TextStyle(color: Colors.grey.shade700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          PremiumGradientButton(
            label: 'Submit Report',
            icon: Icons.send_rounded,
            colors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
            onPressed: () => Navigator.pop(ctx, true),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      await ApiService.post('/complaints', {
        'reported_user_id': widget.reportedUserId,
        'complaint_type': _selectedType!,
        'description': _descCtrl.text.trim(),
      }, auth: true);
      setState(() => _submitted = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return PremiumScrollScaffold(
        child: Column(
          children: [
            const PremiumAppBar(
              title: 'Report Submitted',
              gradient: [Color(0xFF111827), Color(0xFF0F172A)],
              dark: true,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: PremiumGlassCard(
                    gradient: [const Color(0xFF0F172A).withAlpha(245), const Color(0xFF1E293B).withAlpha(230)],
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: AppShadows.lg(AppColors.success),
                          ),
                          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 46),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const Text(
                          'Report Received',
                          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'We will review your complaint about ${widget.reportedUserName} and take appropriate action.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 15, height: 1.6),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        SizedBox(
                          width: double.infinity,
                          child: PremiumGradientButton(
                            label: 'Done',
                            icon: Icons.check_circle_outline_rounded,
                            colors: const [Color(0xFF10B981), Color(0xFF059669)],
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PremiumScrollScaffold(
      child: Column(
        children: [
          const PremiumAppBar(title: 'Report User'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PremiumGlassCard(
                    gradient: [const Color(0xFFEF4444).withAlpha(235), const Color(0xFFDC2626).withAlpha(220)],
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(22),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: Colors.white.withAlpha(40)),
                          ),
                          child: const Icon(Icons.report_gmailerrorred_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reporting: ${widget.reportedUserName}',
                                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Choose the reason carefully and share enough detail for a proper review.',
                                style: TextStyle(color: Colors.white.withAlpha(220), height: 1.45),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PremiumSectionTitle(
                    title: 'Complaint Type',
                    subtitle: 'Select the reason that best matches this report',
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _complaintTypes.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.12,
                    ),
                    itemBuilder: (context, index) {
                      final type = _complaintTypes[index];
                      final selected = _selectedType == type.$1;
                      return PremiumGlassCard(
                        onTap: () => setState(() => _selectedType = type.$1),
                        gradient: selected
                            ? const [Color(0xFFEF4444), Color(0xFFDC2626)]
                            : [Colors.white.withAlpha(220), Colors.white.withAlpha(165)],
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: selected ? Colors.white.withAlpha(22) : AppColors.error.withAlpha(12),
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                              ),
                              child: Icon(
                                type.$3,
                                color: selected ? Colors.white : AppColors.error,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              type.$2,
                              style: TextStyle(
                                color: selected ? Colors.white : AppColors.surfaceDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              selected ? 'Selected complaint type' : 'Tap to choose',
                              style: TextStyle(
                                color: selected ? Colors.white.withAlpha(200) : Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const PremiumSectionTitle(
                    title: 'Description',
                    subtitle: 'Include details that can help our team investigate',
                  ),
                  PremiumGlassCard(
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: TextField(
                      controller: _descCtrl,
                      maxLines: 6,
                      maxLength: 1000,
                      decoration: InputDecoration(
                        hintText: 'Please provide details about your complaint...',
                        border: InputBorder.none,
                        counterStyle: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    child: _submitting
                        ? PremiumGlassCard(
                            gradient: [const Color(0xFFEF4444).withAlpha(220), const Color(0xFFDC2626).withAlpha(200)],
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                SizedBox(width: AppSpacing.md),
                                Text(
                                  'Submitting...',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          )
                        : PremiumGradientButton(
                            label: 'Submit Report',
                            icon: Icons.send_rounded,
                            colors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                            onPressed: _submit,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
