import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class WriteReviewScreen extends StatefulWidget {
  final String professionalId;
  final String contactId;
  final String professionalName;

  const WriteReviewScreen({
    super.key,
    required this.professionalId,
    required this.contactId,
    required this.professionalName,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  double _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a rating'), backgroundColor: Colors.orange));
      return;
    }
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write a comment'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService.post('/reviews', {
        'professional_id': widget.professionalId,
        'contact_id': widget.contactId,
        'rating': _rating.toInt(),
        'comment': _commentCtrl.text.trim(),
      }, auth: true);
      setState(() => _submitted = true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_submitted) {
      return PremiumScrollScaffold(
        child: Column(
          children: [
            const PremiumAppBar(title: 'Review Submitted'),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: PremiumGlassCard(
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: AppShadows.lg(AppColors.success),
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 48),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const Text(
                          'Thank You!',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Your review for ${widget.professionalName} has been submitted.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 16, height: 1.6),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        SizedBox(
                          width: double.infinity,
                          child: PremiumGradientButton(
                            label: 'Done',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () => Navigator.pop(context, true),
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
          const PremiumAppBar(title: 'Write a Review'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PremiumGlassCard(
                    gradient: [Colors.white.withAlpha(225), Colors.white.withAlpha(175)],
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: AppColors.primaryGradient),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.professionalName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reviewing',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                widget.professionalName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PremiumSectionTitle(
                    title: 'Your Rating',
                    subtitle: 'Rate your overall experience',
                  ),
                  PremiumGlassCard(
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      children: [
                        Center(
                          child: RatingBar.builder(
                            initialRating: 0,
                            minRating: 1,
                            itemCount: 5,
                            itemSize: 44,
                            glow: false,
                            unratedColor: Colors.grey.shade300,
                            itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Colors.amber),
                            onRatingUpdate: (rating) => setState(() => _rating = rating),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(colors: AppColors.primaryGradient).createShader(bounds),
                              child: Text(
                                _rating == 0 ? 'Tap to rate' : _ratingLabel(_rating.toInt()),
                                style: TextStyle(fontSize: 16, color: _rating == 0 ? Colors.grey : cs.primary, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PremiumSectionTitle(
                    title: 'Your Review',
                    subtitle: 'Share what stood out about the service',
                  ),
                  PremiumGlassCard(
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: TextField(
                      controller: _commentCtrl,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Share your experience with ${widget.professionalName}...',
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
                            gradient: [AppColors.primary.withAlpha(230), AppColors.accent.withAlpha(220)],
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                SizedBox(width: AppSpacing.md),
                                Text('Submitting...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          )
                        : PremiumGradientButton(
                            label: 'Submit Review',
                            icon: Icons.send_rounded,
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

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent';
      default: return '';
    }
  }
}
