import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../models/professional.dart';
import '../models/review.dart';

class ProfessionalProfileScreen extends StatefulWidget {
  final int professionalId;
  final AuthProvider auth;
  const ProfessionalProfileScreen({super.key, required this.professionalId, required this.auth});
  @override
  State<ProfessionalProfileScreen> createState() => _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState extends State<ProfessionalProfileScreen> with SingleTickerProviderStateMixin {
  Professional? _pro;
  List<Review> _reviews = [];
  List<PortfolioItem> _portfolio = [];
  bool _loading = true;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final proData = await ApiService.get('/professionals/${widget.professionalId}');
      final pro = Professional.fromJson(proData is Map<String, dynamic> ? proData : proData['professional'] ?? proData);

      List<Review> reviews = [];
      try {
        final revData = await ApiService.get('/reviews/${widget.professionalId}');
        final revList = revData is List ? revData : (revData['reviews'] ?? []);
        reviews = (revList as List).map((j) => Review.fromJson(j)).toList();
      } catch (_) {}

      List<PortfolioItem> portfolio = [];
      try {
        final portData = await ApiService.get('/portfolio/${widget.professionalId}');
        final portList = portData is List ? portData : (portData['portfolio'] ?? []);
        portfolio = (portList as List).map((j) => PortfolioItem.fromJson(j)).toList();
      } catch (_) {}

      setState(() { _pro = pro; _reviews = reviews; _portfolio = portfolio; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showContactDialog() {
    if (!widget.auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to contact professionals')));
      return;
    }
    final msgCtrl = TextEditingController();
    String type = 'message';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) {
        return AlertDialog(
          title: const Text('Contact Professional'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'message', label: Text('Message'), icon: Icon(Icons.message)),
                ButtonSegment(value: 'call', label: Text('Call'), icon: Icon(Icons.phone)),
                ButtonSegment(value: 'quote_request', label: Text('Quote'), icon: Icon(Icons.request_quote)),
              ],
              selected: {type},
              onSelectionChanged: (v) => setDlgState(() => type = v.first),
            ),
            const SizedBox(height: 16),
            TextField(controller: msgCtrl, decoration: const InputDecoration(labelText: 'Your message', hintText: 'Describe what you need...'), maxLines: 3),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (msgCtrl.text.trim().isEmpty) return;
                try {
                  await ApiService.post('/contacts', {
                    'professional_id': widget.professionalId,
                    'contact_type': type,
                    'message': msgCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact request sent!')));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    if (_pro == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Professional not found')));
    final p = _pro!;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: LinearGradient(colors: [cs.primary, cs.primary.withValues(alpha: 0.6)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
                    child: Column(children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white,
                        child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: cs.primary)),
                      ),
                      const SizedBox(height: 12),
                      Text(p.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onPrimary)),
                      if (p.headline.isNotEmpty) Text(p.headline, style: TextStyle(fontSize: 14, color: cs.onPrimary.withValues(alpha: 0.85))),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text('${p.averageRating.toStringAsFixed(1)} (${p.reviewCount} reviews)', style: TextStyle(color: cs.onPrimary)),
                        const SizedBox(width: 16),
                        Icon(Icons.location_on, color: cs.onPrimary.withValues(alpha: 0.7), size: 18),
                        const SizedBox(width: 2),
                        Text(p.location, style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.85), fontSize: 13)),
                      ]),
                      const SizedBox(height: 8),
                      if (p.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Text('✓ Available', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                    ]),
                  ),
                ),
              ),
            ),
            bottom: TabBar(controller: _tabCtrl, indicatorColor: cs.onPrimary, labelColor: cs.onPrimary, unselectedLabelColor: cs.onPrimary.withValues(alpha: 0.6), tabs: const [
              Tab(text: 'About'),
              Tab(text: 'Portfolio'),
              Tab(text: 'Reviews'),
            ]),
          ),
        ],
        body: TabBarView(controller: _tabCtrl, children: [
          _aboutTab(p, cs),
          _portfolioTab(),
          _reviewsTab(cs),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showContactDialog,
        icon: const Icon(Icons.message),
        label: const Text('Contact'),
      ),
    );
  }

  Widget _aboutTab(Professional p, ColorScheme cs) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Info chips
      Wrap(spacing: 8, runSpacing: 8, children: [
        _infoChip(Icons.work_history, '${p.yearsOfExperience} yrs exp'),
        _infoChip(Icons.attach_money, p.pricingEstimate),
        _infoChip(Icons.timer, '${p.responseTimeHours.toStringAsFixed(0)}h response'),
        _infoChip(Icons.check_circle, '${p.completedJobs} jobs done'),
      ]),
      const SizedBox(height: 20),
      const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(p.bio.isNotEmpty ? p.bio : 'No bio provided.', style: TextStyle(color: Colors.grey[700], height: 1.5)),
      if (p.categories.isNotEmpty) ...[
        const SizedBox(height: 20),
        const Text('Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: p.categories.map((c) => Chip(label: Text(c), backgroundColor: cs.primaryContainer)).toList()),
      ],
    ]);
  }

  Widget _infoChip(IconData icon, String text) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(text, style: const TextStyle(fontSize: 12)));
  }

  Widget _portfolioTab() {
    if (_portfolio.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text('No portfolio items yet', style: TextStyle(color: Colors.grey[600])),
      ]));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
      itemCount: _portfolio.length,
      itemBuilder: (_, i) {
        final item = _portfolio[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: Center(child: Icon(
                  item.mediaType == 'video' ? Icons.videocam : item.mediaType == 'certificate' ? Icons.verified : Icons.image,
                  size: 48, color: Colors.grey[400],
                )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(item.description, style: TextStyle(fontSize: 11, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        );
      },
    );
  }

  Widget _reviewsTab(ColorScheme cs) {
    if (_reviews.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text('No reviews yet', style: TextStyle(color: Colors.grey[600])),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (_, i) {
        final r = _reviews[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(radius: 18, child: Text(r.reviewerName.isNotEmpty ? r.reviewerName[0].toUpperCase() : '?')),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.reviewerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  RatingBarIndicator(rating: r.rating.toDouble(), itemSize: 16, itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber)),
                ])),
              ]),
              const SizedBox(height: 8),
              Text(r.comment, style: TextStyle(color: Colors.grey[700], height: 1.4)),
            ]),
          ),
        );
      },
    );
  }
}
