import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/models.dart';
import '../screens/profile/professional_profile_screen.dart';
import 'trust_badge.dart';

class ProfessionalCard extends StatelessWidget {
  final Professional professional;
  const ProfessionalCard({super.key, required this.professional});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ProfessionalProfileScreen(professionalId: professional.id),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary.withAlpha(180), cs.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(professional.name.isNotEmpty ? professional.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(professional.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (professional.kycLevel > 0 || professional.trustScore > 0) ...[
                        TrustBadge(kycLevel: professional.kycLevel, trustScore: professional.trustScore, compact: true),
                        const SizedBox(width: 4),
                      ],
                      if (professional.availabilityStatus == 'available')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFF10B981).withAlpha(20), borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            const Text('Online', style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                          ]),
                        ),
                    ]),
                    if (professional.headline != null) ...[
                      const SizedBox(height: 3),
                      Text(professional.headline!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    ],
                    const SizedBox(height: 8),
                    Row(children: [
                      RatingBarIndicator(
                        rating: professional.averageRating,
                        itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Color(0xFFFBBF24)),
                        itemSize: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(professional.averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(' (${professional.reviewCount})', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                      const Spacer(),
                      if (professional.pricingEstimate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: cs.primary.withAlpha(15), borderRadius: BorderRadius.circular(8)),
                          child: Text('From ₹${professional.pricingEstimate}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
                        ),
                    ]),
                    if (professional.location != null) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Expanded(child: Text(professional.location!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (professional.distance != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF06B6D4).withAlpha(20), borderRadius: BorderRadius.circular(8)),
                            child: Text('${professional.distance!.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF06B6D4))),
                          ),
                        ],
                      ]),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}
