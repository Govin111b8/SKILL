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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _gradient.last,
      body: Stack(
        children: [
          // Full gradient background
          Container(
            width: double.infinity,
            height: size.height * 0.45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_gradient.first, _gradient.last],
              ),
            ),
          ),

          // Decorative circles on gradient background
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(18),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 60,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(18),
              ),
            ),
          ),

          // Main scrollable content
          SafeArea(
            child: Column(
              children: [
                // Top section — gradient area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.white.withAlpha(60)),
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
                    ],
                  ),
                ),

                // Logo + title
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(255),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Icon(_logoIcon, size: 36, color: _gradient.first),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _loginTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _loginSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // White card slides up from bottom
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Error banner
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
                            _buildLabel('Email Address'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailCtl,
                              decoration: _inputDecor('Enter your email', Icons.email_outlined),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                            ),
                            const SizedBox(height: 18),

                            // Password
                            _buildLabel('Password'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordCtl,
                              decoration: _inputDecor('Enter your password', Icons.lock_outlined).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.grey.shade400),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              obscureText: _obscure,
                              validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 characters',
                            ),
                            const SizedBox(height: 28),

                            // Sign In button
                            _GradientButton(
                              label: _buttonLabel,
                              gradient: _gradient,
                              loading: auth.loading,
                              onTap: _submit,
                            ),
                            const SizedBox(height: 12),

                            // Demo button
                            if (_hasDemoCredentials)
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: _gradient.first.withAlpha(80), width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: auth.loading ? null : _demoLogin,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('🚀', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Try Demo Login',
                                          style: TextStyle(color: _gradient.first, fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                        Text(
                                          _isAgent ? 'agent@demo.com' : _isPro ? 'pro1@demo.com' : _isAdmin ? 'admin@demo.com' : 'customer@demo.com',
                                          style: TextStyle(color: _gradient.first.withAlpha(150), fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                            if (!_isAdmin) ...[
                              const SizedBox(height: 20),
                              Row(children: [
                                Expanded(child: Divider(color: Colors.grey.shade200)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('or', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade200)),
                              ]),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: _gradient.first.withAlpha(80), width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => RegisterScreen(selectedRole: widget.selectedRole)),
                                ),
                                child: Text(
                                  'Create $_roleLabel Account',
                                  style: TextStyle(color: _gradient.first, fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // What you get section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _gradient.first.withAlpha(8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _gradient.first.withAlpha(30)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'As a $_roleLabel, you get:',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _gradient.first),
                                  ),
                                  const SizedBox(height: 10),
                                  ..._featuresForRole(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
      );

  InputDecoration _inputDecor(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _gradient.first, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
      );

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

class _GradientButton extends StatelessWidget {
  final String label;
  final List<Color> gradient;
  final bool loading;
  final VoidCallback? onTap;

  const _GradientButton({
    required this.label,
    required this.gradient,
    required this.loading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: loading ? null : LinearGradient(colors: gradient),
          color: loading ? Colors.grey.shade200 : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: loading
              ? []
              : [BoxShadow(color: gradient.first.withAlpha(80), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey))
            : Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
