import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/design_tokens.dart';

/// Contextual tip banner — shows a dismissible tip to guide users.
/// Only shows once per [tipKey] (persisted via SharedPreferences).
class ContextualTip extends StatefulWidget {
  final String tipKey;
  final String title;
  final String message;
  final IconData icon;
  final Color? color;

  const ContextualTip({
    super.key,
    required this.tipKey,
    required this.title,
    required this.message,
    this.icon = Icons.lightbulb_rounded,
    this.color,
  });

  @override
  State<ContextualTip> createState() => _ContextualTipState();
}

class _ContextualTipState extends State<ContextualTip> with SingleTickerProviderStateMixin {
  bool _visible = false;
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppDurations.normal);
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _checkVisibility();
  }

  Future<void> _checkVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('tip_${widget.tipKey}') ?? false;
    if (!dismissed && mounted) {
      setState(() => _visible = true);
      _ctrl.forward();
    }
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tip_${widget.tipKey}', true);
    if (mounted) setState(() => _visible = false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final color = widget.color ?? AppColors.info;
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(widget.icon, size: 16, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
                  const SizedBox(height: 2),
                  Text(widget.message, style: TextStyle(fontSize: 12, color: color.withAlpha(200), height: 1.4)),
                ],
              ),
            ),
            GestureDetector(
              onTap: _dismiss,
              child: Icon(Icons.close_rounded, size: 16, color: color.withAlpha(120)),
            ),
          ],
        ),
      ),
    );
  }
}
