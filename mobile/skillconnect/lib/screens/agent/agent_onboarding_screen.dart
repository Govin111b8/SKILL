import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

class AgentOnboardingScreen extends StatefulWidget {
  const AgentOnboardingScreen({super.key});

  @override
  State<AgentOnboardingScreen> createState() => _AgentOnboardingScreenState();
}

class _AgentOnboardingScreenState extends State<AgentOnboardingScreen> {
  final _personalKey = GlobalKey<FormState>();
  final _bankKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _territoryController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _holderController = TextEditingController();
  int _currentStep = 0;
  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _territoryController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_personalKey.currentState!.validate() || !_bankKey.currentState!.validate()) {
      setState(() => _currentStep = 0);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ApiService.post('/agents/register', {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'referral_territory': _territoryController.text.trim(),
      }, auth: true);
      await ApiService.post('/agents/me/kyc', {
        'account_number': _accountController.text.trim(),
        'ifsc': _ifscController.text.trim(),
        'account_holder_name': _holderController.text.trim(),
      }, auth: true);
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _submitting = false);
  }

  void _goNext() {
    HapticFeedback.mediumImpact();
    if (_currentStep < 2) {
      if (_currentStep == 0 && !_personalKey.currentState!.validate()) return;
      if (_currentStep == 1 && !_bankKey.currentState!.validate()) return;
      setState(() => _currentStep += 1);
    } else {
      _submit();
    }
  }

  void _goBack() {
    HapticFeedback.mediumImpact();
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return PremiumScrollScaffold(
        backgroundColor: const Color(0xFFF5F7FF),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              PremiumHeroHeader(
                title: 'Application sent',
                subtitle: 'Your profile and KYC details are safely submitted for review.',
                icon: Icons.verified_rounded,
                gradient: AppColors.successGradient,
                chips: const [
                  PremiumStatChip(label: 'Verification queued', color: Colors.white, icon: Icons.bolt_rounded),
                ],
              ),
              PremiumGlassCard(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                gradient: [Colors.white.withAlpha(235), Colors.white.withAlpha(190)],
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.7, end: 1),
                      duration: AppDurations.slow,
                      curve: Curves.elasticOut,
                      builder: (context, value, child) => Transform.scale(scale: value, child: child),
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.successGradient),
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.xl(AppColors.success),
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 60),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const Text(
                      'Application submitted!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.7),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'We have your details and KYC request. You can track approval from your dashboard.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700, height: 1.6, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    SizedBox(
                      width: double.infinity,
                      child: PremiumGradientButton(
                        label: 'Go to Home',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final stepMeta = _stepMeta(_currentStep);
    return PremiumScrollScaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumHeroHeader(
              title: 'Agent Onboarding',
              subtitle: 'Complete your premium setup in three elegant steps and start earning faster.',
              icon: Icons.person_add_alt_1_rounded,
              gradient: const [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF0891B2)],
              chips: [
                PremiumStatChip(
                  label: 'Step ${_currentStep + 1} of 3',
                  color: Colors.white,
                  icon: Icons.auto_awesome_rounded,
                ),
                const PremiumStatChip(
                  label: 'Secure verification',
                  color: Colors.white,
                  icon: Icons.shield_rounded,
                ),
              ],
            ),
            PremiumGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepProgressIndicator(currentStep: _currentStep),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: stepMeta.gradient),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: AppShadows.lg(stepMeta.gradient.first),
                        ),
                        child: Icon(stepMeta.icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stepMeta.title,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              stepMeta.subtitle,
                              style: TextStyle(color: Colors.grey.shade700, height: 1.45, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AnimatedSwitcher(
                    duration: AppDurations.normal,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _buildStepContent(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _submitting ? null : _goBack,
                    child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w700)),
                  )
                else
                  const SizedBox(width: AppSpacing.xl),
                const Spacer(),
                if (_submitting)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  )
                else
                  PremiumGradientButton(
                    label: _currentStep == 2 ? 'Submit application' : 'Next',
                    icon: _currentStep == 2 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                    colors: _currentStep == 2 ? AppColors.successGradient : AppColors.primaryGradient,
                    onPressed: _goNext,
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.lg),
              PremiumGlassCard(
                gradient: [AppColors.errorLight.withAlpha(210), Colors.white.withAlpha(200)],
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Form(
          key: _personalKey,
          child: Column(
            key: const ValueKey('personal'),
            children: [
              _PremiumTextField(
                controller: _nameController,
                label: 'Full name',
                hint: 'Enter your full name',
                prefixIcon: Icons.person_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PremiumTextField(
                controller: _phoneController,
                label: 'Phone number',
                hint: 'Enter your mobile number',
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.trim().length < 10) ? 'Enter a valid phone number' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PremiumTextField(
                controller: _cityController,
                label: 'City',
                hint: 'Where do you operate?',
                prefixIcon: Icons.location_city_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your city' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PremiumTextField(
                controller: _territoryController,
                label: 'Referral territory',
                hint: 'Your primary territory',
                prefixIcon: Icons.map_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your territory' : null,
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _bankKey,
          child: Column(
            key: const ValueKey('bank'),
            children: [
              _PremiumTextField(
                controller: _accountController,
                label: 'Account number',
                hint: 'Enter your bank account number',
                prefixIcon: Icons.account_balance_wallet_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.trim().length < 8) ? 'Enter a valid account number' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PremiumTextField(
                controller: _ifscController,
                label: 'IFSC code',
                hint: 'Enter IFSC code',
                prefixIcon: Icons.code_rounded,
                textCapitalization: TextCapitalization.characters,
                validator: (v) => (v == null || v.trim().length < 6) ? 'Enter a valid IFSC code' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PremiumTextField(
                controller: _holderController,
                label: 'Account holder name',
                hint: 'Name on your bank account',
                prefixIcon: Icons.badge_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter account holder name' : null,
              ),
            ],
          ),
        );
      default:
        return Column(
          key: const ValueKey('review'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.success.withAlpha(24), AppColors.primary.withAlpha(12)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.success.withAlpha(50)),
              ),
              child: Row(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.85, end: 1),
                    duration: AppDurations.slow,
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) => Transform.scale(scale: value, child: child),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: AppColors.successGradient),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ready to complete',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Review every detail once more and submit your onboarding package.',
                          style: TextStyle(color: Colors.grey.shade700, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _ReviewRow(label: 'Name', value: _nameController.text),
            _ReviewRow(label: 'Phone', value: _phoneController.text),
            _ReviewRow(label: 'City', value: _cityController.text),
            _ReviewRow(label: 'Territory', value: _territoryController.text),
            _ReviewRow(label: 'Account holder', value: _holderController.text),
            _ReviewRow(
              label: 'Account number',
              value: _accountController.text.isEmpty ? '—' : '•••• ${_accountController.text.characters.takeLast(4)}',
            ),
            _ReviewRow(label: 'IFSC', value: _ifscController.text),
          ],
        );
    }
  }

  _StepMeta _stepMeta(int index) {
    switch (index) {
      case 0:
        return const _StepMeta(
          title: 'Personal information',
          subtitle: 'Tell us who you are and where you build your referral network.',
          icon: Icons.person_rounded,
          gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        );
      case 1:
        return const _StepMeta(
          title: 'Banking details',
          subtitle: 'Secure payouts with verified account information.',
          icon: Icons.account_balance_rounded,
          gradient: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
        );
      default:
        return const _StepMeta(
          title: 'Complete setup',
          subtitle: 'One final review before your application is submitted.',
          icon: Icons.task_alt_rounded,
          gradient: [Color(0xFF10B981), Color(0xFF059669)],
        );
    }
  }
}

class _StepProgressIndicator extends StatelessWidget {
  final int currentStep;

  const _StepProgressIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const labels = ['Personal', 'Bank', 'Complete'];
    return Row(
      children: List.generate(labels.length * 2 - 1, (index) {
        if (index.isOdd) {
          final active = currentStep >= index ~/ 2 + 1;
          return Expanded(
            child: AnimatedContainer(
              duration: AppDurations.normal,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: active ? AppColors.primaryGradient : [Colors.grey.shade300, Colors.grey.shade200],
                ),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          );
        }
        final stepIndex = index ~/ 2;
        final isActive = currentStep == stepIndex;
        final isComplete = currentStep > stepIndex;
        return AnimatedContainer(
          duration: AppDurations.normal,
          width: 72,
          child: Column(
            children: [
              AnimatedContainer(
                duration: AppDurations.normal,
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isComplete || isActive
                        ? (isComplete ? AppColors.successGradient : AppColors.primaryGradient)
                        : [Colors.white, Colors.grey.shade100],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isComplete
                        ? AppColors.success
                        : isActive
                            ? AppColors.primary
                            : Colors.grey.shade300,
                    width: 1.4,
                  ),
                  boxShadow: isComplete || isActive ? AppShadows.sm(isComplete ? AppColors.success : AppColors.primary) : null,
                ),
                child: Icon(
                  isComplete
                      ? Icons.check_rounded
                      : stepIndex + 1 == 1
                          ? Icons.person_rounded
                          : stepIndex + 1 == 2
                              ? Icons.account_balance_rounded
                              : Icons.task_alt_rounded,
                  color: isComplete || isActive ? Colors.white : Colors.grey.shade500,
                  size: 20,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                labels[stepIndex],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isComplete || isActive ? AppColors.surfaceDark : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: AppColors.primary),
        labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
        hintStyle: TextStyle(color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.white.withAlpha(180),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: AppColors.primary.withAlpha(35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PremiumGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        gradient: [Colors.white.withAlpha(220), Colors.white.withAlpha(165)],
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepMeta {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  const _StepMeta({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}
