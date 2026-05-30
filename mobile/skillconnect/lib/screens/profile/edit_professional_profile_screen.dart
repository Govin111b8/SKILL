import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class EditProfessionalProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfessionalProfileScreen({super.key, required this.profile});

  @override
  State<EditProfessionalProfileScreen> createState() => _EditProfessionalProfileScreenState();
}

class _EditProfessionalProfileScreenState extends State<EditProfessionalProfileScreen> {
  late final TextEditingController _headlineCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _experienceCtrl;
  late final TextEditingController _pricingCtrl;
  late final TextEditingController _radiusCtrl;
  late String _availability;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _headlineCtrl = TextEditingController(text: p['headline'] ?? '');
    _bioCtrl = TextEditingController(text: p['bio'] ?? '');
    _experienceCtrl = TextEditingController(text: '${p['years_of_experience'] ?? 0}');
    _pricingCtrl = TextEditingController(text: '${p['pricing_estimate'] ?? ''}');
    _radiusCtrl = TextEditingController(text: '${p['service_location_radius_km'] ?? 25}');
    _availability = p['availability_status'] ?? 'available';
  }

  @override
  void dispose() {
    _headlineCtrl.dispose();
    _bioCtrl.dispose();
    _experienceCtrl.dispose();
    _pricingCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_headlineCtrl.text.trim().isEmpty || _bioCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Headline and bio are required'), backgroundColor: Colors.orange));
      return;
    }
    final pricing = double.tryParse(_pricingCtrl.text) ?? 0;
    if (pricing <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid starting price greater than ₹0'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _saving = true);
    try {
      final profileId = widget.profile['id'];
      await ApiService.put('/professionals/$profileId', {
        'headline': _headlineCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'years_of_experience': int.tryParse(_experienceCtrl.text) ?? 0,
        'pricing_estimate': pricing,
        'service_location_radius_km': double.tryParse(_radiusCtrl.text) ?? 25,
      }, auth: true);

      // Update availability separately
      await ApiService.put('/professionals/me/availability', {
        'availability_status': _availability,
      }, auth: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
        return;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PremiumAppBar(
        title: 'Edit Professional Profile',
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_rounded),
            label: Text(_saving ? 'Saving' : 'Save'),
          ),
        ],
      ),
      body: PremiumBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumHeroHeader(
                  title: 'Craft a profile that wins trust',
                  subtitle: 'Sharpen your headline, pricing and availability so customers instantly understand your expertise.',
                  icon: Icons.auto_awesome_rounded,
                  chips: [
                    PremiumStatChip(label: _availability.toUpperCase(), icon: Icons.bolt_rounded, color: Colors.white),
                    PremiumStatChip(label: 'Live edits', icon: Icons.edit_rounded, color: Colors.white),
                  ],
                ),
                const PremiumSectionTitle(
                  title: 'Basic Information',
                  subtitle: 'Set the story customers see first.',
                ),
                PremiumGlassCard(
                  child: Column(
                    children: [
                      _GradientInputField(
                        controller: _headlineCtrl,
                        label: 'Headline',
                        hint: 'e.g. Expert Plumber & Pipe Specialist',
                        icon: Icons.title_rounded,
                        maxLength: 100,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _GradientInputField(
                        controller: _bioCtrl,
                        label: 'Bio / About',
                        hint: 'Describe your skills and experience...',
                        icon: Icons.person_rounded,
                        maxLines: 5,
                        maxLength: 1000,
                      ),
                    ],
                  ),
                ),
                const PremiumSectionTitle(
                  title: 'Business Details',
                  subtitle: 'Show your pricing power and service reach.',
                ),
                PremiumGlassCard(
                  child: Column(
                    children: [
                      _GradientInputField(
                        controller: _experienceCtrl,
                        label: 'Years of Experience',
                        icon: Icons.work_history_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _GradientInputField(
                        controller: _pricingCtrl,
                        label: 'Starting Price (₹)',
                        icon: Icons.currency_rupee_rounded,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _GradientInputField(
                        controller: _radiusCtrl,
                        label: 'Service Radius (km)',
                        icon: Icons.radar_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const PremiumSectionTitle(
                  title: 'Availability',
                  subtitle: 'Let customers know when you are ready to take work.',
                ),
                PremiumGlassCard(
                  child: Column(
                    children: ['available', 'busy', 'offline'].map((status) {
                      final icon = status == 'available'
                          ? Icons.check_circle
                          : status == 'busy'
                              ? Icons.schedule
                              : Icons.circle_outlined;
                      final color = status == 'available'
                          ? AppColors.success
                          : status == 'busy'
                              ? AppColors.warning
                              : Colors.grey;
                      final selected = _availability == status;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          onTap: () => setState(() => _availability = status),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? LinearGradient(colors: [color.withAlpha(18), color.withAlpha(8)])
                                  : null,
                              color: selected ? null : Colors.white.withAlpha(120),
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              border: Border.all(color: selected ? color.withAlpha(120) : Colors.white.withAlpha(150)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(18),
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                  ),
                                  child: Icon(icon, color: color),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    status[0].toUpperCase() + status.substring(1),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                ),
                                Radio<String>(
                                  value: status,
                                  groupValue: _availability,
                                  activeColor: color,
                                  onChanged: (v) => setState(() => _availability = v!),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: _saving ? [Colors.grey.shade400, Colors.grey.shade500] : AppColors.primaryGradient),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: AppShadows.md(AppColors.primary),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        onTap: _saving ? null : _save,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_saving)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              else
                                const Icon(Icons.save_rounded, color: Colors.white),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                _saving ? 'Saving...' : 'Save Changes',
                                style: const TextStyle(
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;

  const _GradientInputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
  });

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
          color: Colors.white.withAlpha(235),
          borderRadius: BorderRadius.circular(AppRadius.xl - 1),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
            labelStyle: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
            hintStyle: TextStyle(color: Colors.grey.shade500),
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
            alignLabelWithHint: maxLines > 1,
            filled: true,
            fillColor: Colors.transparent,
            counterStyle: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      ),
    );
  }
}
