import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../settings/settings_screen.dart';
import '../kyc/kyc_screen.dart';
import '../contacts/my_contacts_screen.dart';
import '../profile/edit_professional_profile_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../favorites/favorites_screen.dart';
import '../bookings/service_history_screen.dart';
import '../trust/neighbourhood_trust_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _dashData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/dashboard', auth: true);
      _dashData = res['data'];
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _updateContactStatus(String contactId, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiService.put('/contacts/$contactId/status', {'status': status}, auth: true);
      _load();
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Contact ${status == 'accepted' ? 'accepted' : 'declined'}'),
          backgroundColor: status == 'accepted' ? const Color(0xFF10B981) : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final isPro = auth.isProfessional;
    final name = user?['name']?.toString() ?? 'User';
    final email = user?['email']?.toString() ?? '';
    final avatarUrl = user?['avatar_url']?.toString() ?? '';
    final isVerified = user?['is_verified'] == true;

    // Stats
    final totalBookings = (_dashData?['totalBookings'] as num?)?.toInt() ?? 0;
    final totalReviews = (_dashData?['totalReviews'] as num?)?.toInt() ?? 0;
    final points = (_dashData?['points'] as num?)?.toInt() ?? 0;
    final pendingContacts = (_dashData?['pendingContacts'] as List?) ?? [];
    final recentBookings = (_dashData?['recentBookings'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF6366F1),
        child: CustomScrollView(
          slivers: [
            // ── Collapsible Hero ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: const Color(0xFF1B6EF3),
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Colors.white),
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1B6EF3), Color(0xFF4F46E5)],
                    ),
                  ),
                  child: SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Avatar with verification ring
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isVerified)
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFFF59E0B), width: 2.5),
                                  ),
                                ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const EditProfessionalProfileScreen())),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: Colors.white, width: 2),
                                    color: Colors.white.withAlpha(30),
                                  ),
                                  child: avatarUrl.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(avatarUrl,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover),
                                        )
                                      : Center(
                                          child: Text(
                                            name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 34,
                                                fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                ),
                              ),
                              if (isVerified)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                    ),
                                    child: const Icon(Icons.star_rounded,
                                        color: Colors.white, size: 13),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(20),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withAlpha(40)),
                                ),
                                child: Text(
                                  isPro ? '🔧 Professional' : '👤 Customer',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (email.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  email,
                                  style: TextStyle(
                                      color: Colors.white.withAlpha(160),
                                      fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Stats Row ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _loading
                  ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.calendar_month_rounded,
                              color: const Color(0xFF6366F1),
                              label: 'Bookings',
                              value: '$totalBookings',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.star_rounded,
                              color: const Color(0xFFF59E0B),
                              label: 'Reviews',
                              value: '$totalReviews',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.emoji_events_rounded,
                              color: const Color(0xFF10B981),
                              label: 'Points',
                              value: '$points',
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // ── Quick Actions Grid ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _QuickActionTile(
                          icon: Icons.edit_rounded,
                          label: 'Edit Profile',
                          color: const Color(0xFF6366F1),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const EditProfessionalProfileScreen())),
                        ),
                        _QuickActionTile(
                          icon: Icons.history_rounded,
                          label: 'Bookings',
                          color: const Color(0xFF06B6D4),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ServiceHistoryScreen())),
                        ),
                        _QuickActionTile(
                          icon: Icons.photo_library_rounded,
                          label: 'Portfolio',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PortfolioScreen())),
                        ),
                        _QuickActionTile(
                          icon: Icons.favorite_rounded,
                          label: 'Favorites',
                          color: const Color(0xFFEF4444),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FavoritesScreen())),
                        ),
                        _QuickActionTile(
                          icon: Icons.verified_user_rounded,
                          label: 'KYC',
                          color: const Color(0xFF10B981),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const KycScreen())),
                        ),
                        _QuickActionTile(
                          icon: Icons.people_rounded,
                          label: 'Contacts',
                          color: const Color(0xFFF59E0B),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MyContactsScreen())),
                        ),
                        _QuickActionTile(
                          icon: Icons.location_on_rounded,
                          label: 'Trust Map',
                          color: const Color(0xFF0EA5E9),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const NeighbourhoodTrustScreen())),
                        ),
                        _QuickActionTile(
                          icon: Icons.settings_rounded,
                          label: 'Settings',
                          color: const Color(0xFF64748B),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen())),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Pending Contact Requests ──────────────────────────────
            if (pendingContacts.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Contact Requests',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${pendingContacts.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: pendingContacts.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) {
                            final c = pendingContacts[i] as Map;
                            final cName = c['name']?.toString() ?? 'User';
                            final cId = c['id']?.toString() ?? '';
                            return Container(
                              width: 200,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(8),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        const Color(0xFF6366F1).withAlpha(20),
                                    child: Text(
                                      cName.isNotEmpty
                                          ? cName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          color: Color(0xFF6366F1),
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(cName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () => _updateContactStatus(
                                                    cId, 'accepted'),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF10B981)
                                                        .withAlpha(20),
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  child: const Center(
                                                    child: Text('Accept',
                                                        style: TextStyle(
                                                            color: Color(0xFF10B981),
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w700)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () => _updateContactStatus(
                                                    cId, 'rejected'),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEF4444)
                                                        .withAlpha(20),
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  child: const Center(
                                                    child: Text('Decline',
                                                        style: TextStyle(
                                                            color: Color(0xFFEF4444),
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w700)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Recent Activity ───────────────────────────────────────
            if (recentBookings.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(6),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: List.generate(
                              recentBookings.length > 5 ? 5 : recentBookings.length,
                              (i) {
                            final b = recentBookings[i] as Map;
                            final title = b['title']?.toString() ?? 'Service';
                            final status = b['status']?.toString() ?? '';
                            final date = b['created_at']?.toString() ?? '';
                            final statusColor = _statusColor(status);
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: statusColor.withAlpha(20),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.home_repair_service_rounded,
                                            color: statusColor, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(title,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis),
                                            Text(
                                              date.length >= 10
                                                  ? date.substring(0, 10)
                                                  : date,
                                              style: const TextStyle(
                                                  color: Color(0xFF94A3B8),
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withAlpha(15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _prettyStatus(status),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (i < (recentBookings.length > 5
                                        ? 4
                                        : recentBookings.length - 1))
                                  Divider(
                                      height: 1,
                                      indent: 64,
                                      color: const Color(0xFFE2E8F0).withAlpha(200)),
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'requested':   return const Color(0xFFF59E0B);
      case 'accepted':    return const Color(0xFF10B981);
      case 'in_progress': return const Color(0xFF8B5CF6);
      case 'completed':   return const Color(0xFF22C55E);
      case 'cancelled':   return const Color(0xFF94A3B8);
      default:            return const Color(0xFF6366F1);
    }
  }

  String _prettyStatus(String s) =>
      s.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

// ── Widget Helpers ────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.color.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  color: Color(0xFF475569),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
