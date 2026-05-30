import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';
import '../profile/professional_profile_screen.dart';

/// Neighbourhood Trust Screen — shows community trust scores for professionals
/// operating in the user's area. Trust levels: Bronze → Silver → Gold → Platinum.
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.get('/trust/neighbourhood', auth: true);
      final list = res['data'] as List? ?? const [];
      _professionals =
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (_professionals.isEmpty) _professionals = _demoData;
    } catch (_) {
      _professionals = _demoData;
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedLevel == 'all') return _professionals;
    return _professionals
        .where((p) =>
            (p['trust_level'] as String? ?? '').toLowerCase() ==
            _selectedLevel.toLowerCase())
        .toList();
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
              _buildHeroHeader(context),
              _buildPremiumTabBar(context),
              Expanded(
                child: _loading
                    ? _buildSkeletons()
                    : _error != null
                        ? _buildError()
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.lg,
                                  AppSpacing.md,
                                  AppSpacing.lg,
                                  AppSpacing.xxxl),
                              children: [
                                _TrustInfoBanner(),
                                const SizedBox(height: AppSpacing.lg),
                                ..._filtered.map(
                                  (pro) => _ProTrustCard(
                                    pro: pro,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ProfessionalProfileScreen(
                                            professionalId:
                                                pro['id'].toString(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (_filtered.isEmpty)
                                  PremiumEmptyState(
                                    icon: Icons.verified_user_outlined,
                                    title:
                                        'No ${_selectedLevel == 'all' ? '' : _selectedLevel} professionals yet',
                                    subtitle:
                                        'Professionals in your area will appear here as they build trust.',
                                  ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(20),
              foregroundColor: AppColors.surfaceDark,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Neighbourhood Trust',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '${_professionals.length} verified professionals near you',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: AppShadows.md(AppColors.primary),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('Verified',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTabBar(BuildContext context) {
    final levels = [
      ('All', null, Colors.grey),
      ('Platinum', Icons.workspace_premium, const Color(0xFF6366F1)),
      ('Gold', Icons.emoji_events, const Color(0xFFF59E0B)),
      ('Silver', Icons.star, const Color(0xFF94A3B8)),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: List.generate(levels.length, (i) {
          final (label, icon, color) = levels[i];
          final selected = _tabController.index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                _tabController.animateTo(i);
                setState(() {
                  _selectedLevel = ['all', 'Platinum', 'Gold', 'Silver'][i];
                });
              },
              child: AnimatedContainer(
                duration: AppDurations.fast,
                margin: EdgeInsets.only(right: i < levels.length - 1 ? 6 : 0),
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(
                          colors: [
                            color.withAlpha(200),
                            color.withAlpha(140)
                          ],
                        )
                      : null,
                  color: selected ? null : Colors.white.withAlpha(60),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: selected ? color : Colors.grey.withAlpha(40),
                  ),
                  boxShadow:
                      selected ? AppShadows.sm(color) : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null)
                      Icon(icon,
                          size: 14,
                          color:
                              selected ? Colors.white : color),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            selected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSkeletons() {
    return const PremiumLoadingList(itemCount: 5, itemHeight: 140);
  }

  Widget _buildError() {
    return PremiumEmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Could not load trust data',
      subtitle: _error ?? 'Something went wrong.',
      actionLabel: 'Retry',
      onAction: _load,
      gradient: const [AppColors.error, Color(0xFFFF6B6B)],
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
    return PremiumGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gradient: const [
        Color(0xFFEEF2FF),
        Color(0xFFF5F3FF),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: AppColors.primaryGradient),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              const Text(
                'How Trust Scores Work',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _TrustFactor(label: 'KYC Verification', emoji: '🪪'),
          const _TrustFactor(label: 'Experience & Completed Jobs', emoji: '🔧'),
          const _TrustFactor(label: 'Customer Ratings', emoji: '⭐'),
          const _TrustFactor(label: 'Repeat Customers', emoji: '🔁'),
          const _TrustFactor(label: 'Response Time', emoji: '⚡'),
          const _TrustFactor(
              label: 'Reliability (on-time %, no-shows)', emoji: '📍'),
        ],
      ),
    );
  }
}

class _TrustFactor extends StatelessWidget {
  final String label;
  final String emoji;
  const _TrustFactor({required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: AppSpacing.sm),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500)),
        ]),
      );
}

class _ProTrustCard extends StatelessWidget {
  final Map<String, dynamic> pro;
  final VoidCallback onTap;
  const _ProTrustCard({required this.pro, required this.onTap});

  Color _levelColor(String level) {
    switch (level) {
      case 'Platinum':
        return const Color(0xFF6366F1);
      case 'Gold':
        return const Color(0xFFF59E0B);
      case 'Silver':
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  IconData _levelIcon(String level) {
    switch (level) {
      case 'Platinum':
        return Icons.workspace_premium;
      case 'Gold':
        return Icons.emoji_events;
      case 'Silver':
        return Icons.star;
      default:
        return Icons.military_tech;
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PremiumGlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [color.withAlpha(60), color.withAlpha(20)],
                      ),
                      border: Border.all(color: color.withAlpha(80), width: 2),
                    ),
                    child: ClipOval(
                      child: pro['avatar_url'] != null
                          ? Image.network(pro['avatar_url'].toString(),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      pro['name'].toString().substring(0, 1),
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: color),
                                    ),
                                  ))
                          : Center(
                              child: Text(
                                pro['name'].toString().substring(0, 1),
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: color),
                              ),
                            ),
                    ),
                  ),
                  if (verified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 10),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pro['name'].toString(),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pro['headline']?.toString() ?? '',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.location_on_rounded,
                          size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 2),
                      Text(
                        pro['location']?.toString() ?? '',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ]),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    color.withAlpha(30),
                    color.withAlpha(15),
                  ]),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: color.withAlpha(100)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_levelIcon(level), size: 13, color: color),
                  const SizedBox(width: 4),
                  Text(
                    level,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              Text(
                'Trust Score',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '$score / 100',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: color),
              ),
            ]),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 7,
                backgroundColor: color.withAlpha(25),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              _StatChip(
                  icon: Icons.star_rounded,
                  value: rating.toStringAsFixed(1),
                  label: 'Rating',
                  color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              _StatChip(
                  icon: Icons.handyman_outlined,
                  value: '$jobs',
                  label: 'Jobs',
                  color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              _StatChip(
                  icon: Icons.repeat_rounded,
                  value: '$repeat%',
                  label: 'Repeat',
                  color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              _StatChip(
                  icon: Icons.bolt_rounded,
                  value: responseStr,
                  label: 'Response',
                  color: AppColors.secondary),
            ]),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatChip(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            color: color.withAlpha(12),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Column(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 3),
            Text(value,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
          ]),
        ),
      );
}
