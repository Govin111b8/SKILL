import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/app_locale_service.dart';
import '../../services/theme_service.dart';
import '../../services/upload_service.dart';
import '../../services/push_notification_service.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _saving = false;
  bool _notificationsEnabled = true;
  String _appLanguage = 'en';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().user;
    _nameCtrl.text = user?['name'] ?? '';
    _phoneCtrl.text = user?['phone'] ?? '';
    _locationCtrl.text = user?['location'] ?? '';
    _loadLanguage();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    final lang = await AppLocaleService.getLocale();
    if (mounted) setState(() => _appLanguage = lang.languageCode);
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked == null) return;
    setState(() => _saving = true);
    try {
      final url = await UploadService.uploadAvatar(File(picked.path));
      if (mounted) {
        context.read<AuthService>().updateLocalUser({'avatar_url': url});
        _showSnack('Avatar updated!', success: true);
      }
    } catch (e) {
      if (mounted) _showSnack('Upload failed: $e', success: false);
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.put('/users/me', {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
      }, auth: true);
      if (mounted) {
        context.read<AuthService>().updateLocalUser({
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'location': _locationCtrl.text.trim(),
        });
        _showSnack('Profile saved!', success: true);
      }
    } catch (e) {
      if (mounted) _showSnack('Save failed: $e', success: false);
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _changePassword() async {
    _currentPassCtrl.clear();
    _newPassCtrl.clear();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ChangePasswordSheet(
        currentCtrl: _currentPassCtrl,
        newCtrl: _newPassCtrl,
        onSave: () async {
          if (_currentPassCtrl.text.isEmpty || _newPassCtrl.text.length < 8) return;
          try {
            await ApiService.put(
              '/users/me/password',
              {
                'current_password': _currentPassCtrl.text,
                'new_password': _newPassCtrl.text,
              },
              auth: true,
            );
            if (mounted) {
              Navigator.pop(context);
              _showSnack('Password changed!', success: true);
            }
          } catch (e) {
            if (mounted) _showSnack('Error: $e', success: false);
          }
        },
      ),
    );
  }

  void _showSnack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthService>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final themeService = context.watch<ThemeService>();
    final avatarUrl = user?['avatar_url']?.toString() ?? '';
    final name = user?['name']?.toString() ?? 'User';
    final email = user?['email']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PremiumAppBar(
        title: 'Settings',
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.lg),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
      body: PremiumBackground(
        child: SafeArea(
          top: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
                  child: PremiumGlassCard(
                    gradient: const [Color(0xE63B2A87), Color(0xE64F46E5), Color(0xE66366F1)],
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(colors: [Colors.white, Color(0xFFE9D5FF)]),
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 36,
                                  backgroundColor: Colors.white.withAlpha(20),
                                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                  child: avatarUrl.isEmpty
                                      ? Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                          style: const TextStyle(
                                            color: AppColors.primaryDark,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: AppShadows.sm(Colors.black26),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                email,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(220),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  PremiumStatChip(
                                    label: _appLanguage.toUpperCase(),
                                    icon: Icons.language_rounded,
                                    color: Colors.white,
                                  ),
                                  PremiumStatChip(
                                    label: themeService.themeMode.name.toUpperCase(),
                                    icon: Icons.palette_rounded,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _SettingsSection(
                  title: 'Account',
                  subtitle: 'Manage your public identity and credentials.',
                  children: [
                    _EditableField(
                      icon: Icons.person_rounded,
                      iconColor: AppColors.primary,
                      label: 'Full Name',
                      controller: _nameCtrl,
                    ),
                    _EditableField(
                      icon: Icons.phone_rounded,
                      iconColor: AppColors.success,
                      label: 'Phone Number',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                    _EditableField(
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.warning,
                      label: 'Location',
                      controller: _locationCtrl,
                    ),
                    _SettingsTile(
                      icon: Icons.lock_rounded,
                      iconColor: AppColors.error,
                      title: 'Change Password',
                      subtitle: 'Update your account security',
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black45),
                      onTap: _changePassword,
                    ),
                    _SettingsTile(
                      icon: Icons.verified_user_rounded,
                      iconColor: AppColors.secondary,
                      title: 'KYC Verification',
                      subtitle: 'Verify your identity',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PremiumStatusPill(label: 'Pending', color: AppColors.warning),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(Icons.chevron_right_rounded, color: Colors.black45),
                        ],
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: _SettingsSection(
                  title: 'Preferences',
                  subtitle: 'Customize language, theme and alerts.',
                  children: [
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      iconColor: AppColors.accent,
                      title: 'Language',
                      subtitle: 'Choose your preferred app language',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PremiumStatusPill(label: _appLanguage.toUpperCase(), color: AppColors.primary),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(Icons.chevron_right_rounded, color: Colors.black45),
                        ],
                      ),
                      onTap: () => _showLanguagePicker(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [AppColors.surfaceDark.withAlpha(25), AppColors.primary.withAlpha(18)]),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: const Icon(Icons.brightness_6_rounded, color: AppColors.surfaceDark),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Theme', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                SizedBox(height: 2),
                                Text('Light, system or dark mode', style: TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ),
                          _ThemeSegmentControl(themeService: themeService),
                        ],
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.notifications_rounded,
                      iconColor: const Color(0xFFF97316),
                      title: 'Notifications',
                      subtitle: 'Bookings, messages & offers',
                      trailing: Switch.adaptive(
                        value: _notificationsEnabled,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _notificationsEnabled = val);
                          if (val) {
                            PushNotificationService.requestPermission();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: _SettingsSection(
                  title: 'Privacy & Security',
                  subtitle: 'Control policies and sensitive account actions.',
                  children: [
                    _SettingsTile(
                      icon: Icons.privacy_tip_rounded,
                      iconColor: AppColors.primary,
                      title: 'Privacy Policy',
                      trailing: const Icon(Icons.open_in_new_rounded, color: Colors.black45, size: 18),
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.description_rounded,
                      iconColor: AppColors.secondary,
                      title: 'Terms of Service',
                      trailing: const Icon(Icons.open_in_new_rounded, color: Colors.black45, size: 18),
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.delete_forever_rounded,
                      iconColor: Colors.red,
                      title: 'Delete Account',
                      titleColor: Colors.red,
                      subtitle: 'This action is permanent',
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black45),
                      onTap: () => _showDeleteConfirm(context),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: _SettingsSection(
                  title: 'About',
                  subtitle: 'Version, feedback and sharing.',
                  children: [
                    _SettingsTile(
                      icon: Icons.info_rounded,
                      iconColor: Colors.grey.shade700,
                      title: 'Version',
                      trailing: const Text('1.0.0', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                    ),
                    _SettingsTile(
                      icon: Icons.star_rounded,
                      iconColor: AppColors.warning,
                      title: 'Rate Us',
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black45),
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.share_rounded,
                      iconColor: AppColors.success,
                      title: 'Share App',
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black45),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: Colors.red.withAlpha(70), width: 1.4),
                      gradient: LinearGradient(colors: [Colors.red.withAlpha(18), Colors.orange.withAlpha(10)]),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        onTap: _logout,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                'Logout',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final langs = [
      ('en', 'English'),
      ('hi', 'हिन्दी'),
      ('te', 'తెలుగు'),
      ('ta', 'தமிழ்'),
      ('ml', 'മലയാളം'),
      ('kn', 'ಕನ್ನಡ'),
      ('bn', 'বাংলা'),
      ('mr', 'मराठी'),
      ('gu', 'ગુજરાતી'),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('Choose Language',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          ...langs.map((l) => ListTile(
                title: Text(l.$2),
                trailing: _appLanguage == l.$1
                    ? const Icon(Icons.check_rounded, color: Color(0xFF6366F1))
                    : null,
                onTap: () async {
                  await AppLocaleService.setLocale(l.$1);
                  if (mounted) {
                    setState(() => _appLanguage = l.$1);
                    Navigator.pop(context);
                  }
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account?'),
        content: const Text(
            'This is permanent and cannot be undone. All your data will be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumSectionTitle(title: title, subtitle: subtitle),
          PremiumGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: Column(
              children: List.generate(children.length, (i) {
                final child = children[i];
                if (i == children.length - 1) return child;
                return Column(
                  children: [
                    child,
                    Divider(color: Colors.grey.shade200, height: 1, indent: 58),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [iconColor.withAlpha(20), iconColor.withAlpha(8)]),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: titleColor ?? AppColors.surfaceDark,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
              ),
            ),
      trailing: trailing,
    );
  }
}

class _EditableField extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _EditableField({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [iconColor.withAlpha(20), iconColor.withAlpha(8)]),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(1.2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.primaryGradient),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  borderRadius: BorderRadius.circular(AppRadius.xl - 1),
                ),
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.surfaceDark),
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl - 1),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl - 1),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl - 1),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: const Icon(Icons.edit_rounded, size: 16, color: Colors.black45),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSegmentControl extends StatelessWidget {
  final ThemeService themeService;
  const _ThemeSegmentControl({required this.themeService});

  @override
  Widget build(BuildContext context) {
    final options = [
      (ThemeMode.light, Icons.wb_sunny_rounded, 'Light'),
      (ThemeMode.system, Icons.phone_android_rounded, 'System'),
      (ThemeMode.dark, Icons.nightlight_round, 'Dark'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(150),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withAlpha(140)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = themeService.themeMode == opt.$1;
          return GestureDetector(
            onTap: () => themeService.setTheme(opt.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: isSelected ? const LinearGradient(colors: AppColors.primaryGradient) : null,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: isSelected ? AppShadows.sm(AppColors.primary) : null,
              ),
              child: Icon(
                opt.$2,
                size: 16,
                color: isSelected ? Colors.white : Colors.black54,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatelessWidget {
  final TextEditingController currentCtrl;
  final TextEditingController newCtrl;
  final VoidCallback onSave;

  const _ChangePasswordSheet({
    required this.currentCtrl,
    required this.newCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Change Password',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Refresh your login credentials to keep your SkillConnect account protected.',
            style: TextStyle(color: Colors.black54, height: 1.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SheetField(
            controller: currentCtrl,
            label: 'Current Password',
            icon: Icons.lock_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          _SheetField(
            controller: newCtrl,
            label: 'New Password (min 8 chars)',
            icon: Icons.lock_open_rounded,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.primaryGradient),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.md(AppColors.primary),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  onTap: onSave,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(
                      child: Text(
                        'Update Password',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _SheetField({required this.controller, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.primaryGradient),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl - 1),
        ),
        child: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: AppColors.primary),
            labelStyle: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl - 1),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl - 1),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl - 1),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
