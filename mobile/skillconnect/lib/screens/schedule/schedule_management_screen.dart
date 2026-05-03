import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';

/// Schedule management screen for professionals.
/// Allows setting weekly availability, blocking dates (vacation), and
/// managing time slots.
class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _schedule = [];
  List<Map<String, dynamic>> _blockedDates = [];
  bool _loading = true;
  String? _error;
  bool _saving = false;

  static const _days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.get('/schedule', auth: true),
        ApiService.get('/schedule/blocked-dates', auth: true),
      ]);
      final schedData = results[0]['schedule'] as List? ?? [];
      _schedule = schedData.cast<Map<String, dynamic>>();
      final blockedData = results[1]['blocked_dates'] as List? ?? [];
      _blockedDates = blockedData.cast<Map<String, dynamic>>();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _slotsForDay(int dayOfWeek) {
    return _schedule.where((s) => s['day_of_week'] == dayOfWeek).toList();
  }

  Future<void> _saveSchedule() async {
    setState(() => _saving = true);
    try {
      await ApiService.post('/schedule', {'slots': _schedule}, auth: true);
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule saved!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  void _addSlot(int dayOfWeek) {
    setState(() {
      _schedule.add({
        'day_of_week': dayOfWeek,
        'start_time': '09:00',
        'end_time': '17:00',
        'is_active': true,
      });
    });
  }

  void _removeSlot(int globalIndex) {
    setState(() {
      _schedule.removeAt(globalIndex);
    });
  }

  Future<void> _pickTime(int slotIndex, bool isStart) async {
    final slot = _schedule[slotIndex];
    final current = slot[isStart ? 'start_time' : 'end_time'] as String;
    final parts = current.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        _schedule[slotIndex][isStart ? 'start_time' : 'end_time'] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _addBlockedDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;

    final dates = <String>[];
    var d = picked.start;
    while (!d.isAfter(picked.end)) {
      dates.add('${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
      d = d.add(const Duration(days: 1));
    }

    try {
      await ApiService.post('/schedule/block-dates', {'dates': dates, 'reason': 'Vacation'}, auth: true);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _unblockDate(String date) async {
    try {
      await ApiService.post('/schedule/unblock-dates', {'dates': [date]}, auth: true);
      setState(() {
        _blockedDates.removeWhere((d) => d['blocked_date']?.toString().startsWith(date) == true);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        actions: [
          if (!_loading)
            TextButton.icon(
              onPressed: _saving ? null : _saveSchedule,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: const Text('Save'),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Weekly Hours'),
            Tab(text: 'Blocked Dates'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: TextStyle(color: cs.error)),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _loadData, child: const Text('Retry')),
                ]))
              : TabBarView(
                  controller: _tabController,
                  children: [_buildWeeklyTab(cs), _buildBlockedTab(cs)],
                ),
    );
  }

  Widget _buildWeeklyTab(ColorScheme cs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 7,
      itemBuilder: (context, day) {
        final slots = _slotsForDay(day);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_days[day], style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    if (slots.isEmpty)
                      Text('Day off', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))
                    else
                      Text('${slots.length} slot${slots.length > 1 ? 's' : ''}',
                          style: TextStyle(color: cs.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () => _addSlot(day),
                      tooltip: 'Add time slot',
                    ),
                  ],
                ),
                ...slots.map((slot) {
                  final globalIndex = _schedule.indexOf(slot);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Switch(
                          value: slot['is_active'] == true,
                          onChanged: (v) => setState(() => _schedule[globalIndex]['is_active'] = v),
                        ),
                        InkWell(
                          onTap: () => _pickTime(globalIndex, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(slot['start_time'] ?? '09:00',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('—'),
                        ),
                        InkWell(
                          onTap: () => _pickTime(globalIndex, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(slot['end_time'] ?? '17:00',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 20, color: cs.error),
                          onPressed: () => _removeSlot(globalIndex),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlockedTab(ColorScheme cs) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addBlockedDates,
              icon: const Icon(Icons.block),
              label: const Text('Block Dates (Vacation)'),
            ),
          ),
        ),
        Expanded(
          child: _blockedDates.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.event_available, size: 48, color: cs.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text('No blocked dates', style: TextStyle(color: cs.onSurfaceVariant)),
                  ]),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _blockedDates.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = _blockedDates[i];
                    final date = item['blocked_date']?.toString().split('T').first ?? '';
                    final reason = item['reason'] ?? 'Blocked';
                    return ListTile(
                      leading: const Icon(Icons.event_busy),
                      title: Text(date),
                      subtitle: Text(reason),
                      trailing: IconButton(
                        icon: Icon(Icons.restore, color: cs.primary),
                        onPressed: () => _unblockDate(date),
                        tooltip: 'Unblock',
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
