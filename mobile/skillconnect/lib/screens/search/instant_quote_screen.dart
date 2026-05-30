import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import '../../services/upload_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/premium_ui.dart';

class InstantQuoteScreen extends StatefulWidget {
  const InstantQuoteScreen({super.key});

  @override
  State<InstantQuoteScreen> createState() => _InstantQuoteScreenState();
}

class _InstantQuoteScreenState extends State<InstantQuoteScreen> {
  File? _imageFile;
  String? _selectedCategory;
  final _descriptionCtl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  final _categories = [
    'AC / Cooling',
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'Cleaning',
    'Appliance Repair',
    'Other',
  ];

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 70,
    );
    if (result != null) {
      setState(() => _imageFile = File(result.path));
    }
  }

  Future<void> _submitQuoteRequest() async {
    if (_imageFile == null || _selectedCategory == null) return;

    setState(() => _submitting = true);
    try {
      final imageUrl =
          await UploadService.uploadFile(_imageFile!.path, 'quote_images');

      await ApiService.post('/quotes/request', {
        'image_url': imageUrl,
        'category': _selectedCategory,
        'description': _descriptionCtl.text.trim(),
      }, auth: true);

      setState(() => _submitted = true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit. Will retry when online.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _descriptionCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccess(context);

    final canSubmit = _imageFile != null && _selectedCategory != null && !_submitting;

    return PremiumScrollScaffold(
      safeTop: false,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.huge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  PremiumGlassCard(
                    onTap: () => Navigator.pop(context),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.surfaceDark,
                    ),
                  ),
                  const Spacer(),
                  const PremiumStatusPill(
                    label: '3 simple steps',
                    color: AppColors.primary,
                  ),
                ],
              ),
              PremiumHeroHeader(
                title: 'Get Instant Quote',
                subtitle:
                    'Snap the problem, tag the service type, and let nearby SkillConnect pros send quick quotes.',
                icon: Icons.camera_alt_rounded,
                chips: const [
                  PremiumStatChip(
                    label: 'Fast responses',
                    color: Colors.white,
                    icon: Icons.flash_on_rounded,
                  ),
                  PremiumStatChip(
                    label: 'Nearby pros',
                    color: Colors.white,
                    icon: Icons.location_on_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const _QuoteStepIndicator(),
              const SizedBox(height: AppSpacing.xl),
              PremiumSectionTitle(
                title: 'Step 1 • Add a photo',
                subtitle:
                    'A clear image helps professionals give more accurate quotes.',
              ),
              PremiumGlassCard(
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                child: Column(
                  children: [
                    if (_imageFile != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        child: Image.file(
                          _imageFile!,
                          height: 240,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: PremiumGlassCard(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                setState(() => _imageFile = null);
                              },
                              gradient: [
                                AppColors.warning.withAlpha(20),
                                Colors.white.withAlpha(190),
                              ],
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.lg,
                              ),
                              child: const Center(
                                child: Text(
                                  'Retake photo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.surfaceDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withAlpha(18),
                              AppColors.accent.withAlpha(16),
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(28),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: AppColors.primaryGradient,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: AppShadows.lg(AppColors.primary),
                              ),
                              child: const Icon(
                                Icons.photo_camera_back_rounded,
                                size: 42,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            const Text(
                              'Capture the issue beautifully',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Take a fresh photo or upload one from your gallery so nearby professionals can assess the problem instantly.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionCard(
                                    icon: Icons.camera_alt_rounded,
                                    label: 'Camera',
                                    onTap: () => _pickImage(ImageSource.camera),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _ActionCard(
                                    icon: Icons.photo_library_rounded,
                                    label: 'Gallery',
                                    onTap: () => _pickImage(ImageSource.gallery),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PremiumSectionTitle(
                title: 'Step 2 • Choose category',
                subtitle:
                    'Tag the issue so the right specialists respond faster.',
              ),
              PremiumGlassCard(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _categories
                      .map(
                        (cat) => _CategoryChip(
                          label: cat,
                          selected: _selectedCategory == cat,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _selectedCategory =
                                  _selectedCategory == cat ? null : cat;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PremiumSectionTitle(
                title: 'Step 3 • Add details',
                subtitle:
                    'Optional notes can help professionals price the job more accurately.',
              ),
              PremiumGlassCard(
                child: TextField(
                  controller: _descriptionCtl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'e.g. "AC not cooling, making noise"',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 56),
                      child: Icon(
                        Icons.edit_note_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (canSubmit)
                SizedBox(
                  width: double.infinity,
                  child: PremiumGradientButton(
                    label: _submitting
                        ? 'Sending...'
                        : 'Get Quotes from Nearby Pros',
                    icon: _submitting
                        ? Icons.hourglass_top_rounded
                        : Icons.send_rounded,
                    onPressed: _submitQuoteRequest,
                  ),
                )
              else
                Opacity(
                  opacity: 0.55,
                  child: PremiumGlassCard(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_submitting) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          _submitting
                              ? 'Sending...'
                              : 'Add a photo and category to continue',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return PremiumScrollScaffold(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: PremiumGlassCard(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.successGradient,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.xl(AppColors.success),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 54,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'Quote Request Sent! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Nearby professionals will send you quotes shortly. You\'ll get a notification when quotes arrive.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.55,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                PremiumGlassCard(
                  gradient: [
                    AppColors.success.withAlpha(22),
                    Colors.white.withAlpha(205),
                  ],
                  child: const Row(
                    children: [
                      Expanded(
                        child: PremiumMetricCard(
                          label: 'Status',
                          value: 'Sent',
                          icon: Icons.outbox_rounded,
                          color: AppColors.success,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: PremiumMetricCard(
                          label: 'Next step',
                          value: 'Await quotes',
                          icon: Icons.notifications_active_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
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
    );
  }
}

class _QuoteStepIndicator extends StatelessWidget {
  const _QuoteStepIndicator();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1', 'Photo'),
      ('2', 'Category'),
      ('3', 'Submit'),
    ];

    return PremiumGlassCard(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            );
          }
          final step = steps[index ~/ 2];
          return Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.md(AppColors.primary),
                ),
                child: Center(
                  child: Text(
                    step.$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                step.$2,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: AppColors.primaryGradient)
              : null,
          color: selected ? null : Colors.white.withAlpha(205),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.primary.withAlpha(42),
          ),
          boxShadow: selected
              ? AppShadows.md(AppColors.primary)
              : AppShadows.sm(AppColors.primary),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.surfaceDark,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      gradient: [AppColors.primary.withAlpha(16), Colors.white.withAlpha(210)],
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
