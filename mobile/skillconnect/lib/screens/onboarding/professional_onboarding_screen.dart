import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/premium_ui.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data class (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class _PortfolioDraft {
  final String path;
  final Uint8List bytes;
  final String title;
  final String description;
  const _PortfolioDraft({
    required this.path,
    required this.bytes,
    required this.title,
    required this.description,
  });
  Map<String, dynamic> toJson() =>
      {'path': path, 'title': title, 'description': description};
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────
class ProfessionalOnboardingScreen extends StatefulWidget {
  const ProfessionalOnboardingScreen({super.key});

  @override
  State<ProfessionalOnboardingScreen> createState() =>
      _ProfessionalOnboardingScreenState();
}

class _ProfessionalOnboardingScreenState
    extends State<ProfessionalOnboardingScreen> with TickerProviderStateMixin {
  // ── Form keys & controllers (UNCHANGED) ────────────────────────
  final _basicKey = GlobalKey<FormState>();
  final _pricingKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  // ── Service state (UNCHANGED) ───────────────────────────────────
  final List<String> _selectedServices = [];
  final List<_PortfolioDraft> _portfolio = [];
  final Map<String, TextEditingController> _servicePriceControllers = {};
  final List<String> _availableServices = const [
    'AC Repair',
    'Deep Cleaning',
    'Salon at Home',
    'Plumbing',
    'Electrical',
    'Tutoring',
    'Carpentry',
    'Painting',
  ];

  // ── Step state (UNCHANGED) ──────────────────────────────────────
  int _currentStep = 0;
  static const _totalSteps = 6;
  bool _submitting = false;
  String? _error;

  // ── Animation controllers ───────────────────────────────────────
  late final AnimationController _stepAnimCtrl;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _stepAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _pageCtrl = PageController();
    _stepAnimCtrl.forward();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _hourlyRateController.dispose();
    for (final c in _servicePriceControllers.values) {
      c.dispose();
    }
    _stepAnimCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Step navigation (UNCHANGED logic) ──────────────────────────
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.selectionClick();
      setState(() => _currentStep++);
      _pageCtrl.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
      _stepAnimCtrl
        ..reset()
        ..forward();
    } else {
      _submit();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.selectionClick();
      setState(() => _currentStep--);
      _pageCtrl.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    }
  }

  // ── Pick portfolio image (UNCHANGED) ───────────────────────────
  Future<void> _pickPortfolioImage() async {
    if (_portfolio.length >= 3) return;
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      final titleCtrl = TextEditingController();
      final descCtrl = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Portfolio details'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: titleCtrl,
                decoration:
                    const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(
                controller: descCtrl,
                decoration:
                    const InputDecoration(labelText: 'Description')),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Add')),
          ],
        ),
      );
      if (confirmed != true) return;
      setState(() => _portfolio.add(_PortfolioDraft(
            path: picked.path,
            bytes: bytes,
            title: titleCtrl.text.trim(),
            description: descCtrl.text.trim(),
          )));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')));
    }
  }

  // ── Submit (UNCHANGED) ──────────────────────────────────────────
  Future<void> _submit() async {
    if (!_basicKey.currentState!.validate() ||
        !_pricingKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      setState(() => _error = 'Please add at least one service.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ApiService.put('/professionals/profile', {
        'display_name': _displayNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'years_experience':
            int.tryParse(_experienceController.text.trim()) ?? 0,
        'city': _cityController.text.trim(),
        'area': _areaController.text.trim(),
        'hourly_rate':
            num.tryParse(_hourlyRateController.text.trim()) ?? 0,
        'portfolio_drafts': _portfolio.map((e) => e.toJson()).toList(),
      }, auth: true);
      for (final service in _selectedServices) {
        await ApiService.post('/services/me', {
          'service_name': service,
          'price': num.tryParse(
                  _servicePriceControllers[service]?.text.trim() ?? '') ??
              0,
        }, auth: true);
      }
      await ApiService.post('/kyc/initiate', {
        'flow': 'professional_onboarding',
        'service_count': _selectedServices.length,
      }, auth: true);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _submitting = false);
  }

  // ─────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Stack(
        children: [
          // Gradient backdrop
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header ───────────────────────────────────────
                _buildHeader(),
                const SizedBox(height: AppSpacing.md),

                // ── Step indicator ───────────────────────────────
                _buildStepIndicator(),
                const SizedBox(height: AppSpacing.xl),

                // ── Page content ─────────────────────────────────
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep0Welcome(),
                      _buildStep1BasicInfo(),
                      _buildStep2Services(),
                      _buildStep3Portfolio(),
                      _buildStep4Pricing(),
                      _buildStep5Review(),
                    ],
                  ),
                ),

                // ── Navigation buttons ───────────────────────────
                _buildNavRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    const stepTitles = [
      'Welcome',
      'Basic Info',
      'Your Services',
      'Portfolio',
      'Pricing',
      'Review & Publish',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Row(
        children: [
          if (_currentStep > 0)
            GestureDetector(
              onTap: _previousStep,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Colors.white.withAlpha(40)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            )
          else
            const SizedBox(width: 38),
          const Spacer(),
          Column(children: [
            Text(
              'Step ${_currentStep + 1} of $_totalSteps',
              style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              stepTitles[_currentStep],
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15),
            ),
          ]),
          const Spacer(),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  // ── Step indicator dots ───────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: List.generate(_totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = (i - 1) ~/ 2;
            final filled = stepIndex < _currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                decoration: BoxDecoration(
                  gradient: filled
                      ? const LinearGradient(colors: [
                          Colors.white,
                          Colors.white70
                        ])
                      : null,
                  color: filled ? null : Colors.white.withAlpha(40),
                ),
              ),
            );
          }
          // Dot
          final step = i ~/ 2;
          final isActive = step == _currentStep;
          final isDone = step < _currentStep;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 28 : 14,
            height: 14,
            decoration: BoxDecoration(
              color: isDone
                  ? Colors.white
                  : isActive
                      ? Colors.white
                      : Colors.white.withAlpha(60),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                          color: Colors.white.withAlpha(80),
                          blurRadius: 8,
                          spreadRadius: 2)
                    ]
                  : null,
            ),
            child: isDone
                ? const Icon(Icons.check_rounded,
                    color: Color(0xFF6366F1), size: 10)
                : null,
          );
        }),
      ),
    );
  }

  // ── Step 0: Welcome ──────────────────────────────────────────────
  Widget _buildStep0Welcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.primary.withAlpha(30)),
              boxShadow: AppShadows.md(AppColors.primary),
            ),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6)
                  ]),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppShadows.md(AppColors.primary),
                ),
                child: const Icon(Icons.rocket_launch_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Build Your Professional Business',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Complete 6 quick steps to publish your verified storefront and start receiving bookings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade600, height: 1.5, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.xl),
              ...[
                ('✅', 'Professional profile & bio'),
                ('🛠️', 'Select your services'),
                ('📸', 'Upload portfolio photos'),
                ('💰', 'Set your pricing'),
                ('🏆', 'Get verified & go live'),
              ].map((item) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(children: [
                      Text(item.$1,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Text(item.$2,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF374151))),
                    ]),
                  )),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Step 1: Basic Info ───────────────────────────────────────────
  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Form(
        key: _basicKey,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(220),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border:
                    Border.all(color: AppColors.primary.withAlpha(30)),
                boxShadow: AppShadows.md(AppColors.primary),
              ),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PremiumField(
                      controller: _displayNameController,
                      label: 'Display Name',
                      icon: Icons.person_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Enter display name'
                              : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PremiumField(
                      controller: _bioController,
                      label: 'Bio',
                      icon: Icons.edit_note_rounded,
                      maxLines: 3,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Enter a short bio'
                              : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PremiumField(
                      controller: _experienceController,
                      label: 'Years Experience',
                      icon: Icons.work_history_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || int.tryParse(v) == null)
                              ? 'Enter years of experience'
                              : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Expanded(
                        child: _PremiumField(
                          controller: _cityController,
                          label: 'City',
                          icon: Icons.location_city_rounded,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Enter city'
                                  : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _PremiumField(
                          controller: _areaController,
                          label: 'Area',
                          icon: Icons.map_rounded,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Enter area'
                                  : null,
                        ),
                      ),
                    ]),
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 2: Services ─────────────────────────────────────────────
  Widget _buildStep2Services() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.primary.withAlpha(30)),
              boxShadow: AppShadows.md(AppColors.primary),
            ),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What services do you offer?',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select all that apply. You can update later.',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: _availableServices.map((service) {
                    final selected = _selectedServices.contains(service);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (selected) {
                            _selectedServices.remove(service);
                          } else {
                            _selectedServices.add(service);
                            _servicePriceControllers.putIfAbsent(
                                service,
                                () => TextEditingController());
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? const LinearGradient(colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF8B5CF6)
                                ])
                              : null,
                          color: selected ? null : Colors.grey.shade100,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : Colors.grey.shade200,
                          ),
                          boxShadow: selected
                              ? AppShadows.sm(AppColors.primary)
                              : null,
                        ),
                        child: Text(
                          service,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_selectedServices.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedServices.length} service${_selectedServices.length > 1 ? "s" : ""} selected',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 3: Portfolio ────────────────────────────────────────────
  Widget _buildStep3Portfolio() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.primary.withAlpha(30)),
              boxShadow: AppShadows.md(AppColors.primary),
            ),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Show your best work',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload up to 3 portfolio photos',
                  style:
                      TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Upload area
                if (_portfolio.length < 3)
                  GestureDetector(
                    onTap: _pickPortfolioImage,
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(80),
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                        color: AppColors.primary.withAlpha(8),
                      ),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                color: AppColors.primary.withAlpha(160),
                                size: 32),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add photo',
                              style: TextStyle(
                                color: AppColors.primary.withAlpha(160),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${_portfolio.length}/3 uploaded',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 11),
                            ),
                          ]),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),

                // Portfolio items
                ..._portfolio.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          child: Image.memory(item.bytes,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title.isEmpty
                                      ? 'Portfolio item'
                                      : item.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.description.isEmpty
                                      ? 'No description'
                                      : item.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11),
                                ),
                              ]),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 20),
                          onPressed: () =>
                              setState(() => _portfolio.remove(item)),
                        ),
                      ]),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 4: Pricing ──────────────────────────────────────────────
  Widget _buildStep4Pricing() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Form(
        key: _pricingKey,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(220),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.primary.withAlpha(30)),
                boxShadow: AppShadows.md(AppColors.primary),
              ),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set your rates',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Transparent pricing builds trust',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PremiumField(
                    controller: _hourlyRateController,
                    label: 'Hourly Rate',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                    prefix: '₹ ',
                    validator: (v) =>
                        (v == null || num.tryParse(v) == null)
                            ? 'Enter hourly rate'
                            : null,
                  ),
                  if (_selectedServices.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Per-service pricing:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ..._selectedServices.map((service) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.md),
                          child: _PremiumField(
                            controller: _servicePriceControllers
                                .putIfAbsent(
                                    service,
                                    () => TextEditingController()),
                            label: service,
                            icon: Icons.price_check_rounded,
                            keyboardType: TextInputType.number,
                            prefix: '₹ ',
                            validator: (v) =>
                                (v == null || num.tryParse(v) == null)
                                    ? 'Enter price for $service'
                                    : null,
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 5: Review & Publish ─────────────────────────────────────
  Widget _buildStep5Review() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.primary.withAlpha(30)),
              boxShadow: AppShadows.md(AppColors.primary),
            ),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Big name
              Text(
                _displayNameController.text.isEmpty
                    ? 'Your Name'
                    : _displayNameController.text,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Text(
                _bioController.text.isEmpty
                    ? 'No bio entered'
                    : _bioController.text,
                style: TextStyle(
                    color: Colors.grey.shade600, height: 1.4, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ReviewRow(Icons.location_on_rounded,
                  '${_cityController.text}, ${_areaController.text}'),
              _ReviewRow(Icons.work_history_rounded,
                  '${_experienceController.text} years experience'),
              _ReviewRow(Icons.currency_rupee_rounded,
                  '₹${_hourlyRateController.text}/hr'),
              _ReviewRow(Icons.construction_rounded,
                  _selectedServices.isEmpty
                      ? 'No services selected'
                      : _selectedServices.join(', ')),
              _ReviewRow(Icons.photo_library_rounded,
                  '${_portfolio.length} portfolio item${_portfolio.length != 1 ? 's' : ''}'),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withAlpha(12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: const Color(0xFFEF4444).withAlpha(60)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 12))),
                  ]),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  // ── Navigation row ───────────────────────────────────────────────
  Widget _buildNavRow() {
    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      child: Row(children: [
        if (_currentStep > 0)
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: _previousStep,
              child: Container(
                height: 52,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_ios_new_rounded,
                          size: 14, color: Color(0xFF374151)),
                      SizedBox(width: 6),
                      Text('Back',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF374151))),
                    ]),
              ),
            ),
          ),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _submitting ? null : _nextStep,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.md(AppColors.primary),
              ),
              child: Center(
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _currentStep == _totalSteps - 1
                            ? '🚀 Publish Profile'
                            : 'Continue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? prefix;

  const _PremiumField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ReviewRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, height: 1.3),
          ),
        ),
      ]),
    );
  }
}
