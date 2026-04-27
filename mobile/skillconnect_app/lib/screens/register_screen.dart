import 'package:flutter/material.dart';
import '../services/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  final AuthProvider auth;
  const RegisterScreen({super.key, required this.auth});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirmPass = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _experience = TextEditingController();
  String _role = 'customer';
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pass.text != _confirmPass.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final data = <String, dynamic>{
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _pass.text,
        'phone': _phone.text.trim(),
        'role': _role,
        'location': _location.text.trim(),
      };
      if (_role == 'professional') {
        data['headline'] = _headline.text.trim();
        data['bio'] = _bio.text.trim();
        data['years_of_experience'] = int.tryParse(_experience.text) ?? 0;
      }
      await widget.auth.register(data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          if (_error != null) Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
            child: Text(_error!, style: TextStyle(color: Colors.red[700])),
          ),

          // Role toggle
          const Text('I am a:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'customer', label: Text('Customer'), icon: Icon(Icons.person)),
              ButtonSegment(value: 'professional', label: Text('Professional'), icon: Icon(Icons.work)),
            ],
            selected: {_role},
            onSelectionChanged: (v) => setState(() => _role = v.first),
          ),
          const SizedBox(height: 20),

          TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress, validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outlined)), validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _confirmPass, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outlined)), validator: (v) => v != _pass.text ? 'Passwords must match' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone, validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _location, decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on_outlined)), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),

          if (_role == 'professional') ...[
            const SizedBox(height: 24),
            const Divider(),
            const Text('Professional Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(controller: _headline, decoration: const InputDecoration(labelText: 'Professional Headline', hintText: 'e.g. Licensed Plumber')),
            const SizedBox(height: 16),
            TextFormField(controller: _bio, decoration: const InputDecoration(labelText: 'Bio', hintText: 'Tell customers about yourself...'), maxLines: 3),
            const SizedBox(height: 16),
            TextFormField(controller: _experience, decoration: const InputDecoration(labelText: 'Years of Experience', prefixIcon: Icon(Icons.work_history)), keyboardType: TextInputType.number),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _register,
              child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create Account'),
            ),
          ),
        ]),
      ),
    );
  }
}
