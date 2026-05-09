import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final String selectedRole; // 'customer', 'professional', 'agent', or 'admin'
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
  bool get _isAgent => widget.selectedRole == 'agent';
  bool get _isAdmin => widget.selectedRole == 'admin';

  List<Color> get _gradient {
    switch (widget.selectedRole) {
      case 'professional':
        return const [Color(0xFF06B6D4), Color(0xFF3B82F6)];
      case 'agent':
        return const [Color(0xFF10B981), Color(0xFF059669)];
      case 'admin':
        return const [Color(0xFFEF4444), Color(0xFFDC2626)];
      default:
        return const [Color(0xFF6366F1), Color(0xFF8B5CF6)];
    }
  }

  String get _roleLabel {
    switch (widget.selectedRole) {
      case 'professional': return 'Professional';
      case 'agent': return 'Agent';
      case 'admin': return 'Admin';
      default: return 'Customer';
    }
  }

  IconData get _roleIcon {
    switch (widget.selectedRole) {
      case 'professional': return Icons.work_rounded;
      case 'agent': return Icons.groups_rounded;
      case 'admin': return Icons.admin_panel_settings_rounded;
      default: return Icons.person_rounded;
    }
  }

  IconData get _logoIcon {
    switch (widget.selectedRole) {
      case 'professional': return Icons.work_rounded;
      case 'agent': return Icons.groups_rounded;
      case 'admin': return Icons.shield_rounded;
      default: return Icons.handyman_rounded;
    }
  }

  String get _loginTitle => '$_roleLabel Login';

  String get _loginSubtitle {
    switch (widget.selectedRole) {
      case 'professional': return 'Sign in to manage your bookings & profile';
      case 'agent': return 'Sign in to manage referrals & commissions';
      case 'admin': return 'Sign in to the admin control panel';
      default: return 'Sign in to find & hire skilled professionals';
    }
  }

  String get _buttonLabel => 'Sign In as $_roleLabel';

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
        final roleLabels = {'professional': 'Professional', 'customer': 'Customer', 'agent': 'Agent', 'admin': 'Admin'};
        final label = roleLabels[loggedRole] ?? loggedRole;
        await auth.logout();
        setState(() => _error = 'This account is registered as a $label. Please use the correct login.');
        return;
      }
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _fillDemo() {
    switch (widget.selectedRole) {
      case 'professional':
        _emailCtl.text = 'pro1@demo.com';
        break;
      case 'agent':
        _emailCtl.text = 'agent@demo.com';
        break;
      case 'admin':
        _emailCtl.text = 'admin@demo.com';
        break;
      default:
        _emailCtl.text = 'customer@demo.com';
        break;
    }
    _passwordCtl.text = 'demo123';
    setState(() {});
  }

  Future<void> _demoLogin() async {
    _fillDemo();
    // Small delay so user can see the fields fill
    await Future.delayed(const Duration(milliseconds: 200));
    _submit();
  }

  bool get _hasDemoCredentials => true; // All roles have demo for now

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
                        Icon(_roleIcon, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          _roleLabel,
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
                      child: Icon(_logoIcon, size: 38, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _loginTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _loginSubtitle,
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
                              _buttonLabel,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Demo credentials — prominent one-tap login button
                  if (_hasDemoCredentials) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _gradient.first.withAlpha(60), width: 2, style: BorderStyle.solid),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: _gradient.first.withAlpha(12),
                        ),
                        onPressed: auth.loading ? null : _demoLogin,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🚀 ', style: TextStyle(fontSize: 20)),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Try Demo — Instant $_roleLabel Login',
                                  style: TextStyle(
                                    color: _gradient.first,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  _isAgent ? 'agent@demo.com'
                                    : _isPro ? 'pro1@demo.com'
                                    : _isAdmin ? 'admin@demo.com'
                                    : 'customer@demo.com',
                                  style: TextStyle(
                                    color: _gradient.first.withAlpha(150),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

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

                  // Register button (not shown for admin — admin accounts are created by existing admins)
                  if (!_isAdmin)
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
                          'Create $_roleLabel Account',
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
                          'As a $_roleLabel, you get:',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        ..._featuresForRole(),
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

  List<Widget> _featuresForRole() {
    switch (widget.selectedRole) {
      case 'professional':
        return [
          _featureRow(Icons.event_note_rounded, 'Manage bookings & schedule'),
          _featureRow(Icons.star_rounded, 'Build your reputation with reviews'),
          _featureRow(Icons.trending_up_rounded, 'Grow your client base'),
          _featureRow(Icons.account_balance_wallet_rounded, 'Zero commission on earnings'),
        ];
      case 'agent':
        return [
          _featureRow(Icons.people_alt_rounded, 'Refer professionals to the platform'),
          _featureRow(Icons.monetization_on_rounded, 'Earn commissions on referrals'),
          _featureRow(Icons.leaderboard_rounded, 'Compete on the agent leaderboard'),
          _featureRow(Icons.account_balance_wallet_rounded, 'Track earnings & payouts'),
        ];
      case 'admin':
        return [
          _featureRow(Icons.dashboard_rounded, 'Full platform dashboard & analytics'),
          _featureRow(Icons.people_rounded, 'Manage users, pros & agents'),
          _featureRow(Icons.verified_user_rounded, 'Review KYC & verifications'),
          _featureRow(Icons.report_rounded, 'Handle disputes & reports'),
        ];
      default:
        return [
          _featureRow(Icons.search_rounded, 'Browse 40+ service categories'),
          _featureRow(Icons.verified_rounded, 'Hire verified professionals'),
          _featureRow(Icons.chat_rounded, 'Chat & book directly'),
          _featureRow(Icons.star_rounded, 'Read authentic reviews'),
        ];
    }
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
