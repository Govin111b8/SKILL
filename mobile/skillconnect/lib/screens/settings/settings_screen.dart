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
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF1B6EF3),
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white),
            ),
            actions: [
              if (_saving)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                )
              else
                TextButton(
                  onPressed: _save,
                  child: const Text('Save',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
            ],
          ),

          // ── Profile Header ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1B6EF3), Color(0xFF4F46E5)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            color: Colors.white.withAlpha(30),
                          ),
                          child: avatarUrl.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(avatarUrl,
                                      width: 68, height: 68, fit: BoxFit.cover),
                                )
                              : Center(
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 13, color: Color(0xFF1B6EF3)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(email,
                            style: TextStyle(
                                color: Colors.white.withAlpha(180), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Account Section ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Account',
              children: [
                _EditableField(
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFF6366F1),
                  label: 'Full Name',
                  controller: _nameCtrl,
                ),
                _EditableField(
                  icon: Icons.phone_rounded,
                  iconColor: const Color(0xFF10B981),
                  label: 'Phone Number',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                _EditableField(
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  label: 'Location',
                  controller: _locationCtrl,
                ),
                _SettingsTile(
                  icon: Icons.lock_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Change Password',
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8), size: 20),
                  onTap: _changePassword,
                ),
                _SettingsTile(
                  icon: Icons.verified_user_rounded,
                  iconColor: const Color(0xFF06B6D4),
                  title: 'KYC Verification',
                  subtitle: 'Verify your identity',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Pending',
                            style: TextStyle(
                                color: Color(0xFFD97706),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8), size: 20),
                    ],
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Preferences ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Preferences',
              children: [
                // Language
                _SettingsTile(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Language',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _appLanguage.toUpperCase(),
                          style: const TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.w700,
                              fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8), size: 20),
                    ],
                  ),
                  onTap: () => _showLanguagePicker(context),
                ),

                // Theme
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.brightness_6_rounded,
                            color: Color(0xFF0F172A), size: 18),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                          child: Text('Theme',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF0F172A)))),
                      _ThemeSegmentControl(themeService: themeService),
                    ],
                  ),
                ),

                // Notifications
                _SettingsTile(
                  icon: Icons.notifications_rounded,
                  iconColor: const Color(0xFFF97316),
                  title: 'Notifications',
                  subtitle: 'Bookings, messages & offers',
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
                    activeColor: const Color(0xFF6366F1),
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

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Privacy & Security ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Privacy & Security',
              children: [
                _SettingsTile(
                  icon: Icons.privacy_tip_rounded,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Privacy Policy',
                  trailing: const Icon(Icons.open_in_new_rounded,
                      color: Color(0xFF94A3B8), size: 18),
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.description_rounded,
                  iconColor: const Color(0xFF06B6D4),
                  title: 'Terms of Service',
                  trailing: const Icon(Icons.open_in_new_rounded,
                      color: Color(0xFF94A3B8), size: 18),
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  iconColor: Colors.red,
                  title: 'Delete Account',
                  titleColor: Colors.red,
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8), size: 20),
                  onTap: () => _showDeleteConfirm(context),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── About ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'About',
              children: [
                _SettingsTile(
                  icon: Icons.info_rounded,
                  iconColor: const Color(0xFF64748B),
                  title: 'Version',
                  trailing: const Text('1.0.0',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                ),
                _SettingsTile(
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Rate Us',
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8), size: 20),
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.share_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Share App',
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8), size: 20),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Logout ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _logout,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
        ],
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

// ── Supporting Widgets ────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
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
              children: List.generate(children.length, (i) {
                final child = children[i];
                if (i == children.length - 1) return child;
                return Column(
                  children: [
                    child,
                    Divider(
                      height: 1,
                      indent: 56,
                      color: const Color(0xFFE2E8F0).withAlpha(200),
                    ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: titleColor ?? const Color(0xFF0F172A),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF94A3B8)),
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
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = themeService.themeMode == opt.$1;
          return GestureDetector(
            onTap: () => themeService.setTheme(opt.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                opt.$2,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
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
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
            margin: const EdgeInsets.only(bottom: 16),
          ),
          const Text('Change Password',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 20),
          TextField(
            controller: currentCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Current Password',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.lock_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'New Password (min 8 chars)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.lock_open_rounded),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onSave,
              child: const Text('Update Password',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
