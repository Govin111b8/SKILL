import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/booking_service.dart';
import '../../widgets/book_now_sheet.dart';
import '../report/report_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../bookings/booking_detail_screen.dart';
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

  void _showContactSheet(BuildContext context) {
    final p = _professional!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Contact ${p.name}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (p.email != null)
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.phone)),
              title: const Text('Call Directly'),
              subtitle: const Text('Make a phone call'),
              onTap: () async {
                Navigator.pop(context);
                final url = Uri.parse('tel:${p.email}');
                if (await canLaunchUrl(url)) await launchUrl(url);
              },
            ),
          ListTile(
            leading: CircleAvatar(backgroundColor: Colors.green.shade100, child: const Icon(Icons.chat, color: Colors.green)),
            title: const Text('WhatsApp'),
            subtitle: const Text('Chat on WhatsApp'),
            onTap: () async {
              Navigator.pop(context);
              final msg = Uri.encodeComponent('Hi ${p.name}, I found you on SkillConnect and I\'m interested in your services.');
              final url = Uri.parse('https://wa.me/?text=$msg');
              if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
            },
          ),
          ListTile(
            leading: CircleAvatar(backgroundColor: Colors.blue.shade100, child: Icon(Icons.request_quote, color: Colors.blue.shade700)),
            title: const Text('Request Quote'),
            subtitle: const Text('Get a custom estimate'),
            onTap: () {
              Navigator.pop(context);
              _showQuoteDialog(context);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showQuoteDialog(BuildContext context) {
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Request a Quote'),
        content: TextField(
          controller: msgCtrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Describe what you need...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (msgCtrl.text.trim().length < 10) return;
              try {
                await ApiService.post('/contacts', {
                  'professional_id': _professional!.id,
                  'contact_type': 'quote_request',
                  'message': msgCtrl.text.trim(),
                }, auth: true);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quote request sent!'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
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
    try {
      final t = await MessagingService.openThread(professionalId: _professional!.id);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatScreen(threadId: t.id, otherName: _professional!.name),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _openBookingSheet(BuildContext context) async {
    final p = _professional!;
    await showBookNowSheet(
      context,
      professionalId: p.id,
      professionalName: p.name,
      categories: p.categories.map((c) => {'id': c.id, 'name': c.name}).toList(),
    );
  }
}

    final descCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    DateTime? preferred;
    int? categoryId;
    final p = _professional!;
    if (p.categories.length == 1) categoryId = p.categories.first.id;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(builder: (_, setSheetState) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          Text('Book ${p.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (p.categories.length > 1) ...[
            DropdownButtonFormField<int>(
              value: categoryId,
              decoration: const InputDecoration(labelText: 'Service category'),
              items: p.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setSheetState(() => categoryId = v),
            ),
            const SizedBox(height: 12),
          ],
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'What do you need? *', hintText: 'e.g. Fix kitchen sink leak')),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', hintText: 'More details...')),
          const SizedBox(height: 12),
          TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Service address (optional)')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final d = await showDatePicker(context: sheetCtx,
                  firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDate: DateTime.now().add(const Duration(days: 1)));
              if (d != null) setSheetState(() => preferred = d);
            },
            icon: const Icon(Icons.event),
            label: Text(preferred == null ? 'Preferred date (optional)' : DateFormat('MMM d, y').format(preferred!)),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              if (titleCtrl.text.trim().length < 5) {
                ScaffoldMessenger.of(sheetCtx).showSnackBar(const SnackBar(content: Text('Please enter what you need (5+ chars)')));
                return;
              }
              try {
                final booking = await BookingService.create(
                  professionalId: p.id,
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  serviceAddress: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                  categoryId: categoryId,
                  preferredDate: preferred,
                );
                if (!sheetCtx.mounted) return;
                Navigator.pop(sheetCtx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Booking request sent!'), backgroundColor: Colors.green));
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => BookingDetailScreen(bookingId: booking.id)));
              } catch (e) {
                if (!sheetCtx.mounted) return;
                ScaffoldMessenger.of(sheetCtx).showSnackBar(SnackBar(
                    content: Text('$e'), backgroundColor: Colors.red));
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Send Booking Request'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () { Navigator.pop(sheetCtx); _showContactSheet(context); },
            icon: const Icon(Icons.alternate_email, size: 18),
            label: const Text('Other contact options'),
          ),
        ])),
      ),
    );
  }
}
