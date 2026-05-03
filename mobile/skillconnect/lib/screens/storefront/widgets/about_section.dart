import 'package:flutter/material.dart';
import '../../../models/models.dart';

class AboutSection extends StatefulWidget {
  final Professional professional;
  const AboutSection({super.key, required this.professional});

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final bio = widget.professional.bio ?? 'No bio available.';
    final shouldTruncate = bio.length > 200;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AnimatedCrossFade(
            firstChild: Text(bio, maxLines: 4, overflow: TextOverflow.ellipsis),
            secondChild: Text(bio),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          if (shouldTruncate)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _expanded ? 'Show less' : 'Read more',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
