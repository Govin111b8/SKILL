import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _currency =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  List<Map<String, dynamic>> _subscriptions = [];
  bool _loading = true;
  String? _error;

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
      final res = await ApiService.get('/subscriptions', auth: true);
      final data = res['data'];
      final items = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ??
                  data['subscriptions'] as List? ??
                  const [])
              : const [];
      _subscriptions = items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pauseAll() async {
    try {
      await ApiService.post('/subscriptions/vacation', {}, auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vacation mode enabled.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pause subscriptions: $e')));
    }
  }

  Future<void> _replaceProvider(String id) async {
    try {
      await ApiService.post(
          '/subscriptions/$id/replace-provider', {}, auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provider replacement requested.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not replace provider: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/search'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Subscription',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: _loading
                      ? const PremiumLoadingList(itemCount: 3, itemHeight: 160)
                      : _error != null
                          ? ListView(children: [
                              PremiumEmptyState(
                                icon: Icons.wifi_off_rounded,
                                title: 'Could not load subscriptions',
                                subtitle: _error!,
                                actionLabel: 'Try again',
                                onAction: _load,
                                gradient: const [
                                  AppColors.error,
                                  Color(0xFFFF6B6B)
                                ],
                              ),
                            ])
                          : _subscriptions.isEmpty
                              ? ListView(children: [
                                  PremiumEmptyState(
                                    icon: Icons.autorenew_rounded,
                                    title: 'No active plans',
                                    subtitle:
                                        'Create your first recurring service subscription to keep home services on autopilot.',
                                    actionLabel: 'Browse Services',
                                    onAction: () => Navigator.pushNamed(
                                        context, '/search'),
                                  ),
                                ])
                              : _buildSubscriptionList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(20),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Subscriptions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '${_subscriptions.length} active plan${_subscriptions.length == 1 ? '' : 's'}',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, 100),
      children: [
        PremiumGlassCard(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          gradient: const [Color(0xFFFFF7E6), Color(0xFFFFF3D6)],
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.beach_access_rounded,
                  color: Colors.white, size: 20),
            ),
            title: const Text('Vacation Mode',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            subtitle: Text('Pause all subscriptions',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            trailing: TextButton(
              onPressed: _pauseAll,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF59E0B),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              ),
              child: const Text('Pause',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._subscriptions.map((subscription) {
          final status =
              (subscription['status'] ?? 'active').toString();
          final amount = (subscription['monthly_amount'] ??
              subscription['amount'] ??
              0) as num;
          final nextBilling = DateTime.tryParse(
              (subscription['next_billing_date'] ??
                      subscription['next_billing_at'] ??
                      '')
                  .toString());
          final professional = (subscription['professional_name'] ??
                  subscription['provider_name'] ??
                  'Assigned provider')
              .toString();
          final service = (subscription['service_type'] ??
                  subscription['category_name'] ??
                  subscription['title'] ??
                  'Service plan')
              .toString();
          final chipColor = switch (status) {
            'paused' => AppColors.warning,
            'cancelled' => AppColors.error,
            _ => AppColors.success,
          };
          final statusIcon = switch (status) {
            'paused' => Icons.pause_circle_rounded,
            'cancelled' => Icons.cancel_rounded,
            _ => Icons.check_circle_rounded,
          };

          return Padding(
            padding:
                const EdgeInsets.only(bottom: AppSpacing.md),
            child: PremiumGlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            AppColors.primary.withAlpha(30),
                            AppColors.accent.withAlpha(20),
                          ]),
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                        ),
                        child: const Icon(Icons.repeat_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          service,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      PremiumStatusPill(
                        label: status.replaceAll('_', ' '),
                        color: chipColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SubscriptionRow(
                    icon: Icons.person_rounded,
                    label: professional,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _SubscriptionRow(
                    icon: Icons.calendar_today_rounded,
                    label:
                        'Next: ${nextBilling != null ? DateFormat('dd MMM yyyy').format(nextBilling) : 'TBD'}',
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _SubscriptionRow(
                    icon: Icons.currency_rupee_rounded,
                    label: '${_currency.format(amount)} / month',
                    color: AppColors.success,
                    bold: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _replaceProvider(
                          (subscription['id'] ?? '').toString()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('Replace Provider',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SubscriptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool bold;
  const _SubscriptionRow(
      {required this.icon,
      required this.label,
      required this.color,
      this.bold = false});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: bold ? color : Colors.grey.shade700,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ]);
}
