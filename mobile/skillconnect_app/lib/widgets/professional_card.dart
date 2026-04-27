import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/professional.dart';

class ProfessionalCard extends StatelessWidget {
  final Professional professional;
  final VoidCallback onTap;
  const ProfessionalCard({super.key, required this.professional, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = professional;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.primary.withValues(alpha: 0.1),
              child: Text(
                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.primary),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (p.isAvailable)
                  Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
              ]),
              if (p.headline.isNotEmpty)
                Text(p.headline, style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                RatingBarIndicator(
                  rating: p.averageRating,
                  itemSize: 16,
                  itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                ),
                const SizedBox(width: 4),
                Text('${p.averageRating.toStringAsFixed(1)} (${p.reviewCount})', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 2),
                Expanded(child: Text(p.location, style: TextStyle(fontSize: 12, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (p.distance != null) Text('${p.distance!.toStringAsFixed(1)} km', style: TextStyle(fontSize: 12, color: cs.primary)),
              ]),
              if (p.categories.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 4, runSpacing: 4, children: p.categories.take(3).map((c) =>
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
                    child: Text(c, style: TextStyle(fontSize: 11, color: cs.primary)),
                  ),
                ).toList()),
              ],
            ])),
          ]),
        ),
      ),
    );
  }
}
