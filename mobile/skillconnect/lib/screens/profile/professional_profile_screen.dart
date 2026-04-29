import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/booking_service.dart';
import '../../widgets/book_now_sheet.dart';
import '../report/report_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../messages/chat_screen.dart';
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
  List<PortfolioItem> _portfolio = [];
  bool _loading = true;
  bool _favorited = false;
  bool _favBusy = false;
  String? _error;
  String _presenceStatus = 'offline'; // real-time presence
  Map<int, int> _ratingDist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

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
        ApiService.get('/portfolio/${widget.professionalId}'),
      ]);
      _professional = Professional.fromJson(results[0]['data']);
      _reviews = (results[1]['data'] as List).map((e) => Review.fromJson(e)).toList();
      _portfolio = (results[2]['data'] as List).map((e) => PortfolioItem.fromJson(e)).toList();
      // Best-effort: check if favorited (silent on error — e.g. customer not logged in)
      try {
        final favs = await NotificationsService.listFavorites();
        _favorited = favs.any((f) => (f as Map)['id']?.toString() == widget.professionalId);
      } catch (_) {}
      // Best-effort: check real-time presence
      try {
        final pres = await ApiService.get('/professionals/${widget.professionalId}/presence');
        _presenceStatus = (pres['data']?['status'] ?? 'offline').toString();
      } catch (_) {}
      // Best-effort: rating distribution
      try {
        final dist = await ApiService.get('/reviews/${widget.professionalId}/distribution');
        final d = dist['data'] as Map<String, dynamic>? ?? {};
        _ratingDist = {for (final e in d.entries) int.parse(e.key): (e.value as num).toInt()};
      } catch (_) {}
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleFavorite() async {
    if (_favBusy || _professional == null) return;
    setState(() => _favBusy = true);
    try {
      final newState = await NotificationsService.toggleFavorite(_professional!.id);
      if (!mounted) return;
      setState(() => _favorited = newState);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newState ? 'Added to favorites' : 'Removed from favorites'),
        duration: const Duration(seconds: 1),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$e'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _favBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Professional Profile'), actions: [
        if (_professional != null)
          IconButton(
            tooltip: 'Share Profile',
            onPressed: () {
              final p = _professional!;
              final text = '${p.name} on SkillConnect\n'
                  '${p.headline ?? ''}\n'
                  '⭐ ${p.averageRating.toStringAsFixed(1)} (${p.reviewCount} reviews)\n'
                  '📍 ${p.location ?? 'N/A'}\n\n'
                  'Check them out on SkillConnect!';
              Share.share(text);
            },
            icon: const Icon(Icons.share),
          ),
        if (_professional != null)
          IconButton(
            tooltip: _favorited ? 'Remove from favorites' : 'Add to favorites',
            onPressed: _favBusy ? null : _toggleFavorite,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _favorited ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(_favorited),
                color: _favorited ? Colors.red : null,
              ),
            ),
          ),
      ]),
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
                          if (_professional!.availabilityStatus != null || _presenceStatus == 'online')
                            Chip(
                              avatar: Icon(Icons.circle, size: 10, color: _presenceStatus == 'online' ? Colors.green : (_professional!.availabilityStatus == 'available' ? Colors.green : Colors.orange)),
                              label: Text(_presenceStatus == 'online' ? 'ONLINE NOW' : _professional!.availabilityStatus!.toUpperCase(), style: const TextStyle(fontSize: 11)),
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
                    // Portfolio preview
                    if (_portfolio.isNotEmpty) ...[
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Portfolio (${_portfolio.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => PortfolioScreen(professionalId: widget.professionalId),
                          )),
                          child: const Text('View All'),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _portfolio.length.clamp(0, 5),
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final item = _portfolio[i];
                            return Container(
                              width: 160,
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withAlpha(60),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Expanded(
                                  child: Container(
                                    width: 160,
                                    color: cs.primaryContainer.withAlpha(100),
                                    child: item.mediaUrl.startsWith('http')
                                        ? Image.network(item.mediaUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Icon(_portfolioIcon(item.mediaType), color: cs.primary)))
                                        : Center(child: Icon(_portfolioIcon(item.mediaType), size: 32, color: cs.primary)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                ),
                              ]),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Reviews
                    Text('Reviews (${_reviews.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // Rating breakdown
                    if (_reviews.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(children: [
                            for (int star = 5; star >= 1; star--)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(children: [
                                  Text('$star', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star, size: 14, color: Colors.amber),
                                  const SizedBox(width: 8),
                                  Expanded(child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _reviews.isEmpty ? 0 : (_ratingDist[star] ?? 0) / _reviews.length,
                                      minHeight: 8,
                                      backgroundColor: cs.surfaceContainerHighest,
                                      color: star >= 4 ? Colors.green : (star == 3 ? Colors.amber : Colors.red.shade400),
                                    ),
                                  )),
                                  const SizedBox(width: 8),
                                  SizedBox(width: 24, child: Text('${_ratingDist[star] ?? 0}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.end)),
                                ]),
                              ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
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
                    const SizedBox(height: 16),
                    // Report button
                    if (_professional!.userId != null)
                      Center(
                        child: TextButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ReportScreen(reportedUserId: _professional!.userId!, reportedUserName: _professional!.name),
                          )),
                          icon: Icon(Icons.flag_outlined, color: Colors.grey.shade500, size: 18),
                          label: Text('Report this professional', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
      floatingActionButton: _professional != null
          ? Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
              FloatingActionButton.small(
                heroTag: 'chat-pro',
                onPressed: () => _openChat(context),
                tooltip: 'Chat',
                child: const Icon(Icons.chat_bubble_outline),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.extended(
                heroTag: 'book-pro',
                onPressed: () => _openBookingSheet(context),
                icon: const Icon(Icons.event_note),
                label: const Text('Book Now'),
              ),
            ])
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

  IconData _portfolioIcon(String type) {
    switch (type) {
      case 'video': return Icons.videocam;
      case 'certificate': return Icons.verified;
      default: return Icons.image;
    }
  }

  Future<void> _openChat(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final t = await MessagingService.openThread(professionalId: _professional!.id);
      if (!mounted) return;
      Navigator.push(this.context, MaterialPageRoute(
        builder: (_) => ChatScreen(threadId: t.id, otherName: _professional!.name),
      ));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _openBookingSheet(BuildContext context) async {
    final p = _professional!;
    await showBookNowSheet(
      this.context,
      professionalId: p.id,
      professionalName: p.name,
      categories: p.categories.map((c) => {'id': c.id, 'name': c.name}).toList(),
    );
  }
}
