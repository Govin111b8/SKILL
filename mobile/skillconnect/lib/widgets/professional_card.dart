import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/models.dart';
import '../screens/storefront/storefront_screen.dart';
import 'trust_badge.dart';

class ProfessionalCard extends StatelessWidget {
  final Professional professional;
  const ProfessionalCard({super.key, required this.professional});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = professional;
    final isAvailable = p.availabilityStatus == 'available';

    // Avatar gradient colors based on name initial
    final avatarColors = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFF06B6D4), const Color(0xFF3B82F6)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      [const Color(0xFFEC4899), const Color(0xFF8B5CF6)],
    ];
    final c = avatarColors[(p.name.isEmpty ? 0 : p.name.codeUnitAt(0)) % avatarColors.length];

    return Semantics(
      label: '${p.name}, ${p.headline ?? "Professional"}. Rating: ${p.rating.toStringAsFixed(1)} stars. ${isAvailable ? "Available now" : ""}',
      button: true,
      child: Card(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => StorefrontScreen(professionalId: p.id),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // — Row 1: Avatar + Name + Badges + Availability
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Avatar
              Stack(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: c, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(
                    p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                  )),
                ),
                if (isAvailable)
                  Positioned(bottom: 0, right: 0,
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 2),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(width: 12),
              // Name + headline
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(p.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (p.kycLevel > 0)
                    TrustBadge(kycLevel: p.kycLevel, trustScore: p.trustScore, compact: true),
                ]),
                if (p.headline != null) ...[
                  const SizedBox(height: 2),
                  Text(p.headline!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
                ],
              ])),
            ]),

            const SizedBox(height: 10),

            // — Row 2: Rating + Reviews + Price
            Row(children: [
              RatingBarIndicator(
                rating: p.averageRating,
                itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Color(0xFFFBBF24)),
                itemSize: 15,
              ),
              const SizedBox(width: 4),
              Text(p.averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFFBBF24))),
              Text(' · ${p.reviewCount} reviews', style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              if (p.pricingEstimate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: cs.primary.withAlpha(15), borderRadius: BorderRadius.circular(10)),
                  child: Text('₹${p.pricingEstimate}/hr', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.primary)),
                ),
            ]),

            // — Row 3: Location + Distance tags
            if (p.location != null || p.distance != null || isAvailable) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 4, children: [
                if (p.location != null)
                  _Tag(icon: Icons.location_on_outlined, label: p.location!, iconColor: Colors.grey.shade500, isDark: isDark),
                if (p.distance != null)
                  _Tag(icon: Icons.near_me_rounded, label: '${p.distance!.toStringAsFixed(1)} km', iconColor: const Color(0xFF06B6D4), isDark: isDark, accent: true),
                if (isAvailable)
                  _Tag(icon: Icons.circle, label: 'Available now', iconColor: const Color(0xFF10B981), isDark: isDark, accent: true),
              ]),
            ],
          ]),
        ),
      ),
    ));
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final bool isDark;
  final bool accent;
  const _Tag({required this.icon, required this.label, required this.iconColor, required this.isDark, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent ? iconColor.withAlpha(18) : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: iconColor),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent ? iconColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
