import 'package:flutter/material.dart';
import '../../services/api_service.dart';

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

    setState(() => _saving = true);
    try {
      final profileId = widget.profile['id'];
      await ApiService.put('/professionals/$profileId', {
        'headline': _headlineCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'years_of_experience': int.tryParse(_experienceCtrl.text) ?? 0,
        'pricing_estimate': double.tryParse(_pricingCtrl.text) ?? 0,
        'service_location_radius_km': double.tryParse(_radiusCtrl.text) ?? 25,
      }, auth: true);

      // Update availability separately
      await ApiService.put('/professionals/me/availability', {
        'availability_status': _availability,
      }, auth: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Professional Profile'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
            label: Text(_saving ? 'Saving' : 'Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Basic Info', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                TextField(
                  controller: _headlineCtrl,
                  decoration: const InputDecoration(labelText: 'Headline', hintText: 'e.g. Expert Plumber & Pipe Specialist', prefixIcon: Icon(Icons.title)),
                  maxLength: 100,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bioCtrl,
                  decoration: const InputDecoration(labelText: 'Bio / About', hintText: 'Describe your skills and experience...', prefixIcon: Icon(Icons.person), alignLabelWithHint: true),
                  maxLines: 5,
                  maxLength: 1000,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          Text('Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                TextField(
                  controller: _experienceCtrl,
                  decoration: const InputDecoration(labelText: 'Years of Experience', prefixIcon: Icon(Icons.work_history)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pricingCtrl,
                  decoration: const InputDecoration(labelText: 'Starting Price (\$)', prefixIcon: Icon(Icons.attach_money)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _radiusCtrl,
                  decoration: const InputDecoration(labelText: 'Service Radius (km)', prefixIcon: Icon(Icons.radar)),
                  keyboardType: TextInputType.number,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          Text('Availability', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: ['available', 'busy', 'offline'].map((status) {
                  final icon = status == 'available' ? Icons.check_circle : status == 'busy' ? Icons.schedule : Icons.circle_outlined;
                  final color = status == 'available' ? Colors.green : status == 'busy' ? Colors.orange : Colors.grey;
                  return RadioListTile<String>(
                    value: status,
                    groupValue: _availability,
                    onChanged: (v) => setState(() => _availability = v!),
                    title: Text(status[0].toUpperCase() + status.substring(1), style: const TextStyle(fontWeight: FontWeight.w500)),
                    secondary: Icon(icon, color: color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save Changes'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}
