import 'package:flutter/material.dart';

/// Trust badge — shows verified level / score with appropriate color & icon.
class TrustBadge extends StatelessWidget {
  final int? kycLevel; // 0..3
  final int? trustScore; // 0..100
  final String? level; // test-friendly named level: bronze/silver/gold
  final List<String>? verifiedTypes;
  final bool compact;
  const TrustBadge({super.key, this.kycLevel, this.trustScore, this.level, this.verifiedTypes, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final verificationLevel = kycLevel ?? 0;
    final score = trustScore ?? 0;
    final (label, color, icon) = _badgeFor(verificationLevel, score, level);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: color.withAlpha(35), borderRadius: BorderRadius.circular(100), border: Border.all(color: color.withAlpha(80))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(100), border: Border.all(color: color.withAlpha(80))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        if (score > 0) ...[
          const SizedBox(width: 5),
          Container(width: 1, height: 10, color: color.withAlpha(60)),
          const SizedBox(width: 5),
          Text('$score', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ]),
    );
  }

  (String, Color, IconData) _badgeFor(int level, int score, String? levelName) {
    switch (levelName) {
      case 'gold':
        return ('Gold', const Color(0xFFF59E0B), Icons.workspace_premium_rounded);
      case 'silver':
        return ('Silver', const Color(0xFF94A3B8), Icons.verified_rounded);
      case 'bronze':
        return ('Bronze', const Color(0xFFB45309), Icons.shield_rounded);
      default:
        break;
    }

    if (level >= 3 || score >= 80) return ('Pro Verified', const Color(0xFF10B981), Icons.verified_rounded);
    if (level >= 2 || score >= 50) return ('ID Verified', const Color(0xFF6366F1), Icons.verified_user_rounded);
    if (level >= 1 || score >= 1)  return ('Phone Verified', const Color(0xFFF59E0B), Icons.phone_android_rounded);
    return ('Unverified', const Color(0xFF94A3B8), Icons.help_outline_rounded);
  }
}
