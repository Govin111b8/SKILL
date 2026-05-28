import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class ProfessionalOnboardingScreen extends StatefulWidget {
  const ProfessionalOnboardingScreen({super.key});

  @override
  State<ProfessionalOnboardingScreen> createState() => _ProfessionalOnboardingScreenState();
}

class _ProfessionalOnboardingScreenState extends State<ProfessionalOnboardingScreen> {
  final _basicKey = GlobalKey<FormState>();
  final _pricingKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final List<String> _selectedServices = [];
  final List<_PortfolioDraft> _portfolio = [];
  final Map<String, TextEditingController> _servicePriceControllers = {};
  final List<String> _availableServices = const ['AC Repair', 'Deep Cleaning', 'Salon at Home', 'Plumbing', 'Electrical', 'Tutoring'];
  int _currentStep = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _hourlyRateController.dispose();
    for (final controller in _servicePriceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPortfolioImage() async {
    if (_portfolio.length >= 3) return;
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      final titleController = TextEditingController();
      final descriptionController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Portfolio details'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
          ],
        ),
      );
      if (confirmed != true) return;
      setState(() {
        _portfolio.add(_PortfolioDraft(path: picked.path, bytes: bytes, title: titleController.text.trim(), description: descriptionController.text.trim()));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
    }
  }

  Future<void> _submit() async {
    if (!_basicKey.currentState!.validate() || !_pricingKey.currentState!.validate()) {
      return;
    }
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
        'years_experience': int.tryParse(_experienceController.text.trim()) ?? 0,
        'city': _cityController.text.trim(),
        'area': _areaController.text.trim(),
        'hourly_rate': num.tryParse(_hourlyRateController.text.trim()) ?? 0,
        'portfolio_drafts': _portfolio.map((e) => e.toJson()).toList(),
      }, auth: true);
      for (final service in _selectedServices) {
        await ApiService.post('/services/me', {
          'service_name': service,
          'price': num.tryParse(_servicePriceControllers[service]?.text.trim() ?? '') ?? 0,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Professional Onboarding')),
      body: Stepper(
        currentStep: _currentStep,
        onStepTapped: (index) => setState(() => _currentStep = index),
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(children: [
            FilledButton(
              onPressed: _submitting
                  ? null
                  : () {
                      if (_currentStep < 5) {
                        setState(() => _currentStep += 1);
                      } else {
                        _submit();
                      }
                    },
              child: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_currentStep == 5 ? 'Publish' : 'Continue'),
            ),
            const SizedBox(width: 12),
            if (_currentStep > 0)
              TextButton(onPressed: _submitting ? null : () => setState(() => _currentStep -= 1), child: const Text('Back')),
          ]),
        ),
        steps: [
          Step(
            title: const Text('Welcome'),
            content: const Text('Set up your professional business profile, service list, portfolio, pricing, and verification in a few quick steps.'),
          ),
          Step(
            title: const Text('Basic Info'),
            content: Form(
              key: _basicKey,
              child: Column(children: [
                TextFormField(controller: _displayNameController, decoration: const InputDecoration(labelText: 'Display name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter display name' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a short bio' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _experienceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Years experience'), validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter years of experience' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'City'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter city' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _areaController, decoration: const InputDecoration(labelText: 'Area / locality'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter area' : null),
              ]),
            ),
          ),
          Step(
            title: const Text('Services'),
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableServices.map((service) {
                final selected = _selectedServices.contains(service);
                return FilterChip(
                  label: Text(service),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedServices.add(service);
                        _servicePriceControllers.putIfAbsent(service, () => TextEditingController());
                      } else {
                        _selectedServices.remove(service);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          Step(
            title: const Text('Portfolio'),
            content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FilledButton.icon(onPressed: _pickPortfolioImage, icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('Upload photo')),
              const SizedBox(height: 12),
              ..._portfolio.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(item.bytes, width: 64, height: 64, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.title.isEmpty ? 'Portfolio item' : item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(item.description.isEmpty ? 'No description' : item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ])),
                    ]),
                  )),
            ]),
          ),
          Step(
            title: const Text('Pricing'),
            content: Form(
              key: _pricingKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextFormField(controller: _hourlyRateController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Hourly rate', prefixText: '₹'), validator: (v) => (v == null || num.tryParse(v) == null) ? 'Enter hourly rate' : null),
                const SizedBox(height: 16),
                ..._selectedServices.map((service) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _servicePriceControllers.putIfAbsent(service, () => TextEditingController()),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: '$service price', prefixText: '₹'),
                        validator: (v) => (v == null || num.tryParse(v) == null) ? 'Enter price for $service' : null,
                      ),
                    )),
              ]),
            ),
          ),
          Step(
            title: const Text('Review & Publish'),
            content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_displayNameController.text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(_bioController.text),
              const SizedBox(height: 8),
              Text('Services: ${_selectedServices.join(', ')}'),
              const SizedBox(height: 8),
              Text('Portfolio items: ${_portfolio.length}/3'),
              const SizedBox(height: 8),
              Text('Hourly rate: ₹${_hourlyRateController.text.isEmpty ? '0' : _hourlyRateController.text}'),
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

class _PortfolioDraft {
  final String path;
  final Uint8List bytes;
  final String title;
  final String description;
  const _PortfolioDraft({required this.path, required this.bytes, required this.title, required this.description});

  Map<String, dynamic> toJson() => {
        'path': path,
        'title': title,
        'description': description,
      };
}
