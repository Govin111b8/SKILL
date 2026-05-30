import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';

/// Welcome screen — the first thing users see. Lets them pick their role
/// (Customer or Professional) before proceeding to login/register.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late final AnimationController _blobCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _blobCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _blobCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _goToLogin(String role) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LoginScreen(selectedRole: role),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: AnimatedBuilder(
        animation: _blobCtrl,
        builder: (_, __) => Stack(
          children: [
            // Animated background blobs
            _AnimatedBlob(
              animation: _blobCtrl,
              color: const Color(0xFF6366F1),
              baseOffset: const Offset(-80, -60),
              amplitude: 30,
              phase: 0,
              size: 320,
            ),
            _AnimatedBlob(
              animation: _blobCtrl,
              color: const Color(0xFF8B5CF6),
              baseOffset: const Offset(200, 80),
              amplitude: 20,
              phase: math.pi,
              size: 200,
            ),
            _AnimatedBlob(
              animation: _blobCtrl,
              color: const Color(0xFF06B6D4),
              baseOffset: const Offset(60, 560),
              amplitude: 25,
              phase: math.pi / 2,
              size: 260,
            ),

            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Logo with pulsing glow
                      _PulsingLogo(ctrl: _blobCtrl),

                      const SizedBox(height: 20),

                      // App name
                      const Text(
                        'SkillConnect',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'India\'s #1 Super App for Home Services',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withAlpha(140),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatChip(label: '40+ Services'),
                          const SizedBox(width: 8),
                          _StatChip(label: '1M+ Jobs'),
                          const SizedBox(width: 8),
                          _StatChip(label: '₹0 Commission'),
                        ],
                      ),

                      const Spacer(),

                      // Role heading
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'I want to...',
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Role cards
                      _GlassRoleCard(
                        emoji: '👤',
                        title: 'Customer',
                        subtitle: 'Find & hire skilled pros\nfor any service you need',
                        accentColor: const Color(0xFF6366F1),
                        onTap: () => _goToLogin('customer'),
                      ),
                      const SizedBox(height: 12),
                      _GlassRoleCard(
                        emoji: '🔧',
                        title: 'Professional',
                        subtitle: 'Offer your skills, grow\nyour business & earn more',
                        accentColor: const Color(0xFF06B6D4),
                        onTap: () => _goToLogin('professional'),
                      ),
                      const SizedBox(height: 12),
                      _GlassRoleCard(
                        emoji: '🤝',
                        title: 'Agent',
                        subtitle: 'Refer pros, earn commissions\nand expand the network',
                        accentColor: const Color(0xFF10B981),
                        onTap: () => _goToLogin('agent'),
                      ),

                      const SizedBox(height: 24),

                      // Admin login
                      TextButton(
                        onPressed: () => _goToLogin('admin'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withAlpha(80),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.admin_panel_settings_rounded, size: 14,
                                color: Colors.white.withAlpha(80)),
                            const SizedBox(width: 6),
                            Text('Admin Login',
                                style: TextStyle(
                                    color: Colors.white.withAlpha(80), fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBlob extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final Offset baseOffset;
  final double amplitude;
  final double phase;
  final double size;

  const _AnimatedBlob({
    required this.animation,
    required this.color,
    required this.baseOffset,
    required this.amplitude,
    required this.phase,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final t = animation.value * 2 * math.pi + phase;
    final dx = baseOffset.dx + math.sin(t * 0.7) * amplitude;
    final dy = baseOffset.dy + math.cos(t * 0.5) * amplitude;

    return Positioned(
      left: dx,
      top: dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withAlpha(40),
        ),
      ),
    );
  }
}

class _PulsingLogo extends StatelessWidget {
  final AnimationController ctrl;
  const _PulsingLogo({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final pulse = 0.5 + 0.5 * math.sin(ctrl.value * 2 * math.pi);
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring
            Container(
              width: 96 + pulse * 16,
              height: 96 + pulse * 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6366F1).withAlpha((40 + pulse * 60).toInt()),
                  width: 1.5,
                ),
              ),
            ),
            // Logo
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withAlpha((80 + pulse * 60).toInt()),
                    blurRadius: 24 + pulse * 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.handyman_rounded, size: 44, color: Colors.white),
            ),
          ],
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  const _StatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withAlpha(160),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _GlassRoleCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _GlassRoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_GlassRoleCard> createState() => _GlassRoleCardState();
}

class _GlassRoleCardState extends State<_GlassRoleCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _chevronCtrl;
  late final Animation<double> _chevronBounce;

  @override
  void initState() {
    super.initState();
    _chevronCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _chevronBounce = Tween<double>(begin: 0, end: 6).animate(
        CurvedAnimation(parent: _chevronCtrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _chevronCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _chevronCtrl.forward(from: 0);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(20)),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withAlpha(30),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Emoji in frosted circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.accentColor.withAlpha(30),
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.accentColor.withAlpha(60)),
                ),
                child: Center(
                  child: Text(widget.emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: Colors.white.withAlpha(160),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Animated chevron
              AnimatedBuilder(
                animation: _chevronBounce,
                builder: (_, __) => Transform.translate(
                  offset: Offset(_chevronBounce.value, 0),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: widget.accentColor.withAlpha(200),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
