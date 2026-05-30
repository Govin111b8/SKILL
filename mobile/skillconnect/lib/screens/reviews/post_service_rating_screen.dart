import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../services/api_service.dart';
import '../../widgets/app_components.dart';
import '../../widgets/premium_ui.dart';

/// Delightful multi-step post-service rating experience.
/// Steps: Star Rating → Category Tags → Optional Comment → Thank You
class PostServiceRatingScreen extends StatefulWidget {
  final String bookingId;
  final String professionalName;
  final String serviceName;

  const PostServiceRatingScreen({
    super.key,
    required this.bookingId,
    required this.professionalName,
    required this.serviceName,
  });

  @override
  State<PostServiceRatingScreen> createState() => _PostServiceRatingScreenState();
}

class _PostServiceRatingScreenState extends State<PostServiceRatingScreen> with TickerProviderStateMixin {
  int _step = 0; // 0=stars, 1=tags, 2=comment, 3=done
  int _rating = 0;
  final Set<String> _selectedTags = {};
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  static const _positiveTags = [
    'Punctual', 'Professional', 'Skilled', 'Friendly', 'Clean work',
    'Good value', 'Efficient', 'Communicative',
  ];

  static const _improveTags = [
    'Late arrival', 'Unprofessional', 'Overcharged', 'Incomplete work',
    'Poor communication', 'Messy', 'Rude',
  ];

  List<String> get _tags => _rating >= 4 ? _positiveTags : _improveTags;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ApiService.post('/reviews', {
        'booking_id': widget.bookingId,
        'rating': _rating,
        'comment': _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
        'tags': _selectedTags.toList(),
      }, auth: true);
      if (mounted) setState(() => _step = 3);
      HapticFeedback.heavyImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScrollScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.huge, AppSpacing.lg, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (_step == 3) {
                      Navigator.of(context).pop(true);
                    } else if (_step > 0) {
                      setState(() => _step -= 1);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: PremiumGlassCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.surfaceDark),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PremiumGlassCard(
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.professionalName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.serviceName,
                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final active = index <= _step;
                return AnimatedContainer(
                  duration: AppDurations.normal,
                  margin: EdgeInsets.only(right: index == 3 ? 0 : AppSpacing.sm),
                  width: active ? 28 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: active ? const LinearGradient(colors: AppColors.primaryGradient) : null,
                    color: active ? null : Colors.white.withAlpha(120),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppDurations.normal,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: _buildStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildStarStep();
      case 1:
        return _buildTagsStep();
      case 2:
        return _buildCommentStep();
      case 3:
        return _buildThankYouStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStarStep() {
    return SingleChildScrollView(
      key: const ValueKey('stars'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
      child: PremiumGlassCard(
        gradient: [Colors.white.withAlpha(230), Colors.white.withAlpha(175)],
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          children: [
            const _StepBadge(icon: Icons.auto_awesome_rounded, label: 'Step 1 · Rate experience'),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'How was your experience?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your feedback for ${widget.serviceName} helps ${widget.professionalName} stand out.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _rating = i + 1);
                  },
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: filled ? AppShadows.lg(AppColors.warning.withAlpha(140)) : null,
                      gradient: filled ? const LinearGradient(colors: AppColors.warmGradient) : null,
                    ),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 44,
                      color: filled ? Colors.white : Colors.grey.shade400,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedSwitcher(
              duration: AppDurations.fast,
              child: Text(
                _rating == 0
                    ? 'Tap a star to begin'
                    : _rating >= 4
                        ? 'Outstanding service ✨'
                        : _rating >= 3
                            ? 'Solid experience 👍'
                            : 'We’ll help make it better 💭',
                key: ValueKey(_rating),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _rating == 0 ? Colors.grey.shade600 : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            if (_rating > 0)
              SizedBox(
                width: double.infinity,
                child: PremiumGradientButton(
                  label: 'Next',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _step = 1);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsStep() {
    return SingleChildScrollView(
      key: const ValueKey('tags'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
      child: PremiumGlassCard(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepBadge(
              icon: _rating >= 4 ? Icons.favorite_rounded : Icons.tune_rounded,
              label: 'Step 2 · Select tags',
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              _rating >= 4 ? 'What stood out?' : 'What should improve?',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose every tag that matches your experience.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _tags.map((tag) {
                final selected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      if (selected) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: selected ? const LinearGradient(colors: AppColors.primaryGradient) : null,
                      color: selected ? null : Colors.white.withAlpha(160),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: selected ? Colors.transparent : Colors.white.withAlpha(160),
                      ),
                      boxShadow: selected ? AppShadows.md(AppColors.primary.withAlpha(90)) : null,
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.surfaceDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _step = 0);
                  },
                  child: const Text('Back'),
                ),
                const Spacer(),
                PremiumGradientButton(
                  label: 'Next',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _step = 2);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentStep() {
    return SingleChildScrollView(
      key: const ValueKey('comment'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
      child: PremiumGlassCard(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepBadge(icon: Icons.edit_note_rounded, label: 'Step 3 · Add a comment'),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Add a few words',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Optional — tell others what made this experience memorable.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xxl),
            PremiumGlassCard(
              gradient: [Colors.white.withAlpha(150), Colors.white.withAlpha(90)],
              borderRadius: BorderRadius.circular(AppRadius.xl),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TextField(
                controller: _commentCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Share your experience...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
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
                            width: 20,
                            height: 20,
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
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _step = 1);
                },
                child: const Text('Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThankYouStep() {
    return SingleChildScrollView(
      key: const ValueKey('done'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
      child: PremiumGlassCard(
        gradient: [const Color(0xFF0F172A).withAlpha(240), const Color(0xFF1E1B4B).withAlpha(225)],
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.success.withAlpha(120),
                        AppColors.accent.withAlpha(20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const AnimatedSuccessCheck(size: 100, color: Colors.white),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Thank you! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your feedback helps the community find great professionals.',
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
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StepBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
