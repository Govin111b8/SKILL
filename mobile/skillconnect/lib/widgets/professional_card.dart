import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/models.dart';

class ProfessionalCard extends StatelessWidget {
  final Professional professional;
  const ProfessionalCard({super.key, required this.professional});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/professional', arguments: professional.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: cs.primaryContainer,
                child: Text(professional.name[0].toUpperCase(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.primary)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(professional.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                      if (professional.availabilityStatus == 'available')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Text('Available', style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                        ),
                    ]),
                    if (professional.headline != null) ...[
                      const SizedBox(height: 2),
                      Text(professional.headline!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                    const SizedBox(height: 6),
                    Row(children: [
                      RatingBarIndicator(
                        rating: professional.averageRating,
                        itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                        itemSize: 16,
                      ),
                      const SizedBox(width: 6),
                      Text('${professional.averageRating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                      Text(' (${professional.reviewCount})', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      const Spacer(),
                      if (professional.location != null)
                        Row(children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 2),
                          Text(professional.location!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ]),
                    ]),
                    if (professional.pricingEstimate != null) ...[
                      const SizedBox(height: 4),
                      Text('From \$${professional.pricingEstimate}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
