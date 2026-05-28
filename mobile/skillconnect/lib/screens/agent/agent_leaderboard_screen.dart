import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/skeleton_loader.dart';

class AgentLeaderboardScreen extends StatefulWidget {
  const AgentLeaderboardScreen({super.key});

  @override
  State<AgentLeaderboardScreen> createState() => _AgentLeaderboardScreenState();
}

class _AgentLeaderboardScreenState extends State<AgentLeaderboardScreen> {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  List<Map<String, dynamic>> _agents = [];
  bool _loading = true;
  String? _error;
  String _period = 'month';

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
      final res = await ApiService.get('/agents/leaderboard', auth: true, queryParams: {'period': _period});
      final data = res['data'];
      final list = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['agents'] as List? ?? const [])
              : const [];
      _agents = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).take(50).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final currentId = auth.user?['id']?.toString();
    final podium = _agents.take(3).toList();
    final rest = _agents.length > 3 ? _agents.sublist(3) : const <Map<String, dynamic>>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Agent Leaderboard')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))])
            : _error != null
                ? ListView(children: [
                    EmptyStateWidget(
                      icon: Icons.leaderboard_outlined,
                      iconColor: Colors.red,
                      title: 'Could not load leaderboard',
                      subtitle: _error!,
                      actionLabel: 'Retry',
                      onAction: _load,
                    ),
                  ])
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(label: const Text('This month'), selected: _period == 'month', onSelected: (_) { setState(() => _period = 'month'); _load(); }),
                          ChoiceChip(label: const Text('This quarter'), selected: _period == 'quarter', onSelected: (_) { setState(() => _period = 'quarter'); _load(); }),
                          ChoiceChip(label: const Text('All time'), selected: _period == 'all', onSelected: (_) { setState(() => _period = 'all'); _load(); }),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (podium.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (podium.length > 1) Expanded(child: _PodiumCard(agent: podium[1], medalColor: const Color(0xFFC0C0C0), height: 140)),
                            if (podium.isNotEmpty) Expanded(child: _PodiumCard(agent: podium[0], medalColor: const Color(0xFFFFD700), height: 180)),
                            if (podium.length > 2) Expanded(child: _PodiumCard(agent: podium[2], medalColor: const Color(0xFFCD7F32), height: 120)),
                          ],
                        ),
                      const SizedBox(height: 20),
                      ...rest.map((agent) {
                        final isCurrent = currentId != null && (agent['id']?.toString() == currentId || agent['agent_id']?.toString() == currentId);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isCurrent ? Theme.of(context).colorScheme.primary.withAlpha(10) : null,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isCurrent ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant),
                          ),
                          child: Row(children: [
                            CircleAvatar(child: Text('${agent['rank'] ?? ''}')),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(agent['name']?.toString() ?? 'Agent', style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(agent['city']?.toString() ?? 'City not set'),
                              ]),
                            ),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('${agent['referrals_count'] ?? 0} referrals • ${agent['bookings_count'] ?? 0} bookings'),
                              const SizedBox(height: 4),
                              Text(_currency.format(((agent['earnings'] ?? 0) as num).toDouble()), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ]),
                          ]),
                        );
                      }),
                    ],
                  ),
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final Map<String, dynamic> agent;
  final Color medalColor;
  final double height;
  const _PodiumCard({required this.agent, required this.medalColor, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: medalColor),
        color: medalColor.withAlpha(18),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Icon(Icons.workspace_premium_rounded, color: medalColor, size: 30),
        const SizedBox(height: 8),
        Text(agent['name']?.toString() ?? 'Agent', textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('#${agent['rank'] ?? ''}', style: TextStyle(color: medalColor, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
