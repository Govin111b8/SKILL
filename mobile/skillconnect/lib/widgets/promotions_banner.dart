import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/design_tokens.dart';
import '../services/api_service.dart';

/// Auto-scrolling promotional banner carousel for the home screen.
/// Fetches banners from GET /api/promotions; falls back to static banners
/// if the API is unavailable.
class PromotionsBanner extends StatefulWidget {
  const PromotionsBanner({super.key});

  @override
  State<PromotionsBanner> createState() => _PromotionsBannerState();
}

class _PromotionsBannerState extends State<PromotionsBanner> {
  final _controller = PageController();
  int _currentPage = 0;
  Timer? _timer;
  List<_BannerData> _banners = _kDefaultBanners;

  static const _kDefaultBanners = [
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
    _fetchBanners();
    _startAutoScroll();
  }

  Future<void> _fetchBanners() async {
    try {
      final res = await ApiService.get('/promotions');
      final list = res['data'] as List? ?? [];
      if (list.isEmpty) return;
      final fetched = list.map((item) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(item as Map);
        return _BannerData(
          title: m['title']?.toString() ?? '',
          subtitle: m['subtitle']?.toString() ?? '',
          emoji: m['emoji']?.toString() ?? '🎁',
          imageUrl: m['image_url']?.toString(),
          gradient: [
            _parseColor(m['gradient_from']?.toString(), const Color(0xFF6366F1)),
            _parseColor(m['gradient_to']?.toString(), const Color(0xFF8B5CF6)),
          ],
        );
      }).toList();
      if (mounted) setState(() => _banners = fetched);
    } catch (_) {
      // Silently keep default banners
    }
  }

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null) return fallback;
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _banners.isEmpty) return;
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
    if (_banners.isEmpty) return const SizedBox.shrink();
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
          height: 160,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _banners.length,
            itemBuilder: (_, i) {
              final banner = _banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background: network image or gradient
                      if (banner.imageUrl != null)
                        CachedNetworkImage(
                          imageUrl: banner.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _GradientBg(gradient: banner.gradient),
                          placeholder: (_, __) => _GradientBg(gradient: banner.gradient),
                        )
                      else
                        _GradientBg(gradient: banner.gradient),

                      // Dark overlay for text readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withAlpha(160)],
                          ),
                        ),
                      ),

                      // Text overlay (bottom-left, matching design image)
                      Positioned(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        bottom: AppSpacing.lg,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              banner.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              banner.subtitle,
                              style: TextStyle(
                                color: Colors.white.withAlpha(220),
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                                shadows: const [Shadow(color: Colors.black38, blurRadius: 3)],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Emoji (top-right, only if no image)
                      if (banner.imageUrl == null)
                        Positioned(
                          right: 16,
                          top: 16,
                          child: Text(banner.emoji, style: const TextStyle(fontSize: 48)),
                        ),
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
                color: active ? AppColors.superBlue : AppColors.superBlue.withAlpha(60),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _GradientBg extends StatelessWidget {
  final List<Color> gradient;
  const _GradientBg({required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
    );
  }
}

class _BannerData {
  final String title;
  final String subtitle;
  final String emoji;
  final String? imageUrl;
  final List<Color> gradient;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.emoji,
    this.imageUrl,
    required this.gradient,
  });
}
