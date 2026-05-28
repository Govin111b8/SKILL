import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../services/api_service.dart';
import '../../widgets/app_components.dart';

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
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _step == 3
                ? [const Color(0xFF10B981), const Color(0xFF059669)]
                : [const Color(0xFF0F172A), const Color(0xFF1E1B4B)],
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: AppDurations.normal,
            child: _buildStep(),
          ),
        ),
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
    return Padding(
      key: const ValueKey('stars'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 56)),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'How was your experience?',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${widget.serviceName} by ${widget.professionalName}',
            style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          // Star row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _rating;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _rating = i + 1);
                },
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 48,
                    color: filled ? AppColors.warning : Colors.white.withAlpha(60),
                  ),
                ),
              );
            }),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _rating >= 4 ? 'Excellent! 🎉' : _rating >= 3 ? 'Good 👍' : 'We\'re sorry 😔',
              style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: AppSpacing.huge),
          if (_rating > 0)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => setState(() => _step = 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTagsStep() {
    return Padding(
      key: const ValueKey('tags'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _rating >= 4 ? 'What did you love?' : 'What could improve?',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Select all that apply',
            style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: _tags.map((tag) {
              final selected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.white.withAlpha(40),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white.withAlpha(180),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.huge),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 0),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withAlpha(60)),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _step = 2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
                child: const Text('Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildCommentStep() {
    return Padding(
      key: const ValueKey('comment'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Any additional feedback?',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Optional — help others make informed decisions',
            style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextField(
            controller: _commentCtrl,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Share your experience...',
              hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
              filled: true,
              fillColor: Colors.white.withAlpha(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: Colors.white.withAlpha(30)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: Colors.white.withAlpha(30)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => setState(() => _step = 1),
            child: Text('Back', style: TextStyle(color: Colors.white.withAlpha(160))),
          ),
        ],
      ),
    );
  }

  Widget _buildThankYouStep() {
    return Padding(
      key: const ValueKey('done'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AnimatedSuccessCheck(size: 100, color: Colors.white),
          const SizedBox(height: AppSpacing.xxl),
          const Text(
            'Thank you! 🎉',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your feedback helps the community find great professionals.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.huge),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
              child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
