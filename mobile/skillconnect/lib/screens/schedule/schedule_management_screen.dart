import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

/// Schedule management screen for professionals.
/// Allows setting weekly availability, blocking dates (vacation), and
/// managing time slots.
class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _schedule = [];
  List<Map<String, dynamic>> _blockedDates = [];
  bool _loading = true;
  String? _error;
  bool _saving = false;

  static const _days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

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
    setState(() {
      _loading = true;
      _error = null;
    });
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
          const SnackBar(
              content: Text('Schedule saved!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
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
    final initial =
        TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

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
      dates.add(
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
      d = d.add(const Duration(days: 1));
    }

    try {
      await ApiService.post('/schedule/block-dates',
          {'dates': dates, 'reason': 'Vacation'}, auth: true);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _unblockDate(String date) async {
    try {
      await ApiService.post(
          '/schedule/unblock-dates', {'dates': [date]}, auth: true);
      setState(() {
        _blockedDates.removeWhere(
            (d) => d['blocked_date']?.toString().startsWith(date) == true);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            _buildHeader(context),
            _buildPremiumTabBar(),
            Expanded(
              child: _loading
                  ? const PremiumLoadingList(itemCount: 7, itemHeight: 100)
                  : _error != null
                      ? Center(
                          child: PremiumEmptyState(
                            icon: Icons.error_outline_rounded,
                            title: 'Could not load schedule',
                            subtitle: _error!,
                            actionLabel: 'Retry',
                            onAction: _loadData,
                            gradient: const [
                              AppColors.error,
                              Color(0xFFFF6B6B)
                            ],
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildWeeklyTab(),
                            _buildBlockedTab(),
                          ],
                        ),
            ),
          ]),
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
            'My Schedule',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5),
          ),
        ),
        if (!_loading)
          AnimatedContainer(
            duration: AppDurations.fast,
            decoration: BoxDecoration(
              gradient: _saving
                  ? null
                  : const LinearGradient(colors: AppColors.primaryGradient),
              color: _saving ? Colors.grey.withAlpha(40) : null,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: _saving ? null : AppShadows.sm(AppColors.primary),
            ),
            child: TextButton.icon(
              onPressed: _saving ? null : _saveSchedule,
              icon: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_rounded,
                      color: Colors.white, size: 16),
              label: Text(
                'Save',
                style: TextStyle(
                  color: _saving ? Colors.grey : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildPremiumTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(60),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.primaryGradient),
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
          Tab(text: 'Weekly Hours'),
          Tab(text: 'Blocked Dates'),
        ],
      ),
    );
  }

  Widget _buildWeeklyTab() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.huge),
      itemCount: 7,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, day) {
        final slots = _slotsForDay(day);
        final isWeekend = day == 0 || day == 6;
        final dayColor = isWeekend ? AppColors.warning : AppColors.primary;

        return PremiumGlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: dayColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: dayColor.withAlpha(50)),
                  ),
                  child: Center(
                    child: Text(
                      _days[day].substring(0, 2),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: dayColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _days[day],
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      Text(
                        slots.isEmpty
                            ? 'Day off'
                            : '${slots.length} slot${slots.length > 1 ? 's' : ''} scheduled',
                        style: TextStyle(
                          fontSize: 12,
                          color: slots.isEmpty
                              ? Colors.grey.shade500
                              : dayColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _addSlot(day),
                  icon: const Icon(Icons.add_circle_rounded,
                      color: AppColors.primary),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withAlpha(12),
                  ),
                  tooltip: 'Add time slot',
                ),
              ]),
              if (slots.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                ...slots.map((slot) {
                  final globalIndex = _schedule.indexOf(slot);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: slot['is_active'] == true
                            ? AppColors.primary.withAlpha(8)
                            : Colors.grey.withAlpha(10),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: slot['is_active'] == true
                              ? AppColors.primary.withAlpha(40)
                              : Colors.grey.withAlpha(30),
                        ),
                      ),
                      child: Row(children: [
                        Switch(
                          value: slot['is_active'] == true,
                          onChanged: (v) => setState(
                              () => _schedule[globalIndex]['is_active'] = v),
                          activeColor: AppColors.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _TimeChip(
                          time: slot['start_time'] ?? '09:00',
                          onTap: () => _pickTime(globalIndex, true),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm),
                          child: Text('—',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300)),
                        ),
                        _TimeChip(
                          time: slot['end_time'] ?? '17:00',
                          onTap: () => _pickTime(globalIndex, false),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded,
                              size: 20, color: AppColors.error),
                          onPressed: () => _removeSlot(globalIndex),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.error.withAlpha(10),
                          ),
                        ),
                      ]),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlockedTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: GestureDetector(
          onTap: _addBlockedDates,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppShadows.md(AppColors.warning),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.beach_access_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Block Dates (Vacation)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Expanded(
        child: _blockedDates.isEmpty
            ? const PremiumEmptyState(
                icon: Icons.event_available_rounded,
                title: 'No blocked dates',
                subtitle:
                    'Block date ranges when you\'re on vacation or unavailable.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
                itemCount: _blockedDates.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) {
                  final item = _blockedDates[i];
                  final date =
                      item['blocked_date']?.toString().split('T').first ??
                          '';
                  final reason = item['reason'] ?? 'Blocked';
                  return PremiumGlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withAlpha(15),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                              color: AppColors.warning.withAlpha(50)),
                        ),
                        child: const Icon(Icons.event_busy_rounded,
                            color: AppColors.warning, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(date,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            Text(reason,
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.restore_rounded,
                            color: AppColors.primary),
                        onPressed: () => _unblockDate(date),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary.withAlpha(12),
                        ),
                        tooltip: 'Unblock',
                      ),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final VoidCallback onTap;
  const _TimeChip({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [
              Color(0xFFEEF2FF),
              Color(0xFFF5F3FF),
            ]),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.primary.withAlpha(40)),
          ),
          child: Text(
            time,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
        ),
      );
}
