import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../widgets/premium_ui.dart';

class JobScreen extends StatefulWidget {
  const JobScreen({super.key});
  @override
  State<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;
  String _filterCategory = 'All';
  String _filterSalary = 'Any';
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  String _postCategory = 'Plumbing';
  bool _posting = false;

  static const _categories = ['All', 'Plumbing', 'Electrical', 'Carpentry', 'Painting', 'Cleaning', 'Driving', 'IT/Tech', 'Teaching', 'Other'];
  static const _salaryFilters = ['Any', 'Under ₹500', '₹500–₹1000', '₹1000–₹2000', 'Above ₹2000'];
  static const _sampleJobs = [
    _Job('Fix leaking pipe', 'Plumbing', '₹500–800', 'Bangalore', '🔧', '2 hr'),
    _Job('Electrical wiring', 'Electrical', '₹1000–1500', 'Hyderabad', '⚡', '4 hr'),
    _Job('Paint 2BHK flat', 'Painting', '₹8000–12000', 'Chennai', '🎨', '3 days'),
    _Job('Deep cleaning', 'Cleaning', '₹600–900', 'Mumbai', '🧹', '1 day'),
    _Job('Corporate cab driver', 'Driving', '₹15000/mo', 'Pune', '🚗', 'Full-time'),
    _Job('Python tutor', 'IT/Tech', '₹500/hr', 'Remote', '💻', 'Part-time'),
    _Job('Maths teacher', 'Teaching', '₹300/hr', 'Delhi', '📚', 'Part-time'),
    _Job('Carpenter for furniture', 'Carpentry', '₹2000–3000', 'Kolkata', '🪚', '2 days'),
  ];

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); _loadJobs(); }

  @override
  void dispose() { _tabCtrl.dispose(); _titleCtrl.dispose(); _descCtrl.dispose(); _budgetCtrl.dispose(); super.dispose(); }

  Future<void> _loadJobs() async {
    setState(() => _loading = true);
    try { await ApiService.get('/quotes', auth: true); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<_Job> get _filteredJobs => _sampleJobs.where((j) => _filterCategory == 'All' || j.category == _filterCategory).toList();

  Future<void> _postJob() async {
    if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill in title and description'), behavior: SnackBarBehavior.floating));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _posting = true);
    try {
      await ApiService.post('/quotes/request', {
        'title': _titleCtrl.text, 'description': _descCtrl.text, 'service_mode': 'on_demand',
        'budget': _budgetCtrl.text.isEmpty ? null : _budgetCtrl.text, 'category': _postCategory,
      }, auth: true);
      if (mounted) {
        _titleCtrl.clear(); _descCtrl.clear(); _budgetCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Job posted! Professionals will apply shortly.'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
        _tabCtrl.animateTo(0);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
    if (mounted) setState(() => _posting = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final filtered = _filteredJobs;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: PremiumBackground(
        colors: const [Color(0xFFF0FFF8), Color(0xFFE8F5F0), Color(0xFFE0F5EE)],
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(
              child: PremiumHeroHeader(
                title: 'Jobs & Gigs',
                subtitle: 'Find work or hire skilled professionals',
                icon: Icons.work_rounded,
                gradient: const [Color(0xFF00796B), Color(0xFF00574B)],
                chips: [PremiumStatChip(label: '💼 ${_sampleJobs.length} Jobs', color: Colors.white), const PremiumStatChip(label: '⚡ Instant Hire', color: Colors.white)],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabDelegate(TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.tileJob,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.tileJob,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                tabs: const [Tab(text: 'Browse Jobs'), Tab(text: 'Post a Job')],
              )),
            ),
          ],
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              Column(children: [
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = _categories[i]; final selected = cat == _filterCategory;
                      return GestureDetector(
                        onTap: () { HapticFeedback.selectionClick(); setState(() => _filterCategory = cat); },
                        child: AnimatedContainer(
                          duration: AppDurations.normal,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: selected ? const LinearGradient(colors: [Color(0xFF00796B), Color(0xFF00574B)]) : null,
                            color: selected ? null : Colors.white.withAlpha(200),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: selected ? Colors.transparent : AppColors.borderLight),
                            boxShadow: selected ? AppShadows.sm(AppColors.tileJob) : null,
                          ),
                          child: Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.surfaceDark)),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _loading
                      ? PremiumLoadingList(itemCount: 4)
                      : filtered.isEmpty
                          ? PremiumEmptyState(icon: Icons.work_off_rounded, title: 'No jobs found', subtitle: 'No jobs in this category.\nTry a different filter.', gradient: const [Color(0xFF00796B), Color(0xFF00574B)])
                          : ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final job = filtered[i];
                                return PremiumGlassCard(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Row(children: [
                                    Container(width: 52, height: 52,
                                      decoration: BoxDecoration(color: AppColors.tileJob.withAlpha(30), borderRadius: BorderRadius.circular(AppRadius.lg)),
                                      child: Center(child: Text(job.emoji, style: const TextStyle(fontSize: 24)))),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(job.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                      const SizedBox(height: 2),
                                      PremiumStatusPill(label: job.category, color: AppColors.tileJob),
                                      const SizedBox(height: 6),
                                      Row(children: [
                                        const Icon(Icons.location_on_rounded, size: 12, color: Colors.grey),
                                        const SizedBox(width: 2),
                                        Text(job.location, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.schedule_rounded, size: 12, color: Colors.grey),
                                        const SizedBox(width: 2),
                                        Text(job.duration, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                      ]),
                                    ])),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      Text(job.salary, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.tileJob)),
                                      const SizedBox(height: 8),
                                      PremiumGradientButton(
                                        label: auth.isProfessional ? 'Apply' : 'Hire',
                                        colors: const [Color(0xFF00796B), Color(0xFF00574B)],
                                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                                        onPressed: () { HapticFeedback.mediumImpact(); Navigator.pushNamed(context, '/instant-quote'); },
                                      ),
                                    ]),
                                  ]),
                                );
                              },
                            ),
                ),
              ]),
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  PremiumSectionTitle(title: 'Post a Job', subtitle: 'Verified professionals apply within minutes'),
                  PremiumGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Job Title', hintText: 'e.g. Fix bathroom tap', prefixIcon: Icon(Icons.title_rounded), border: InputBorder.none)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PremiumGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: DropdownButtonFormField<String>(
                      value: _postCategory,
                      decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_rounded), border: InputBorder.none),
                      items: _categories.where((c) => c != 'All').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _postCategory = v ?? _postCategory),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PremiumGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: TextFormField(controller: _descCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Description', hintText: 'Describe the work...', prefixIcon: Icon(Icons.description_rounded), border: InputBorder.none)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PremiumGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: TextFormField(controller: _budgetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Budget (₹)', hintText: 'e.g. 500 or leave blank', prefixIcon: Icon(Icons.currency_rupee_rounded), border: InputBorder.none)),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(width: double.infinity, child: PremiumGradientButton(
                    label: _posting ? 'Posting...' : 'Post Job',
                    icon: _posting ? null : Icons.post_add_rounded,
                    colors: const [Color(0xFF00796B), Color(0xFF00574B)],
                    onPressed: _posting ? () {} : _postJob,
                  )),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabDelegate(this.tabBar);
  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: Colors.white.withAlpha(230), child: tabBar);
  @override bool shouldRebuild(_TabDelegate old) => false;
}

class _Job {
  final String title; final String category; final String salary; final String location; final String emoji; final String duration;
  const _Job(this.title, this.category, this.salary, this.location, this.emoji, this.duration);
}
