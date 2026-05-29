import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../profile/professional_profile_screen.dart';

/// Neighbourhood Trust Screen — shows community trust scores for professionals
/// operating in the user's area. Trust levels: Bronze → Silver → Gold → Platinum.
/// Multi-factor scoring: verification, experience, rating, repeat customers,
/// responsiveness, reliability.
class NeighbourhoodTrustScreen extends StatefulWidget {
  const NeighbourhoodTrustScreen({super.key});

  @override
  State<NeighbourhoodTrustScreen> createState() => _NeighbourhoodTrustScreenState();
}

class _NeighbourhoodTrustScreenState extends State<NeighbourhoodTrustScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _professionals = [];
  bool _loading = true;
  String? _error;
  String _selectedLevel = 'all';

  // Demo data — used when the API is unavailable
  static const List<Map<String, dynamic>> _demoData = [
    {
      'id': 'pro-1',
      'name': 'Ramesh Kumar',
      'headline': 'AC & Appliance Expert',
      'trust_score': 94,
      'trust_level': 'Platinum',
      'location': 'Koramangala, Bengaluru',
      'average_rating': 4.9,
      'review_count': 128,
      'completed_jobs': 312,
      'kyc_level': 3,
      'government_id_verified': true,
      'response_time_hours': 0.5,
      'repeat_customer_rate': 72,
      'avatar_url': 'https://i.pravatar.cc/150?img=11',
      'categories': [{'name': 'AC Service'}],
    },
    {
      'id': 'pro-2',
      'name': 'Suresh Nair',
      'headline': 'Master Plumber & Pipe Fitter',
      'trust_score': 87,
      'trust_level': 'Gold',
      'location': 'Indiranagar, Bengaluru',
      'average_rating': 4.7,
      'review_count': 89,
      'completed_jobs': 201,
      'kyc_level': 2,
      'government_id_verified': true,
      'response_time_hours': 1.2,
      'repeat_customer_rate': 58,
      'avatar_url': 'https://i.pravatar.cc/150?img=15',
      'categories': [{'name': 'Plumbing'}],
    },
    {
      'id': 'pro-3',
      'name': 'Priya Sharma',
      'headline': 'Beauty & Wellness Specialist',
      'trust_score': 82,
      'trust_level': 'Gold',
      'location': 'HSR Layout, Bengaluru',
      'average_rating': 4.8,
      'review_count': 203,
      'completed_jobs': 440,
      'kyc_level': 2,
      'government_id_verified': true,
      'response_time_hours': 0.8,
      'repeat_customer_rate': 81,
      'avatar_url': 'https://i.pravatar.cc/150?img=25',
      'categories': [{'name': 'Beauty'}],
    },
    {
      'id': 'pro-4',
      'name': 'Mohammed Irfan',
      'headline': 'Electrician & Wiring Specialist',
      'trust_score': 71,
      'trust_level': 'Silver',
      'location': 'Whitefield, Bengaluru',
      'average_rating': 4.5,
      'review_count': 42,
      'completed_jobs': 88,
      'kyc_level': 1,
      'government_id_verified': false,
      'response_time_hours': 2.1,
      'repeat_customer_rate': 39,
      'avatar_url': 'https://i.pravatar.cc/150?img=32',
      'categories': [{'name': 'Electrician'}],
    },
    {
      'id': 'pro-5',
      'name': 'Anita Rao',
      'headline': 'Home Cleaning & Organizer',
      'trust_score': 63,
      'trust_level': 'Silver',
      'location': 'Jayanagar, Bengaluru',
      'average_rating': 4.3,
      'review_count': 31,
      'completed_jobs': 55,
      'kyc_level': 1,
      'government_id_verified': false,
      'response_time_hours': 3.0,
      'repeat_customer_rate': 28,
      'avatar_url': 'https://i.pravatar.cc/150?img=48',
      'categories': [{'name': 'Cleaning'}],
    },
    {
      'id': 'pro-6',
      'name': 'Vijay Malhotra',
      'headline': 'Carpenter & Furniture Repair',
      'trust_score': 45,
      'trust_level': 'Bronze',
      'location': 'BTM Layout, Bengaluru',
      'average_rating': 4.0,
      'review_count': 14,
      'completed_jobs': 22,
      'kyc_level': 0,
      'government_id_verified': false,
      'response_time_hours': 5.0,
      'repeat_customer_rate': 18,
      'avatar_url': 'https://i.pravatar.cc/150?img=56',
      'categories': [{'name': 'Carpentry'}],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/trust/neighbourhood', auth: true);
      final list = res['data'] as List? ?? const [];
      _professionals = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (_professionals.isEmpty) _professionals = _demoData;
    } catch (_) {
      _professionals = _demoData;
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedLevel == 'all') return _professionals;
    return _professionals.where((p) =>
      (p['trust_level'] as String? ?? '').toLowerCase() == _selectedLevel.toLowerCase()
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Neighbourhood Trust'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (i) {
            setState(() {
              _selectedLevel = ['all', 'Platinum', 'Gold', 'Silver'][i];
            });
          },
          tabs: const [
            Tab(text: 'All'),
            Tab(child: _LevelTab(level: 'Platinum', color: Color(0xFF6366F1))),
            Tab(child: _LevelTab(level: 'Gold', color: Color(0xFFF59E0B))),
            Tab(child: _LevelTab(level: 'Silver', color: Color(0xFF94A3B8))),
          ],
        ),
      ),
      body: _loading
          ? _buildSkeletons()
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(_error!),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _TrustInfoBanner(),
                      const SizedBox(height: 16),
                      ..._filtered.map((pro) => _ProTrustCard(
                        pro: pro,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ProfessionalProfileScreen(professionalId: pro['id'].toString()),
                          ));
                        },
                      )),
                      if (_filtered.isEmpty)
                        EmptyStateWidget(
                          icon: Icons.verified_user_outlined,
                          title: 'No ${_selectedLevel == 'all' ? '' : _selectedLevel} professionals yet',
                          subtitle: 'Professionals in your area will appear here as they build trust.',
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSkeletons() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(5, (_) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: CardSkeleton(height: 120),
      )),
    );
  }
}

class _LevelTab extends StatelessWidget {
  final String level;
  final Color color;
  const _LevelTab({required this.level, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.workspace_premium, size: 14, color: color),
      const SizedBox(width: 4),
      Text(level),
    ],
  );
}

class _TrustInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How Trust Scores Work', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const _TrustFactor(label: 'KYC Verification', emoji: '🪪'),
        const _TrustFactor(label: 'Experience & Completed Jobs', emoji: '🔧'),
        const _TrustFactor(label: 'Customer Ratings', emoji: '⭐'),
        const _TrustFactor(label: 'Repeat Customers', emoji: '🔁'),
        const _TrustFactor(label: 'Response Time', emoji: '⚡'),
        const _TrustFactor(label: 'Reliability (on-time %, no-shows)', emoji: '📍'),
      ]),
    );
  }
}

class _TrustFactor extends StatelessWidget {
  final String label;
  final String emoji;
  const _TrustFactor({required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 8),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]),
  );
}

class _ProTrustCard extends StatelessWidget {
  final Map<String, dynamic> pro;
  final VoidCallback onTap;
  const _ProTrustCard({required this.pro, required this.onTap});

  Color _levelColor(String level) {
    switch (level) {
      case 'Platinum': return const Color(0xFF6366F1);
      case 'Gold': return const Color(0xFFF59E0B);
      case 'Silver': return const Color(0xFF94A3B8);
      default: return const Color(0xFFCD7F32);
    }
  }

  IconData _levelIcon(String level) {
    switch (level) {
      case 'Platinum': return Icons.workspace_premium;
      case 'Gold': return Icons.emoji_events;
      case 'Silver': return Icons.star;
      default: return Icons.military_tech;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = pro['trust_level']?.toString() ?? 'Bronze';
    final score = (pro['trust_score'] as num?)?.toInt() ?? 0;
    final color = _levelColor(level);
    final rating = (pro['average_rating'] as num?)?.toDouble() ?? 0.0;
    final jobs = (pro['completed_jobs'] as num?)?.toInt() ?? 0;
    final repeat = (pro['repeat_customer_rate'] as num?)?.toInt() ?? 0;
    final responseH = (pro['response_time_hours'] as num?)?.toDouble() ?? 0;
    final responseStr = responseH < 1
        ? '${(responseH * 60).round()} min'
        : '${responseH.toStringAsFixed(1)} h';
    final verified = pro['government_id_verified'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundImage: pro['avatar_url'] != null
                    ? NetworkImage(pro['avatar_url'].toString())
                    : null,
                child: pro['avatar_url'] == null
                    ? Text(pro['name'].toString().substring(0, 1), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(pro['name'].toString(), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  if (verified)
                    const Icon(Icons.verified, size: 16, color: Color(0xFF10B981)),
                ]),
                Text(pro['headline']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(pro['location']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
              ])),
              // Trust badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withAlpha(80)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_levelIcon(level), size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(level, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            // Trust score bar
            Row(children: [
              Text('Trust Score', style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              Text('$score / 100', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 6,
                backgroundColor: color.withAlpha(30),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 12),
            // Stats row
            Row(children: [
              _StatChip(icon: Icons.star, value: rating.toStringAsFixed(1), label: 'Rating'),
              const SizedBox(width: 8),
              _StatChip(icon: Icons.handyman_outlined, value: '$jobs', label: 'Jobs'),
              const SizedBox(width: 8),
              _StatChip(icon: Icons.repeat, value: '$repeat%', label: 'Repeat'),
              const SizedBox(width: 8),
              _StatChip(icon: Icons.bolt, value: responseStr, label: 'Response'),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatChip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        Icon(icon, size: 13, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 9)),
      ]),
    ),
  );
}
