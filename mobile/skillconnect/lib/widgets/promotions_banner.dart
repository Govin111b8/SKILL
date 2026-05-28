import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Auto-scrolling promotional banner carousel for the home screen.
/// Shows seasonal offers, featured professionals, and campaigns.
class PromotionsBanner extends StatefulWidget {
  const PromotionsBanner({super.key});

  @override
  State<PromotionsBanner> createState() => _PromotionsBannerState();
}

class _PromotionsBannerState extends State<PromotionsBanner> {
  final _controller = PageController();
  int _currentPage = 0;
  Timer? _timer;

  static const _banners = [
    _BannerData(
      title: 'Summer Special',
      subtitle: 'AC servicing at 20% off — verified technicians near you',
      emoji: '❄️',
      gradient: [Color(0xFF06B6D4), Color(0xFF0284C7)],
    ),
    _BannerData(
      title: 'New: Home Services',
      subtitle: 'Deep cleaning, painting, pest control — book in 2 taps',
      emoji: '🏠',
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
    ),
    _BannerData(
      title: 'Refer & Earn ₹200',
      subtitle: 'Share with friends, both get ₹200 off first booking',
      emoji: '🎁',
      gradient: [Color(0xFFF59E0B), Color(0xFFEA580C)],
    ),
    _BannerData(
      title: 'Zero Commission',
      subtitle: 'Professionals keep 100% earnings — better rates for you',
      emoji: '💰',
      gradient: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _banners.length;
      _controller.animateToPage(next, duration: AppDurations.slow, curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
          child: Text(
            'Promotions & Updates',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        // Carousel
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _banners.length,
            itemBuilder: (_, i) {
              final banner = _banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: banner.gradient,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: AppShadows.md(banner.gradient.first),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              banner.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              banner.subtitle,
                              style: TextStyle(
                                color: Colors.white.withAlpha(210),
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Text(banner.emoji, style: const TextStyle(fontSize: 48)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Dot indicators
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: AppDurations.normal,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.primary.withAlpha(40),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerData {
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> gradient;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradient,
  });
}
