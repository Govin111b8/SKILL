import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class ProfessionalProfileScreen extends StatefulWidget {
  final String professionalId;
  const ProfessionalProfileScreen({super.key, required this.professionalId});

  @override
  State<ProfessionalProfileScreen> createState() => _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState extends State<ProfessionalProfileScreen> {
  Professional? _professional;
  List<Review> _reviews = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.get('/professionals/${widget.professionalId}'),
        ApiService.get('/reviews/${widget.professionalId}'),
      ]);
      _professional = Professional.fromJson(results[0]['data']);
      _reviews = (results[1]['data'] as List).map((e) => Review.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Professional Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(_error!),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: cs.primaryContainer,
                            child: Text(_professional!.name[0].toUpperCase(), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: cs.primary)),
                          ),
                          const SizedBox(height: 12),
                          Text(_professional!.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          if (_professional!.headline != null) ...[
                            const SizedBox(height: 4),
                            Text(_professional!.headline!, style: TextStyle(color: Colors.grey.shade600)),
                          ],
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            RatingBarIndicator(
                              rating: _professional!.averageRating,
                              itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                              itemSize: 20,
                            ),
                            const SizedBox(width: 8),
                            Text('${_professional!.averageRating.toStringAsFixed(1)} (${_professional!.reviewCount})', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ]),
                          const SizedBox(height: 12),
                          if (_professional!.availabilityStatus != null)
                            Chip(
                              avatar: Icon(Icons.circle, size: 10, color: _professional!.availabilityStatus == 'available' ? Colors.green : Colors.orange),
                              label: Text(_professional!.availabilityStatus!.toUpperCase(), style: const TextStyle(fontSize: 11)),
                            ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Details card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          if (_professional!.bio != null) ...[
                            const SizedBox(height: 8),
                            Text(_professional!.bio!),
                          ],
                          const Divider(height: 24),
                          _infoRow(Icons.work_history, 'Experience', '${_professional!.yearsOfExperience ?? 0} years'),
                          _infoRow(Icons.attach_money, 'Pricing', _professional!.pricingEstimate ?? 'Contact for quote'),
                          _infoRow(Icons.location_on, 'Location', _professional!.location ?? 'Not specified'),
                          _infoRow(Icons.timer, 'Response Time', _professional!.responseTimeHours != null ? '${_professional!.responseTimeHours!.toStringAsFixed(0)}h' : 'N/A'),
                          _infoRow(Icons.check_circle, 'Completed Jobs', '${_professional!.completedJobs}'),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Categories
                    if (_professional!.categories.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Services', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _professional!.categories.map((c) => Chip(label: Text(c.name))).toList(),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Reviews
                    Text('Reviews (${_reviews.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_reviews.isEmpty)
                      const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No reviews yet'))))
                    else
                      ..._reviews.map((r) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              CircleAvatar(radius: 16, child: Text((r.reviewerName ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 12))),
                              const SizedBox(width: 10),
                              Expanded(child: Text(r.reviewerName ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.w600))),
                              Text(DateFormat.yMMMd().format(r.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ]),
                            const SizedBox(height: 8),
                            RatingBarIndicator(rating: r.rating.toDouble(), itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber), itemSize: 16),
                            if (r.comment != null) ...[const SizedBox(height: 6), Text(r.comment!)],
                          ]),
                        ),
                      )),
                  ],
                ),
      floatingActionButton: _professional != null
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact request feature coming soon!')));
              },
              icon: const Icon(Icons.message),
              label: const Text('Contact'),
            )
          : null,
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(child: Text(value)),
      ]),
    );
  }
}
