import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/app_locale_service.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

/// Smart push notification preferences screen.
/// Lets users control notification categories to avoid annoyance.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _transactional = true; // Always on
  bool _behavioral = true;
  bool _lifecycle = true;
  bool _promotional = false;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _behavioral = prefs.getBool('notif_behavioral') ?? true;
      _lifecycle = prefs.getBool('notif_lifecycle') ?? true;
      _promotional = prefs.getBool('notif_promotional') ?? false;
      _language = prefs.getString('notif_language') ?? 'en';
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool('notif_behavioral', _behavioral),
      prefs.setBool('notif_lifecycle', _lifecycle),
      prefs.setBool('notif_promotional', _promotional),
      prefs.setString('notif_language', _language),
    ]);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved ✓')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const PremiumAppBar(title: 'Notification Settings'),
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.xxxl),
            children: [
              PremiumHeroHeader(
                title: 'Stay informed your way',
                subtitle: 'Choose which alerts feel helpful, timely, and premium.',
                icon: Icons.tune_rounded,
                chips: [
                  PremiumStatChip(
                    label: _promotional ? 'Offers on' : 'Offers off',
                    icon: _promotional ? Icons.local_offer_rounded : Icons.local_offer_outlined,
                    color: Colors.white,
                  ),
                  PremiumStatChip(
                    label: 'Language ${_language.toUpperCase()}',
                    icon: Icons.translate_rounded,
                    color: Colors.white,
                  ),
                ],
              ),
              const PremiumSectionTitle(
                title: 'Notification categories',
                subtitle: 'Smart toggle cards for booking, reminders, and promotions.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    _NotifTile(
                      icon: Icons.receipt_long,
                      title: 'Booking Updates',
                      subtitle: 'Confirmations, assignments, completions',
                      value: _transactional,
                      onChanged: null,
                      locked: true,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _NotifTile(
                      icon: Icons.lightbulb_outline,
                      title: 'Smart Suggestions',
                      subtitle: '"Plumber available nearby", "Need help with yesterday's search?"',
                      value: _behavioral,
                      onChanged: (v) => setState(() => _behavioral = v),
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _NotifTile(
                      icon: Icons.history,
                      title: 'Service Reminders',
                      subtitle: '"It's been 30 days since last service"',
                      value: _lifecycle,
                      onChanged: (v) => setState(() => _lifecycle = v),
                      color: AppColors.info,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _NotifTile(
                      icon: Icons.local_offer,
                      title: 'Offers & Promotions',
                      subtitle: 'Max 1-2 per week',
                      value: _promotional,
                      onChanged: (v) => setState(() => _promotional = v),
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ),
              const PremiumSectionTitle(
                title: 'Notification language',
                subtitle: 'Pick the language you want alerts in.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: PremiumGlassCard(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: AppLocaleService.languageOptions
                        .map(
                          (option) => ChoiceChip(
                            label: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                              child: Text(option.value),
                            ),
                            selected: _language == option.key,
                            selectedColor: AppColors.primary.withAlpha(16),
                            backgroundColor: Colors.white.withAlpha(180),
                            side: BorderSide(
                              color: _language == option.key ? AppColors.primary : AppColors.borderLight,
                            ),
                            labelStyle: TextStyle(
                              color: _language == option.key ? AppColors.primary : AppColors.surfaceDark,
                              fontWeight: FontWeight.w700,
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _language = option.key);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, 0),
                child: PremiumGradientButton(
                  label: 'Save Preferences',
                  icon: Icons.save_rounded,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool locked;
  final Color color;

  const _NotifTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
    this.locked = false,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      gradient: value
          ? [color.withAlpha(18), Colors.white.withAlpha(220)]
          : [Colors.white.withAlpha(210), Colors.white.withAlpha(160)],
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withAlpha(14),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                    if (locked)
                      const PremiumStatusPill(label: 'Always on', color: AppColors.success),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch(
            value: value,
            onChanged: locked ? null : onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }
}
