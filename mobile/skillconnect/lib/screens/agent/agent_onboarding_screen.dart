import 'package:flutter/material.dart';
import '../../services/api_service.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Agent Onboarding')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.verified_rounded, size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('Application submitted!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('We have your details and KYC request. You can track approval from your dashboard.', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false), child: const Text('Go to Home')),
            ]),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Agent Onboarding')),
      body: Stepper(
        currentStep: _currentStep,
        onStepTapped: (step) => setState(() => _currentStep = step),
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(children: [
            FilledButton(
              onPressed: _submitting
                  ? null
                  : () {
                      if (_currentStep < 2) {
                        if (_currentStep == 0 && !_personalKey.currentState!.validate()) return;
                        if (_currentStep == 1 && !_bankKey.currentState!.validate()) return;
                        setState(() => _currentStep += 1);
                      } else {
                        _submit();
                      }
                    },
              child: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_currentStep == 2 ? 'Submit' : 'Continue'),
            ),
            const SizedBox(width: 12),
            if (_currentStep > 0)
              TextButton(onPressed: _submitting ? null : () => setState(() => _currentStep -= 1), child: const Text('Back')),
          ]),
        ),
        steps: [
          Step(
            title: const Text('Personal Info'),
            isActive: _currentStep >= 0,
            content: Form(
              key: _personalKey,
              child: Column(children: [
                TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone'), validator: (v) => (v == null || v.trim().length < 10) ? 'Enter a valid phone number' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'City'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your city' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _territoryController, decoration: const InputDecoration(labelText: 'Referral territory'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your territory' : null),
              ]),
            ),
          ),
          Step(
            title: const Text('Bank Details'),
            isActive: _currentStep >= 1,
            content: Form(
              key: _bankKey,
              child: Column(children: [
                TextFormField(controller: _accountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Account number'), validator: (v) => (v == null || v.trim().length < 8) ? 'Enter a valid account number' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _ifscController, decoration: const InputDecoration(labelText: 'IFSC code'), validator: (v) => (v == null || v.trim().length < 6) ? 'Enter a valid IFSC code' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _holderController, decoration: const InputDecoration(labelText: 'Account holder name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter account holder name' : null),
              ]),
            ),
          ),
          Step(
            title: const Text('Confirm'),
            isActive: _currentStep >= 2,
            content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _ReviewRow(label: 'Name', value: _nameController.text),
              _ReviewRow(label: 'Phone', value: _phoneController.text),
              _ReviewRow(label: 'City', value: _cityController.text),
              _ReviewRow(label: 'Territory', value: _territoryController.text),
              _ReviewRow(label: 'Account holder', value: _holderController.text),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ]),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
        Expanded(child: Text(value.isEmpty ? '—' : value)),
      ]),
    );
  }
}
