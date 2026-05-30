import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

/// Simplified 3-step dispute flow for mobile.
/// Step 1: Select issue type
/// Step 2: Describe problem
/// Step 3: Submit (with optional photo)
class DisputeScreen extends StatefulWidget {
  final String bookingId;
  final String bookingTitle;

  const DisputeScreen({super.key, required this.bookingId, required this.bookingTitle});

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  int _step = 0;
  String? _issueType;
  final _descCtl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  final _issueTypes = [
    ('quality', 'Poor Quality Work', Icons.star_border),
    ('incomplete', 'Work Not Completed', Icons.pending_actions),
    ('overcharged', 'Overcharged', Icons.money_off),
    ('no_show', 'Professional Didn't Show', Icons.person_off),
    ('damage', 'Property Damaged', Icons.broken_image),
    ('other', 'Other Issue', Icons.help_outline),
  ];

  Future<void> _submit() async {
    if (_issueType == null || _descCtl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ApiService.post('/disputes', {
        'booking_id': widget.bookingId,
        'issue_type': _issueType,
        'description': _descCtl.text.trim(),
      }, auth: true);
      setState(() => _submitted = true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _descCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        body: PremiumBackground(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: PremiumGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.successGradient),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: AppShadows.lg(AppColors.success),
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 46),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Text(
                        'Dispute submitted',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Our team will review your dispute within 24 hours. You'll receive a notification with the resolution.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: PremiumGradientButton(
                          label: 'Done',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const PremiumAppBar(title: 'Raise a Dispute'),
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.huge, AppSpacing.lg, AppSpacing.lg),
                child: PremiumGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: AppColors.warmGradient),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: const Icon(Icons.gavel_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Booking support',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  widget.bookingTitle,
                                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: List.generate(3, (index) {
                          final isDone = index < _step;
                          final isActive = index == _step;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: index == 2 ? 0 : AppSpacing.sm),
                              child: AnimatedContainer(
                                duration: AppDurations.normal,
                                height: 10,
                                decoration: BoxDecoration(
                                  gradient: isDone || isActive
                                      ? const LinearGradient(colors: AppColors.primaryGradient)
                                      : null,
                                  color: isDone || isActive ? null : AppColors.borderLight,
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                  boxShadow: isActive ? AppShadows.sm(AppColors.primary) : null,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Step ${_step + 1} of 3 · ${_stepTitles[_step]}',
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _step == 0 ? _buildStep1() : _step == 1 ? _buildStep2() : _buildStep3(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PremiumSectionTitle(
          title: 'What happened?',
          subtitle: 'Choose the issue type that best matches your experience.',
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.08,
            ),
            itemCount: _issueTypes.length,
            itemBuilder: (context, index) {
              final (id, label, icon) = _issueTypes[index];
              final selected = _issueType == id;
              final color = _issueColor(index);
              return PremiumGlassCard(
                onTap: () => setState(() { _issueType = id; _step = 1; }),
                gradient: selected
                    ? [color.withAlpha(28), Colors.white.withAlpha(210)]
                    : [Colors.white.withAlpha(220), Colors.white.withAlpha(165)],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: color.withAlpha(selected ? 30 : 14),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Icon(icon, color: color),
                        ),
                        const Spacer(),
                        if (selected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      label,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.2),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tap to continue',
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PremiumSectionTitle(
          title: 'Describe the issue',
          subtitle: 'Share what happened so our support team can review it quickly.',
        ),
        PremiumGlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PremiumStatusPill(
                label: _issueTypes.firstWhere((e) => e.$1 == _issueType).$2,
                color: AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _descCtl,
                maxLines: 7,
                decoration: InputDecoration(
                  hintText: 'Tell us what happened...',
                  filled: true,
                  fillColor: Colors.white.withAlpha(150),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: _secondaryButton(
                label: 'Back',
                onTap: () => setState(() => _step = 0),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _primaryButton(
                label: 'Next',
                enabled: _descCtl.text.trim().isNotEmpty,
                onTap: () => setState(() => _step = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PremiumSectionTitle(
          title: 'Confirm & submit',
          subtitle: 'Review the details before we send this dispute to support.',
        ),
        PremiumGlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.warmGradient),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(
                      _issueTypes.firstWhere((e) => e.$1 == _issueType).$3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _issueTypes.firstWhere((e) => e.$1 == _issueType).$2,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Booking: ${widget.bookingTitle}',
                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Text(
                  _descCtl.text,
                  style: TextStyle(color: Colors.grey.shade800, height: 1.55, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: _secondaryButton(
                label: 'Back',
                onTap: () => setState(() => _step = 1),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _primaryButton(
                label: _submitting ? 'Submitting...' : 'Submit',
                enabled: !_submitting,
                onTap: () { _submit(); },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: PremiumGradientButton(
          label: label,
          icon: Icons.arrow_forward_rounded,
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _secondaryButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(200),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.surfaceDark),
        ),
      ),
    );
  }

  Color _issueColor(int index) {
    const colors = [
      AppColors.warning,
      AppColors.primary,
      AppColors.success,
      AppColors.error,
      AppColors.accent,
      AppColors.info,
    ];
    return colors[index % colors.length];
  }

  List<String> get _stepTitles => const [
    'Choose issue type',
    'Describe the problem',
    'Confirm and submit',
  ];
}
