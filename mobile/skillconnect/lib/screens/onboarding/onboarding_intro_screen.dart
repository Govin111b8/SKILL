import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/design_tokens.dart';

/// Onboarding intro carousel shown to first-time users.
/// Swipeable 4-screen experience explaining the app value proposition.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.search_rounded,
      iconGradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      title: 'Find Skilled Pros',
      subtitle: 'Search from 40+ verified service categories.\nPlumbers, tutors, designers — all in one place.',
      illustration: '🔍',
    ),
    _OnboardingPage(
      icon: Icons.verified_rounded,
      iconGradient: [Color(0xFF10B981), Color(0xFF059669)],
      title: 'Verified & Trusted',
      subtitle: 'Every professional is verified with KYC.\nRead real reviews from your neighbors.',
      illustration: '✅',
    ),
    _OnboardingPage(
      icon: Icons.calendar_month_rounded,
      iconGradient: [Color(0xFFF59E0B), Color(0xFFEF4444)],
      title: 'Book Instantly',
      subtitle: 'Schedule at your convenience.\nPay securely with multiple options.',
      illustration: '📅',
    ),
    _OnboardingPage(
      icon: Icons.star_rounded,
      iconGradient: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
      title: 'Rate & Earn Rewards',
      subtitle: 'Share feedback, earn points.\nRefer friends and get discounts.',
      illustration: '⭐',
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(duration: AppDurations.normal, curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: GestureDetector(
                    onTap: _finish,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: Colors.white.withAlpha(30)),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _buildPage(_pages[i]),
                ),
              ),

              // Dot indicators
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: AppDurations.normal,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),

              // Next / Get Started button
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.xxxl),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLast ? 'Get Started' : 'Next',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Icon(isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large emoji illustration
          Text(page.illustration, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: AppSpacing.xxl),
          // Icon badge
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: page.iconGradient),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppShadows.lg(page.iconGradient.first),
            ),
            child: Icon(page.icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            page.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String subtitle;
  final String illustration;

  const _OnboardingPage({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.illustration,
  });
}
