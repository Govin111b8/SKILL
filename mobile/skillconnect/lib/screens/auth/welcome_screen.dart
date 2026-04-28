import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Welcome screen — the first thing users see. Lets them pick their role
/// (Customer or Professional) before proceeding to login/register.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withAlpha(100),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.handyman_rounded, size: 44, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'SkillConnect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connecting skilled professionals\nwith customers who need them',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withAlpha(160),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),

                const Spacer(flex: 2),

                // Role cards
                const Text(
                  'I am a...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Customer card
                _RoleCard(
                  icon: Icons.person_rounded,
                  emoji: '👤',
                  title: 'Customer',
                  subtitle: 'Find & hire skilled professionals\nfor any service you need',
                  gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  onTap: () => _goToLogin(context, 'customer'),
                ),
                const SizedBox(height: 14),

                // Professional card
                _RoleCard(
                  icon: Icons.work_rounded,
                  emoji: '🔧',
                  title: 'Professional',
                  subtitle: 'Offer your skills, get bookings\nand grow your business',
                  gradient: const [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  onTap: () => _goToLogin(context, 'professional'),
                ),

                const Spacer(flex: 1),

                // Bottom info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_rounded, size: 16, color: Colors.white.withAlpha(120)),
                      const SizedBox(width: 8),
                      Text(
                        '40+ services · 20+ verified pros · ₹0 commission',
                        style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goToLogin(BuildContext context, String role) {
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
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withAlpha(80),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(50)),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withAlpha(180), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
