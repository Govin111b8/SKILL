import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/models.dart';

class PortfolioGrid extends StatelessWidget {
  final List<PortfolioItem> items;
  const PortfolioGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No portfolio items yet.'));
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: item.mediaUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.mediaUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (_, __) => Container(color: Colors.grey.shade200),
                          errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Center(child: Icon(Icons.image, size: 40)),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
