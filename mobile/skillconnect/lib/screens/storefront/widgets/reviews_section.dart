import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../models/models.dart';

class ReviewsSection extends StatelessWidget {
  final List<Review> reviews;
  final Map<int, int> distribution;
  final double averageRating;
  final int reviewCount;
  const ReviewsSection({
    super.key,
    required this.reviews,
    required this.distribution,
    required this.averageRating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = distribution.values.fold(0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary header
        Row(children: [
          Column(children: [
            Text(averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
            RatingBarIndicator(
              rating: averageRating,
              itemSize: 18,
              itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
            ),
            const SizedBox(height: 4),
            Text('$reviewCount reviews', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ]),
          const SizedBox(width: 24),
          Expanded(child: _RatingDistChart(distribution: distribution, total: total)),
        ]),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        // Review list
        if (reviews.isEmpty)
          const Center(child: Text('No reviews yet.'))
        else
          ...reviews.map((r) => _ReviewTile(review: r)),
      ],
    );
  }
}

class _RatingDistChart extends StatelessWidget {
  final Map<int, int> distribution;
  final int total;
  const _RatingDistChart({required this.distribution, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (i) {
        final star = 5 - i;
        final count = distribution[star] ?? 0;
        final pct = total > 0 ? count / total : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Text('$star', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.star, size: 12, color: Colors.amber),
            const SizedBox(width: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(width: 24, child: Text('$count', style: const TextStyle(fontSize: 11), textAlign: TextAlign.end)),
          ]),
        );
      }),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(radius: 14, child: Text((review.reviewerName ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 12))),
            const SizedBox(width: 8),
            Expanded(child: Text(review.reviewerName ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
            RatingBarIndicator(
              rating: review.rating.toDouble(),
              itemSize: 14,
              itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
            ),
          ]),
          if (review.comment != null && review.comment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 36),
              child: Text(review.comment!, style: const TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
