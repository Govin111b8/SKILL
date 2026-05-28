import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loader.dart';

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _earnings = [];
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
      final meRes = await ApiService.get('/referrals/me', auth: true);
      final earningsRes = await ApiService.get('/referrals/earnings', auth: true);
      _summary = Map<String, dynamic>.from((meRes['data'] as Map?) ?? const {});
      final data = earningsRes['data'];
      final items = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['items'] as List? ?? data['earnings'] as List? ?? data['referrals'] as List? ?? const [])
              : const [];
      _earnings = items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral code copied.')));
  }

  void _shareCode(String code) {
    Share.share('Join SkillConnect with my referral code $code and unlock rewards.');
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary ?? const <String, dynamic>{};
    final code = (summary['code'] ?? summary['referral_code'] ?? 'SKILLPRO').toString();
    final totalReferrals = (summary['total_referrals'] ?? summary['referrals_count'] ?? _earnings.length).toString();
    final pending = ((summary['pending_earnings'] ?? 0) as num).toDouble();
    final credited = ((summary['credited_earnings'] ?? summary['total_credited'] ?? 0) as num).toDouble();
    return Scaffold(
      appBar: AppBar(title: const Text('Referrals')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                ],
              )
            : _error != null
                ? ListView(children: [
                    EmptyStateWidget(
                      icon: Icons.error_outline_rounded,
                      iconColor: Colors.red,
                      title: 'Could not load referrals',
                      subtitle: _error!,
                      actionLabel: 'Try again',
                      onAction: _load,
                    ),
                  ])
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Text('Your referral code', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            SelectableText(code, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _copyCode(code),
                                    icon: const Icon(Icons.copy_rounded),
                                    label: const Text('Copy'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () => _shareCode(code),
                                    icon: const Icon(Icons.share_rounded),
                                    label: const Text('Share'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            QrImageView(data: code, size: 160),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _StatCard(label: 'Total referrals', value: totalReferrals)),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(label: 'Pending', value: _currency.format(pending))),
                      ]),
                      const SizedBox(height: 12),
                      _StatCard(label: 'Credited earnings', value: _currency.format(credited)),
                      const SizedBox(height: 20),
                      Text('Referred users', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      if (_earnings.isEmpty)
                        const EmptyStateWidget(
                          icon: Icons.people_outline_rounded,
                          title: 'No referral activity yet',
                          subtitle: 'Share your code to start earning referral credits.',
                        )
                      else
                        ..._earnings.map((item) {
                          final status = (item['status'] ?? 'pending').toString();
                          final color = status == 'credited' ? Colors.green : Colors.orange;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            child: Row(children: [
                              CircleAvatar(child: Text((item['name'] ?? item['user_name'] ?? '').toString().trim().isEmpty ? '?' : (item['name'] ?? item['user_name'] ?? '').toString().trim()[0].toUpperCase())),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(item['name']?.toString() ?? item['user_name']?.toString() ?? 'Referred user', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text(item['date']?.toString() ?? item['created_at']?.toString() ?? ''),
                                ]),
                              ),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(_currency.format(((item['amount'] ?? 0) as num).toDouble()), style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(20)),
                                  child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                                ),
                              ]),
                            ]),
                          );
                        }),
                      const SizedBox(height: 12),
                      Text('How it works', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      const _HowItWorksStep(step: '1', title: 'Share your code', subtitle: 'Send your referral link or QR code to friends and family.'),
                      _HowItWorksStep(step: '2', title: 'They sign up', subtitle: 'New users join SkillConnect using your code at registration.'),
                      _HowItWorksStep(step: '3', title: 'You get rewarded', subtitle: 'Once they complete the required action, earnings are credited to your wallet.'),
                    ],
                  ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;
  const _HowItWorksStep({required this.step, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(children: [
        CircleAvatar(child: Text(step)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle),
        ])),
      ]),
    );
  }
}
