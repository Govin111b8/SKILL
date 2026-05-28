import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  String _role = 'all';
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200 && !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  Map<String, String> _query({required int page}) {
    return {
      'page': '$page',
      'role': _role == 'all' ? '' : _role,
      'status': _status == 'all' ? '' : _status,
      if (_searchController.text.trim().isNotEmpty) 'q': _searchController.text.trim(),
    };
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _page = 1;
        _hasMore = true;
        _error = null;
      });
    }
    try {
      final res = await ApiService.get('/admin/users', auth: true, queryParams: _query(page: reset ? 1 : _page));
      final data = res['data'];
      final list = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['users'] as List? ?? const [])
              : const [];
      final parsed = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (!mounted) return;
      setState(() {
        if (reset) {
          _users = parsed;
        } else {
          _users.addAll(parsed);
        }
        _hasMore = parsed.isNotEmpty;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
    if (mounted) {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _loadingMore = true;
      _page += 1;
    });
    await _load(reset: false);
  }

  Future<void> _updateUserStatus(String id, Map<String, dynamic> body, String successMessage) async {
    try {
      await ApiService.put('/admin/users/$id/status', body, auth: true);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update user: $e')));
    }
  }

  void _showActions(Map<String, dynamic> user) {
    final id = (user['id'] ?? '').toString();
    final currentStatus = (user['status'] ?? 'active').toString();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.person_outline_rounded), title: const Text('View profile'), onTap: () => Navigator.pushNamed(context, '/profile/${user['id']}')),
          ListTile(
            leading: Icon(currentStatus == 'suspended' ? Icons.check_circle_outline_rounded : Icons.pause_circle_outline_rounded),
            title: Text(currentStatus == 'suspended' ? 'Unsuspend user' : 'Suspend user'),
            onTap: () => _updateUserStatus(id, {'status': currentStatus == 'suspended' ? 'active' : 'suspended'}, currentStatus == 'suspended' ? 'User reactivated.' : 'User suspended.'),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Make admin'),
            onTap: () => _updateUserStatus(id, {'role': 'admin'}, 'Admin access granted.'),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const roles = ['all', 'customer', 'professional', 'agent', 'admin'];
    const statuses = ['all', 'active', 'suspended', 'pending'];
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => _load()),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: roles.map((item) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: Text(item == 'all' ? 'All' : item[0].toUpperCase() + item.substring(1)), selected: _role == item, onSelected: (_) { setState(() => _role = item); _load(); }),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: statuses.map((item) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(label: Text(item == 'all' ? 'All' : item[0].toUpperCase() + item.substring(1)), selected: _status == item, onSelected: (_) { setState(() => _status = item); _load(); }),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(),
              child: _loading
                  ? ListView(children: const [SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))])
                  : _error != null
                      ? ListView(children: [
                          EmptyStateWidget(
                            icon: Icons.people_outline_rounded,
                            iconColor: Colors.red,
                            title: 'Could not load users',
                            subtitle: _error!,
                            actionLabel: 'Retry',
                            onAction: _load,
                          ),
                        ])
                      : _users.isEmpty
                          ? ListView(children: const [
                              EmptyStateWidget(
                                icon: Icons.manage_search_rounded,
                                title: 'No users found',
                                subtitle: 'Try adjusting your filters or search query.',
                              ),
                            ])
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _users.length + (_loadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= _users.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                final user = _users[index];
                                final role = (user['role'] ?? 'customer').toString();
                                final status = (user['status'] ?? 'active').toString();
                                final statusColor = status == 'suspended' ? Colors.red : status == 'pending' ? Colors.orange : Colors.green;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                                  child: ListTile(
                                    onTap: () => _showActions(user),
                                    leading: CircleAvatar(child: Text((user['name'] ?? '').toString().trim().isEmpty ? '?' : (user['name'] ?? '').toString().trim()[0].toUpperCase())),
                                    title: Text(user['name']?.toString() ?? 'User', style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(user['email']?.toString() ?? ''),
                                      const SizedBox(height: 6),
                                      Wrap(spacing: 8, runSpacing: 8, children: [
                                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withAlpha(18), borderRadius: BorderRadius.circular(18)), child: Text(role, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 12))),
                                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withAlpha(18), borderRadius: BorderRadius.circular(18)), child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12))),
                                      ]),
                                    ]),
                                    trailing: Text(user['member_since']?.toString() ?? user['created_at']?.toString() ?? ''),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
