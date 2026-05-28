import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/skeleton_loader.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Map<String, dynamic>> _browseProjects = [];
  List<Map<String, dynamic>> _myProjects = [];
  bool _loading = true;
  String? _error;
  String _category = 'All';
  String _budget = 'All';

  static const _categories = ['All', 'Home Services', 'Beauty', 'Fitness', 'Tutoring'];
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
      final browseRes = await ApiService.get('/marketplace', auth: true, queryParams: _query());
      final myRes = await ApiService.get('/marketplace', auth: true, queryParams: {..._query(), 'mine': 'true'});
      _browseProjects = _extractList(browseRes);
      _myProjects = _extractList(myRes);
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
            ? (data['items'] as List? ?? data['projects'] as List? ?? const [])
            : const [];
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _showMilestones(Map<String, dynamic> project) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FutureBuilder<Map<String, dynamic>>(
        future: ApiService.get('/marketplace/${project['id']}/milestones', auth: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load milestones: ${snapshot.error}'),
            );
          }
          final data = snapshot.data?['data'];
          final milestones = data is List
              ? data
              : data is Map<String, dynamic>
                  ? (data['items'] as List? ?? data['milestones'] as List? ?? const [])
                  : const [];
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project['title']?.toString() ?? 'Project', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  ...milestones.map((item) {
                    final milestone = Map<String, dynamic>.from(item as Map);
                    final status = (milestone['status'] ?? 'pending').toString();
                    final progress = ((milestone['progress'] ?? (status == 'completed' ? 1 : status == 'in_progress' ? .6 : .15)) as num).toDouble();
                    final color = status == 'completed' ? Colors.green : status == 'in_progress' ? Theme.of(context).colorScheme.primary : Colors.orange;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(milestone['title']?.toString() ?? 'Milestone', style: const TextStyle(fontWeight: FontWeight.w700))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(18)),
                            child: Text(status.replaceAll('_', ' '), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 8, borderRadius: BorderRadius.circular(999), color: color),
                      ]),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isProfessional = auth.isProfessional;
    final canPostProject = !isProfessional;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Browse Projects'), Tab(text: 'My Projects')],
        ),
      ),
      floatingActionButton: canPostProject
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/marketplace/post'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Post Project'),
            )
          : null,
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              children: [
                ..._categories.map((item) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(item),
                        selected: _category == item,
                        onSelected: (_) {
                          setState(() => _category = item);
                          _load();
                        },
                      ),
                    )),
                ..._budgets.map((item) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(item),
                        selected: _budget == item,
                        onSelected: (_) {
                          setState(() => _budget = item);
                          _load();
                        },
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: List.generate(4, (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: SkeletonBookingCard())),
                  )
                : _error != null
                    ? RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(children: [
                          EmptyStateWidget(
                            icon: Icons.error_outline_rounded,
                            iconColor: Colors.red,
                            title: 'Marketplace unavailable',
                            subtitle: _error!,
                            actionLabel: 'Retry',
                            onAction: _load,
                          ),
                        ]),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _ProjectList(projects: _browseProjects, isProfessional: isProfessional, onRefresh: _load, onTap: _showMilestones),
                          _ProjectList(projects: _myProjects, isProfessional: isProfessional, onRefresh: _load, onTap: _showMilestones),
                        ],
                      ),
          ),
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

  const _ProjectList({required this.projects, required this.isProfessional, required this.onRefresh, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(children: const [
          EmptyStateWidget(
            icon: Icons.work_outline_rounded,
            title: 'No projects found',
            subtitle: 'Try another filter or come back later for new project requests.',
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              onTap: () => onTap(project),
              title: Text(project['title']?.toString() ?? 'Project', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(project['category']?.toString() ?? 'General'),
                  const SizedBox(height: 6),
                  Text('${project['budget_range'] ?? 'Budget on request'} • ${project['location'] ?? 'Remote'}'),
                  const SizedBox(height: 6),
                  Text('Deadline: ${project['deadline'] ?? 'Flexible'} • ${project['bid_count'] ?? 0} bids'),
                ]),
              ),
              trailing: isProfessional
                  ? OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/marketplace/${project['id']}/bid'),
                      child: const Text('Place Bid'),
                    )
                  : const Icon(Icons.chevron_right_rounded),
            ),
          );
        },
      ),
    );
  }
}
