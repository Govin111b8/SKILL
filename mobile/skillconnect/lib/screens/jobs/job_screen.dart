import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';

/// Job screen — post gigs and browse available jobs by skill/location/salary.
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

  // Post a job form
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
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadJobs();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _loading = true);
    try {
      await ApiService.get('/quotes', auth: true);
    } catch (_) {}
    // Use sample jobs for now
    if (mounted) setState(() => _loading = false);
  }

  List<_Job> get _filteredJobs {
    return _sampleJobs.where((j) {
      if (_filterCategory != 'All' && j.category != _filterCategory) return false;
      return true;
    }).toList();
  }

  Future<void> _postJob() async {
    if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Fill in title and description'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _posting = true);
    try {
      await ApiService.post('/quotes/request', {
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'service_mode': 'on_demand',
        'budget': _budgetCtrl.text.isEmpty ? null : _budgetCtrl.text,
        'category': _postCategory,
      }, auth: true);
      if (mounted) {
        _titleCtrl.clear();
        _descCtrl.clear();
        _budgetCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Job posted! Professionals will apply shortly.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        _tabCtrl.animateTo(0); // Switch to Browse tab
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) setState(() => _posting = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthService>();
    final filtered = _filteredJobs;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.tileJob,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
              title: const Text('Jobs & Gigs', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00796B), Color(0xFF00574B)],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 24),
                    child: Text('💼', style: TextStyle(fontSize: 72)),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Browse Jobs'),
                Tab(text: 'Post a Job'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            // ── Browse Jobs tab ──────────────────────────────────
            Column(
              children: [
                // Filters
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final selected = cat == _filterCategory;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _filterCategory = cat);
                        },
                        child: AnimatedContainer(
                          duration: AppDurations.normal,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.tileJob : (isDark ? AppColors.cardDark : Colors.white),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: selected ? AppColors.tileJob : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Job list
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? Center(
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                const Text('💼', style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 12),
                                Text('No jobs in this category', style: Theme.of(context).textTheme.bodyMedium),
                              ]),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final job = filtered[i];
                                return Container(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                    boxShadow: AppShadows.sm(Colors.black),
                                  ),
                                  child: Row(children: [
                                    Container(
                                      width: 52, height: 52,
                                      decoration: BoxDecoration(
                                        color: AppColors.tileJob.withAlpha(20),
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                      ),
                                      child: Center(child: Text(job.emoji, style: const TextStyle(fontSize: 24))),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(job.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                        const SizedBox(height: 2),
                                        Text(job.category, style: TextStyle(fontSize: 12, color: AppColors.tileJob, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          const Icon(Icons.location_on_rounded, size: 12, color: Colors.grey),
                                          const SizedBox(width: 2),
                                          Text(job.location, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.schedule_rounded, size: 12, color: Colors.grey),
                                          const SizedBox(width: 2),
                                          Text(job.duration, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                        ]),
                                      ]),
                                    ),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      Text(job.salary, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.tileJob)),
                                      const SizedBox(height: 6),
                                      ElevatedButton(
                                        onPressed: () {
                                          HapticFeedback.mediumImpact();
                                          Navigator.pushNamed(context, '/instant-quote');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.tileJob,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          auth.isProfessional ? 'Apply' : 'Hire',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                        ),
                                      ),
                                    ]),
                                  ]),
                                );
                              },
                            ),
                ),
              ],
            ),

            // ── Post a Job tab ───────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Post a Job', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Verified professionals will apply within minutes',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Job Title',
                      hintText: 'e.g. Fix bathroom tap',
                      prefixIcon: const Icon(Icons.title_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _postCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: const Icon(Icons.category_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    items: _categories
                        .where((c) => c != 'All')
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _postCategory = v ?? _postCategory),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the work in detail...',
                      prefixIcon: const Icon(Icons.description_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _budgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Budget (₹)',
                      hintText: 'e.g. 500 or leave blank',
                      prefixIcon: const Icon(Icons.currency_rupee_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _posting ? null : _postJob,
                      icon: _posting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.post_add_rounded),
                      label: Text(_posting ? 'Posting...' : 'Post Job',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tileJob,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Job {
  final String title;
  final String category;
  final String salary;
  final String location;
  final String emoji;
  final String duration;
  const _Job(this.title, this.category, this.salary, this.location, this.emoji, this.duration);
}
