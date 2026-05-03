import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../models/models.dart';

class HeroBanner extends StatelessWidget {
  final Professional professional;
  const HeroBanner({super.key, required this.professional});

  @override
  Widget build(BuildContext context) {
    final p = professional;
    final cs = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Cover image
        if (p.coverImageUrl != null && p.coverImageUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: p.coverImageUrl!,
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.3),
            colorBlendMode: BlendMode.darken,
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.secondary],
              ),
            ),
          ),
        // Content overlay
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 36,
                backgroundColor: cs.surface,
                child: Text(
                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cs.primary),
                ),
              ),
              const SizedBox(height: 8),
              // Name + verified badge
              Row(children: [
                Flexible(
                  child: Text(
                    p.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (p.govIdVerified) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                ],
              ]),
              // Headline
              if (p.headline != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(p.headline!, style: const TextStyle(fontSize: 14, color: Colors.white70), maxLines: 2),
                ),
              const SizedBox(height: 6),
              // Rating + location
              Row(children: [
                if (p.showRating) ...[
                  RatingBarIndicator(
                    rating: p.averageRating,
                    itemSize: 16,
                    itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                  ),
                  const SizedBox(width: 4),
                  Text('${p.averageRating.toStringAsFixed(1)} (${p.reviewCount})',
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  const SizedBox(width: 12),
                ],
                if (p.location != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.white60),
                    const SizedBox(width: 2),
                    Text(p.location!, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ]),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}
