import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/smart_location_service.dart';
import '../models/models.dart';
import 'professional_card.dart';

/// Widget showing real-time nearby available providers on the home screen.
/// Auto-refreshes when location changes.
class NearbyProvidersSection extends StatelessWidget {
  const NearbyProvidersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SmartLocationService>(
      builder: (context, locationService, _) {
        if (locationService.error != null && locationService.nearbyProviders.isEmpty) {
          return _buildLocationPrompt(context, locationService);
        }

        if (locationService.loading && locationService.nearbyProviders.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (locationService.nearbyProviders.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.near_me, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Available Nearby',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ]),
                  if (locationService.loading)
                    const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: locationService.nearbyProviders.length.clamp(0, 10),
                itemBuilder: (context, i) {
                  final pro = locationService.nearbyProviders[i];
                  return SizedBox(
                    width: 280,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _NearbyProviderCard(professional: pro),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationPrompt(BuildContext context, SmartLocationService service) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.location_off, size: 32, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text('Enable location to find nearby providers',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => service.refreshLocation(),
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('Enable Location'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearbyProviderCard extends StatelessWidget {
  final Professional professional;

  const _NearbyProviderCard({required this.professional});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/professional', arguments: professional.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    professional.name.isNotEmpty ? professional.name[0].toUpperCase() : '?',
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(professional.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (professional.headline != null)
                      Text(professional.headline!, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                )),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                const SizedBox(width: 4),
                Text('${professional.averageRating.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                if (professional.distance != null) ...[
                  Icon(Icons.location_on, size: 14, color: cs.primary),
                  const SizedBox(width: 2),
                  Text('${professional.distance!.toStringAsFixed(1)} km',
                      style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w500)),
                ],
              ]),
              const Spacer(),
              if (professional.availabilityStatus == 'available')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
                    const SizedBox(width: 4),
                    Text('Available Now', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
