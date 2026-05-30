import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Map<String, dynamic>> _browseProjects = [];
  List<Map<String, dynamic>> _myProjects = [];
  bool _loading = true;
  String? _error;
  String _category = 'All';
  String _budget = 'All';

  static const _categories = [
    'All',
    'Home Services',
    'Beauty',
    'Fitness',
    'Tutoring'
  ];
  static const _budgets = ['All', 'Under ₹5k', '₹5k-₹20k', '₹20k+'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final browseRes =
          await ApiService.get('/marketplace', queryParams: _query());
      _browseProjects = _extractList(browseRes);
      try {
        final myRes = await ApiService.get('/marketplace',
            auth: true, queryParams: {..._query(), 'mine': 'true'});
        _myProjects = _extractList(myRes);
      } catch (_) {
        _myProjects = [];
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Map<String, String> _query() {
    final query = <String, String>{};
    if (_category != 'All') query['category'] = _category;
    if (_budget != 'All') query['budget_range'] = _budget;
    return query;
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> res) {
    final data = res['data'];
    final list = data is List
        ? data
        : data is Map<String, dynamic>
            ? (data['items'] as List? ??
                data['projects'] as List? ??
                const [])
            : const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _showMilestones(Map<String, dynamic> project) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: ApiService.get(
              '/marketplace/${project['id']}/milestones',
              auth: true),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.xxxl),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Text(
                    'Could not load milestones: ${snapshot.error}'),
              );
            }
            final data = snapshot.data?['data'];
            final milestones = data is List
                ? data
                : data is Map<String, dynamic>
                    ? (data['items'] as List? ??
                        data['milestones'] as List? ??
                        const [])
                    : const [];
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                    Text(
                      project['title']?.toString() ?? 'Project',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ...milestones.map((item) {
                      final milestone =
                          Map<String, dynamic>.from(item as Map);
                      final status =
                          (milestone['status'] ?? 'pending').toString();
                      final progress = ((milestone['progress'] ??
                              (status == 'completed'
                                  ? 1
                                  : status == 'in_progress'
                                      ? .6
                                      : .15)) as num)
                          .toDouble();
                      final color = status == 'completed'
                          ? AppColors.success
                          : status == 'in_progress'
                              ? AppColors.primary
                              : AppColors.warning;
                      return PremiumGlassCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                  child: Text(
                                    milestone['title']?.toString() ??
                                        'Milestone',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                PremiumStatusPill(
                                  label: status.replaceAll('_', ' '),
                                  color: color,
                                ),
                              ]),
                              const SizedBox(height: AppSpacing.md),
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                child: LinearProgressIndicator(
                                  value: progress.clamp(0, 1).toDouble(),
                                  minHeight: 8,
                                  color: color,
                                  backgroundColor: color.withAlpha(25),
                                ),
                              ),
                            ]),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isProfessional = auth.isProfessional;
    final canPostProject = !isProfessional;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      floatingActionButton: canPostProject
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pushNamed(context, '/marketplace/post'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Post Project',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(context),
              _buildFilterChips(),
              _buildPremiumTabBar(),
              Expanded(
                child: _loading
                    ? const PremiumLoadingList(
                        itemCount: 4, itemHeight: 130)
                    : _error != null
                        ? RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(children: [
                              PremiumEmptyState(
                                icon: Icons.error_outline_rounded,
                                title: 'Marketplace unavailable',
                                subtitle: _error!,
                                actionLabel: 'Retry',
                                onAction: _load,
                                gradient: const [
                                  AppColors.error,
                                  Color(0xFFFF6B6B)
                                ],
                              ),
                            ]),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _ProjectList(
                                projects: _browseProjects,
                                isProfessional: isProfessional,
                                onRefresh: _load,
                                onTap: _showMilestones,
                              ),
                              _ProjectList(
                                projects: _myProjects,
                                isProfessional: isProfessional,
                                onRefresh: _load,
                                onTap: _showMilestones,
                              ),
                            ],
                          ),
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
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          style: IconButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(20)),
        ),
        const SizedBox(width: AppSpacing.md),
        const Expanded(
          child: Text(
            'Marketplace',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5),
          ),
        ),
      ]),
    );
  }

  Widget _buildFilterChips() {
    final allFilters = [
      ..._categories.map((c) => (c, true)),
      ..._budgets.map((b) => (b, false)),
    ];
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        scrollDirection: Axis.horizontal,
        itemCount: allFilters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final (label, isCategory) = allFilters[i];
          final selected =
              isCategory ? _category == label : _budget == label;
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isCategory) {
                  _category = label;
                } else {
                  _budget = label;
                }
              });
              _load();
            },
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: AppColors.primaryGradient)
                    : null,
                color: selected ? null : Colors.white.withAlpha(60),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : Colors.grey.withAlpha(50),
                ),
                boxShadow:
                    selected ? AppShadows.sm(AppColors.primary) : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(60),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
              colors: AppColors.primaryGradient),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.sm(AppColors.primary),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(text: 'Browse Projects'),
          Tab(text: 'My Projects'),
        ],
      ),
    );
  }
}

class _ProjectList extends StatelessWidget {
  final List<Map<String, dynamic>> projects;
  final bool isProfessional;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Map<String, dynamic>) onTap;

  const _ProjectList(
      {required this.projects,
      required this.isProfessional,
      required this.onRefresh,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(children: const [
          PremiumEmptyState(
            icon: Icons.work_outline_rounded,
            title: 'No projects found',
            subtitle:
                'Try another filter or come back later for new project requests.',
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 100),
        itemCount: projects.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final project = projects[index];
          final bidCount = (project['bid_count'] ?? 0) as num;
          return PremiumGlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            onTap: () => onTap(project),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: AppColors.primaryGradient),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Icon(Icons.work_outline_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      project['title']?.toString() ?? 'Project',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isProfessional)
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: AppColors.primaryGradient),
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(context,
                            '/marketplace/${project['id']}/bid'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Bid',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                    )
                  else
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.primary),
                ]),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _ProjectChip(
                      icon: Icons.category_rounded,
                      label: project['category']?.toString() ?? 'General',
                      color: AppColors.primary,
                    ),
                    _ProjectChip(
                      icon: Icons.currency_rupee_rounded,
                      label: project['budget_range']?.toString() ??
                          'Budget on request',
                      color: AppColors.success,
                    ),
                    _ProjectChip(
                      icon: Icons.location_on_rounded,
                      label:
                          project['location']?.toString() ?? 'Remote',
                      color: AppColors.secondary,
                    ),
                    _ProjectChip(
                      icon: Icons.timer_rounded,
                      label:
                          'Deadline: ${project['deadline'] ?? 'Flexible'}',
                      color: AppColors.warning,
                    ),
                    _ProjectChip(
                      icon: Icons.gavel_rounded,
                      label: '$bidCount bids',
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProjectChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ProjectChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}
