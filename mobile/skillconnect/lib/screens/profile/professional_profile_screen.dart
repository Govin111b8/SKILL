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
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PremiumAppBar(
        title: 'Professional Profile',
        actions: [
          if (_professional != null)
            IconButton(
              tooltip: 'Share Profile',
              onPressed: () {
                final p = _professional!;
                final text = '${p.name} on SkillConnect
'
                    '${p.headline ?? ''}
'
                    '⭐ ${p.averageRating.toStringAsFixed(1)} (${p.reviewCount} reviews)
'
                    '📍 ${p.location ?? 'N/A'}

'
                    'Check them out on SkillConnect!';
                Share.share(text);
              },
              icon: const Icon(Icons.share_rounded),
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
        ],
      ),
      body: PremiumBackground(
        child: SafeArea(
          top: false,
          child: _loading
              ? const PremiumLoadingList(itemCount: 4, itemHeight: 160)
              : _error != null
                  ? PremiumEmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Unable to load profile',
                      subtitle: _error!,
                      actionLabel: 'Retry',
                      onAction: _load,
                      gradient: AppColors.warmGradient,
                    )
                  : _buildContent(context),
        ),
      ),
      floatingActionButton: _professional != null
          ? Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
              FloatingActionButton.small(
                heroTag: 'chat-pro',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                onPressed: () => _openChat(context),
                tooltip: 'Chat',
                child: const Icon(Icons.chat_bubble_outline),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.extended(
                heroTag: 'book-pro',
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: () => _openBookingSheet(context),
                icon: const Icon(Icons.event_note),
                label: const Text('Book Now'),
              ),
            ])
          : null,
    );
  }

  Widget _buildContent(BuildContext context) {
    final professional = _professional!;
    final presenceColor = _presenceStatus == 'online'
        ? AppColors.success
        : (professional.availabilityStatus == 'available' ? AppColors.success : AppColors.warning);
    final statusLabel = _presenceStatus == 'online'
        ? 'Online now'
        : (professional.availabilityStatus ?? 'Offline');

    final badges = <Widget>[
      PremiumStatChip(
        label: '${professional.averageRating.toStringAsFixed(1)} rating',
        icon: Icons.star_rounded,
        color: Colors.amber.shade200,
      ),
      PremiumStatChip(
        label: '${professional.completedJobs} jobs',
        icon: Icons.workspace_premium_rounded,
        color: Colors.white,
      ),
      PremiumStatChip(
        label: professional.responseTimeHours != null
            ? '${professional.responseTimeHours!.toStringAsFixed(0)}h reply'
            : 'Responsive',
        icon: Icons.flash_on_rounded,
        color: Colors.white,
      ),
    ];

    if (professional.averageRating >= 4.8 && professional.reviewCount >= 10) {
      badges.add(const PremiumStatChip(
        label: 'Top Rated',
        icon: Icons.shield_rounded,
        color: Color(0xFFFDE68A),
      ));
    }

    return ListView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xEE312E81), Color(0xEE4F46E5), Color(0xEE8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            boxShadow: AppShadows.lg(AppColors.primary),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.white, Color(0xFFE9D5FF)]),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.white.withAlpha(28),
                        child: Text(
                          professional.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PremiumStatusPill(
                            label: statusLabel.toUpperCase(),
                            color: presenceColor,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            professional.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                              letterSpacing: -0.6,
                            ),
                          ),
                          if (professional.headline != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              professional.headline!,
                              style: TextStyle(
                                color: Colors.white.withAlpha(220),
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(
                        value: professional.averageRating.toStringAsFixed(1),
                        label: 'Avg rating',
                        icon: Icons.star_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _HeroStat(
                        value: '${professional.reviewCount}',
                        label: 'Reviews',
                        icon: Icons.rate_review_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _HeroStat(
                        value: '${professional.completedJobs}',
                        label: 'Jobs done',
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: badges),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PremiumSectionTitle(
          title: 'About',
          subtitle: 'A trusted professional snapshot before you book.',
        ),
        PremiumGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (professional.bio != null && professional.bio!.trim().isNotEmpty) ...[
                Text(
                  professional.bio!,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 14,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              _infoRow(Icons.work_history_rounded, 'Experience', '${professional.yearsOfExperience ?? 0} years'),
              _infoRow(Icons.currency_rupee_rounded, 'Pricing', professional.pricingEstimate ?? 'Contact for quote'),
              _infoRow(Icons.location_on_rounded, 'Location', professional.location ?? 'Not specified'),
              _infoRow(
                Icons.timer_outlined,
                'Response Time',
                professional.responseTimeHours != null ? '${professional.responseTimeHours!.toStringAsFixed(0)}h' : 'N/A',
              ),
              _infoRow(Icons.verified_user_outlined, 'Completed Jobs', '${professional.completedJobs}'),
            ],
          ),
        ),
        if (professional.categories.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const PremiumSectionTitle(
            title: 'Services',
            subtitle: 'What this professional is known for.',
          ),
          PremiumGlassCard(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: professional.categories
                  .map((c) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary.withAlpha(18), AppColors.accent.withAlpha(12)],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.primary.withAlpha(35)),
                        ),
                        child: Text(
                          c.name,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        PremiumSectionTitle(
          title: 'Portfolio',
          subtitle: 'Recent work and proof of quality.',
          trailing: _portfolio.isEmpty
              ? null
              : TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PortfolioScreen(professionalId: widget.professionalId),
                  )),
                  child: const Text('View all'),
                ),
        ),
        if (_portfolio.isEmpty)
          const PremiumEmptyState(
            icon: Icons.photo_library_outlined,
            title: 'Portfolio coming soon',
            subtitle: 'This professional has not added showcase media yet.',
          )
        else
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _portfolio.length.clamp(0, 5),
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, i) {
                final item = _portfolio[i];
                return SizedBox(
                  width: 180,
                  child: PremiumGlassCard(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primary.withAlpha(18), AppColors.accent.withAlpha(18)],
                                ),
                              ),
                              child: item.mediaUrl.startsWith('http')
                                  ? Image.network(
                                      item.mediaUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Icon(_portfolioIcon(item.mediaType), color: AppColors.primary, size: 34),
                                      ),
                                    )
                                  : Center(
                                      child: Icon(_portfolioIcon(item.mediaType), size: 34, color: AppColors.primary),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.mediaType.toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        PremiumSectionTitle(
          title: 'Reviews',
          subtitle: '${_reviews.length} verified customer impressions',
        ),
        if (_reviews.isNotEmpty)
          PremiumGlassCard(
            child: Column(
              children: [
                for (int star = 5; star >= 1; star--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        Text('$star', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.star, size: 15, color: Colors.amber),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: _reviews.isEmpty ? 0 : (_ratingDist[star] ?? 0) / _reviews.length,
                              minHeight: 9,
                              backgroundColor: Colors.grey.shade200,
                              color: star >= 4 ? AppColors.success : (star == 3 ? AppColors.warning : AppColors.error),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${_ratingDist[star] ?? 0}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (_reviews.isEmpty)
          const PremiumEmptyState(
            icon: Icons.reviews_outlined,
            title: 'No reviews yet',
            subtitle: 'The first completed booking can unlock a glowing customer story here.',
          )
        else
          ..._reviews.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: PremiumGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primary.withAlpha(18),
                            child: Text(
                              (r.reviewerName ?? '?')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.reviewerName ?? 'Anonymous',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat.yMMMd().format(r.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PremiumStatusPill(label: '${r.rating.toInt()}/5', color: AppColors.warning),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      RatingBarIndicator(
                        rating: r.rating.toDouble(),
                        itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                        itemSize: 16,
                      ),
                      if (r.comment != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          r.comment!,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )),
        if (professional.userId != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ReportScreen(reportedUserId: professional.userId!, reportedUserName: professional.name),
              )),
              icon: Icon(Icons.flag_outlined, color: Colors.grey.shade600, size: 18),
              label: Text(
                'Report this professional',
                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
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

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _HeroStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withAlpha(32)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
