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
      bgGradient: [Color(0xFF6366F1), Color(0xFF4F46E5)],
      title: 'Find Skilled Pros',
      subtitle: 'Search from 40+ verified service categories.\nPlumbers, tutors, designers — all in one place.',
      illustration: '🔍',
    ),
    _OnboardingPage(
      icon: Icons.verified_rounded,
      iconGradient: [Color(0xFF10B981), Color(0xFF059669)],
      bgGradient: [Color(0xFF059669), Color(0xFF065F46)],
      title: 'Verified & Trusted',
      subtitle: 'Every professional is verified with KYC.\nRead real reviews from your neighbors.',
      illustration: '✅',
    ),
    _OnboardingPage(
      icon: Icons.calendar_month_rounded,
      iconGradient: [Color(0xFFF59E0B), Color(0xFFEF4444)],
      bgGradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      title: 'Book Instantly',
      subtitle: 'Schedule at your convenience.\nPay securely with multiple options.',
      illustration: '📅',
    ),
    _OnboardingPage(
      icon: Icons.star_rounded,
      iconGradient: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
      bgGradient: [Color(0xFF0288D1), Color(0xFF01579B)],
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
    final page = _pages[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: AppDurations.normal,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: page.bgGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar: logo + skip
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.lg, 0),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text('SkillConnect', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _finish,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: Colors.white.withAlpha(40)),
                      ),
                      child: const Text('Skip', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _currentPage = i);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _buildPage(_pages[i]),
                ),
              ),

              // Dot indicators
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: AppDurations.normal,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white.withAlpha(50),
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
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: page.bgGradient.first,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLast ? '🚀 Get Started' : 'Next  →',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: page.bgGradient.first,
                          ),
                        ),
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
          // Full illustration circle
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(20),
              border: Border.all(color: Colors.white.withAlpha(40), width: 2),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(page.illustration, style: const TextStyle(fontSize: 70)),
            ]),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          // Icon badge
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: Colors.white.withAlpha(60), width: 2),
            ),
            child: Icon(page.icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            page.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 15,
              height: 1.6,
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
  final List<Color> bgGradient;
  final String title;
  final String subtitle;
  final String illustration;

  const _OnboardingPage({
    required this.icon,
    required this.iconGradient,
    required this.bgGradient,
    required this.title,
    required this.subtitle,
    required this.illustration,
  });
}
