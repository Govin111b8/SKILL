import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String selectedRole;
  const RegisterScreen({super.key, this.selectedRole = 'customer'});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _locationCtl = TextEditingController();
  bool _obscure = true;
  String? _error;

  bool get _isPro => widget.selectedRole == 'professional';

  List<Color> get _gradient => _isPro
      ? const [Color(0xFF06B6D4), Color(0xFF3B82F6)]
      : const [Color(0xFF6366F1), Color(0xFF8B5CF6)];

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _passwordCtl.dispose();
    _phoneCtl.dispose();
    _locationCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final auth = context.read<AuthService>();
    final err = await auth.register(
      name: _nameCtl.text.trim(),
      email: _emailCtl.text.trim(),
      password: _passwordCtl.text,
      phone: _phoneCtl.text.trim(),
      role: widget.selectedRole,
      location: _locationCtl.text.trim(),
    );
    if (err != null) {
      setState(() => _error = err);
    } else if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_gradient.first.withAlpha(20), Colors.white],
            stops: const [0, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // Back + role badge
                  Row(children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: _gradient),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          _isPro ? Icons.work_rounded : Icons.person_rounded,
                          size: 14, color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isPro ? 'Professional' : 'Customer',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ]),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Header
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: _gradient),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: _gradient.first.withAlpha(50), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Icon(
                        _isPro ? Icons.work_rounded : Icons.person_add_rounded,
                        size: 32, color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isPro ? 'Join as Professional' : 'Create Account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800, letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isPro
                        ? 'Start getting bookings & grow your business'
                        : 'Find and hire the best professionals near you',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
                  ),
                  const SizedBox(height: 24),

                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                      ]),
                    ),

                  TextFormField(
                    controller: _nameCtl,
                    decoration: InputDecoration(
                      hintText: _isPro ? 'Business / Full Name' : 'Full Name',
                      prefixIcon: const Icon(Icons.person_outlined),
                    ),
                    validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtl,
                    decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v != null && v.contains('@') ? null : 'Valid email required',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtl,
                    decoration: InputDecoration(
                      hintText: 'Password (min 6 chars)',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    obscureText: _obscure,
                    validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 characters',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtl,
                    decoration: const InputDecoration(hintText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationCtl,
                    decoration: InputDecoration(
                      hintText: _isPro ? 'Service Location (e.g. Mumbai, MH)' : 'City / Location',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
                  ),

                  const SizedBox(height: 24),

                  // Register button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gradient.first,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: auth.loading ? null : _submit,
                      child: auth.loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              _isPro ? 'Register as Professional' : 'Create My Account',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Switch to login
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen(selectedRole: widget.selectedRole)),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(color: _gradient.first, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_isPro) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.cyan.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.cyan.shade100),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.cyan.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'After registration, complete your profile to start receiving bookings. You can add your skills, portfolio, and pricing from the dashboard.',
                            style: TextStyle(fontSize: 12, color: Colors.cyan.shade800, height: 1.4),
                          ),
                        ),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
