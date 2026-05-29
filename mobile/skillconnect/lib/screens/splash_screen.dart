import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Stage 1: logo scale + glow ring
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;

  // Stage 2: text slide-up
  late final AnimationController _textCtrl;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  // Stage 3: shimmer sweep + progress bar
  late final AnimationController _shimmerCtrl;
  late final AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();

    // Stage 1 — logo + glow ring (0–700ms)
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.4)));
    _ringScale = Tween<double>(begin: 0.6, end: 1.4).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));
    _ringOpacity = Tween<double>(begin: 0.7, end: 0.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));

    // Stage 2 — text (700–1300ms)
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    // Stage 3 — shimmer sweep (repeating)
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();

    // Progress bar (1300–2400ms)
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

    // Sequence
    _logoCtrl.forward().then((_) async {
      await _textCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 100));
      _progressCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => widget.nextScreen,
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ));
      }
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _shimmerCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: AnimatedBuilder(
        animation: Listenable.merge([_logoCtrl, _textCtrl, _shimmerCtrl, _progressCtrl]),
        builder: (context, _) {
          return Stack(
            children: [
              // Background gradient blobs
              Positioned(top: -80, left: -80,
                child: _GlowBlob(color: const Color(0xFF6366F1).withAlpha(60), size: 280)),
              Positioned(bottom: -60, right: -60,
                child: _GlowBlob(color: const Color(0xFF8B5CF6).withAlpha(50), size: 240)),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glow ring behind logo
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Opacity(
                          opacity: _ringOpacity.value,
                          child: Transform.scale(
                            scale: _ringScale.value,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF6366F1).withAlpha(180),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Second ring
                        Opacity(
                          opacity: _ringOpacity.value * 0.5,
                          child: Transform.scale(
                            scale: _ringScale.value * 1.3,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6).withAlpha(100),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Logo card with shimmer
                        Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: _ShimmerLogo(shimmerValue: _shimmerCtrl.value),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Text section
                    SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(
                        opacity: _textOpacity,
                        child: Column(
                          children: [
                            const Text(
                              'SkillConnect',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'India\'s Super App for Home Services',
                              style: TextStyle(
                                color: Colors.white.withAlpha(160),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress bar at bottom
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _textOpacity,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 48),
                        child: Column(
                          children: [
                            Text(
                              'Connecting skilled professionals',
                              style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 12),
                            ),
                            const SizedBox(height: 20),
                            // Progress bar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 48),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _progressCtrl.value,
                                  backgroundColor: Colors.white.withAlpha(20),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                                  minHeight: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShimmerLogo extends StatelessWidget {
  final double shimmerValue;
  const _ShimmerLogo({required this.shimmerValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(120),
            blurRadius: 40,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(Icons.handyman_rounded, size: 56, color: Colors.white),
          ),
          // Shimmer sweep
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment(-1.5 + shimmerValue * 3.5, 0),
                  end: Alignment(-0.5 + shimmerValue * 3.5, 0),
                  colors: [
                    Colors.white.withAlpha(0),
                    Colors.white.withAlpha(60),
                    Colors.white.withAlpha(0),
                  ],
                ).createShader(bounds),
                child: Container(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
