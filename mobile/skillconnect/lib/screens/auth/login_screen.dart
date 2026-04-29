import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final String selectedRole; // 'customer' or 'professional'
  const LoginScreen({super.key, this.selectedRole = 'customer'});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  bool _obscure = true;
  String? _error;

  bool get _isPro => widget.selectedRole == 'professional';

  List<Color> get _gradient => _isPro
      ? const [Color(0xFF06B6D4), Color(0xFF3B82F6)]
      : const [Color(0xFF6366F1), Color(0xFF8B5CF6)];

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final auth = context.read<AuthService>();
    final err = await auth.login(email: _emailCtl.text.trim(), password: _passwordCtl.text);
    if (err != null) {
      setState(() => _error = err);
    } else if (mounted) {
      // Verify the logged-in user matches the selected role
      final loggedRole = auth.user?['role'];
      if (loggedRole != null && loggedRole != widget.selectedRole) {
        await auth.logout();
        setState(() => _error = 'This account is registered as a ${loggedRole == "professional" ? "Professional" : "Customer"}. Please use the correct login.');
        return;
      }
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _fillDemo() {
    if (_isPro) {
      _emailCtl.text = 'pro1@demo.com';
    } else {
      _emailCtl.text = 'customer@demo.com';
    }
    _passwordCtl.text = 'demo123';
    setState(() {});
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

                  // Back button + role badge
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
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isPro ? 'Professional' : 'Customer',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ]),
                    ),
                  ]),

                  const SizedBox(height: 32),

                  // Logo
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: _gradient),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: _gradient.first.withAlpha(60), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Icon(
                        _isPro ? Icons.work_rounded : Icons.handyman_rounded,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isPro ? 'Professional Login' : 'Customer Login',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isPro
                        ? 'Sign in to manage your bookings & profile'
                        : 'Sign in to find & hire skilled professionals',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                  const SizedBox(height: 28),

                  // Error
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                      ]),
                    ),

                  // Email
                  TextFormField(
                    controller: _emailCtl,
                    decoration: const InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                  ),
                  const SizedBox(height: 14),

                  // Password
                  TextFormField(
                    controller: _passwordCtl,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    obscureText: _obscure,
                    validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 characters',
                  ),
                  const SizedBox(height: 24),

                  // Sign In button
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
                              _isPro ? 'Sign In as Professional' : 'Sign In as Customer',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Demo credentials
                  GestureDetector(
                    onTap: _fillDemo,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _isPro ? Colors.cyan.shade50 : Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isPro ? Colors.cyan.shade100 : Colors.indigo.shade100),
                      ),
                      child: Row(children: [
                        Icon(Icons.touch_app_rounded, size: 16, color: _isPro ? Colors.cyan.shade700 : Colors.indigo.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isPro
                                ? 'Tap to fill: pro1@demo.com / demo123'
                                : 'Tap to fill: customer@demo.com / demo123',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isPro ? Colors.cyan.shade800 : Colors.indigo.shade800,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(children: [
                    Expanded(child: Divider(color: Colors.grey.shade200)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade200)),
                  ]),

                  const SizedBox(height: 20),

                  // Register button
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _gradient.first.withAlpha(80), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => RegisterScreen(selectedRole: widget.selectedRole)),
                      ),
                      child: Text(
                        _isPro ? 'Create Professional Account' : 'Create Customer Account',
                        style: TextStyle(
                          color: _gradient.first,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // What you get section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isPro ? 'As a Professional, you get:' : 'As a Customer, you get:',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        ...(_isPro
                            ? [
                                _featureRow(Icons.event_note_rounded, 'Manage bookings & schedule'),
                                _featureRow(Icons.star_rounded, 'Build your reputation with reviews'),
                                _featureRow(Icons.trending_up_rounded, 'Grow your client base'),
                                _featureRow(Icons.account_balance_wallet_rounded, 'Zero commission on earnings'),
                              ]
                            : [
                                _featureRow(Icons.search_rounded, 'Browse 40+ service categories'),
                                _featureRow(Icons.verified_rounded, 'Hire verified professionals'),
                                _featureRow(Icons.chat_rounded, 'Chat & book directly'),
                                _featureRow(Icons.star_rounded, 'Read authentic reviews'),
                              ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: _gradient.first),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700))),
      ]),
    );
  }
}
