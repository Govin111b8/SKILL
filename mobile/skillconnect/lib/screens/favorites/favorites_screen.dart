import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/booking_service.dart';
import '../../widgets/professional_card.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Professional> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await NotificationsService.listFavorites();
      _items = raw
          .map((e) =>
              Professional.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _loading
                    ? const PremiumLoadingList(
                        itemCount: 5, itemHeight: 110)
                    : _error != null
                        ? _buildError()
                        : _items.isEmpty
                            ? _buildEmpty()
                            : _buildList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      child: Row(children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          style: IconButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(20)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saved Professionals',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5),
              ),
              Text(
                '${_items.length} saved',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFFF4081)]),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.sm(const Color(0xFFFF4081)),
          ),
          child: const Icon(Icons.favorite_rounded,
              color: Colors.white, size: 20),
        ),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: PremiumGlassCard(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.lg),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: AppSpacing.lg),
            PremiumGradientButton(
              label: 'Retry',
              onPressed: _load,
              icon: Icons.refresh_rounded,
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: PremiumEmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'No favorites yet',
        subtitle:
            'Tap the heart on any professional to save them here.',
        gradient: [Color(0xFFFF6B9D), Color(0xFFFF4081)],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
        itemCount: _items.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) => Dismissible(
          key: ValueKey(_items[i].id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.xxl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), AppColors.error]),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(Icons.heart_broken_rounded,
                color: Colors.white, size: 28),
          ),
          confirmDismiss: (_) async {
            try {
              await NotificationsService.toggleFavorite(_items[i].id);
              return true;
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('$e'),
                    backgroundColor: Colors.red));
              }
              return false;
            }
          },
          onDismissed: (_) {
            setState(() => _items.removeAt(i));
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Removed from favorites')));
          },
          child: ProfessionalCard(professional: _items[i]),
        ),
      ),
    );
  }
}
