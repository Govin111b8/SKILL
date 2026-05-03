import 'package:flutter/material.dart';

class AnnouncementBanner extends StatelessWidget {
  final String text;
  const AnnouncementBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: cs.primaryContainer,
      child: Row(
        children: [
          Icon(Icons.campaign, size: 20, color: cs.onPrimaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: cs.onPrimaryContainer, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
