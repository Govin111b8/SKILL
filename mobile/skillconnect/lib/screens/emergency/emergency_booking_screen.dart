import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_ui.dart';
import '../../theme/design_tokens.dart';

/// Emergency mode — priority booking with faster matching and premium pricing.
class EmergencyBookingScreen extends StatefulWidget {
  const EmergencyBookingScreen({super.key});

  @override
  State<EmergencyBookingScreen> createState() => _EmergencyBookingScreenState();
}

class _EmergencyBookingScreenState extends State<EmergencyBookingScreen> {
  String? _selectedService;
  final _descCtl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  final _emergencyServices = [
    ('Plumbing Emergency', Icons.plumbing, 'Burst pipe, leak, no water'),
    ('Electrical Emergency', Icons.electric_bolt, 'Power outage, sparking, short circuit'),
    ('AC Emergency', Icons.ac_unit, 'Not cooling in extreme heat'),
    ('Lock Emergency', Icons.lock_open, 'Locked out, broken lock'),
    ('Appliance Breakdown', Icons.kitchen, 'Fridge, washing machine failure'),
  ];

  Future<void> _submitEmergency() async {
    if (_selectedService == null) return;
    setState(() => _submitting = true);
    try {
      await ApiService.post(
          '/bookings/emergency',
          {
            'service_type': _selectedService,
            'description': _descCtl.text.trim(),
            'priority': 'urgent',
          },
          auth: true);
      setState(() => _submitted = true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _descCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _buildSuccessScreen(context);
    }
    return _buildRequestScreen(context);
  }

  Widget _buildSuccessScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PremiumBackground(
        dark: true,
        colors: const [
          Color(0xFF1A0A00),
          Color(0xFF2D0F00),
          Color(0xFF1A0A00),
        ],
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFFFF6B35),
                        Color(0xFFFF3B00),
                      ]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3B00).withAlpha(100),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.emergency_rounded,
                        size: 52, color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const Text(
                    'Emergency Request Sent! 🚨',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    "We're finding the nearest available professional. You'll be connected within 5 minutes.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxxl,
                          vertical: AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color(0xFFFF6B35),
                          Color(0xFFFF3B00),
                        ]),
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF3B00).withAlpha(80),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PremiumBackground(
        dark: true,
        colors: const [
          Color(0xFF1A0300),
          Color(0xFF200800),
          Color(0xFF180510),
        ],
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            _buildDarkHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.huge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildWarningBanner(),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      "What's the emergency?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withAlpha(240),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...List.generate(_emergencyServices.length, (i) {
                      final (name, icon, desc) = _emergencyServices[i];
                      final selected = _selectedService == name;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedService = name),
                          child: AnimatedContainer(
                            duration: AppDurations.fast,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? const LinearGradient(colors: [
                                      Color(0x40FF3B00),
                                      Color(0x25FF6B35),
                                    ])
                                  : LinearGradient(colors: [
                                      Colors.white.withAlpha(8),
                                      Colors.white.withAlpha(5),
                                    ]),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFFF3B00)
                                    : Colors.white.withAlpha(20),
                                width: selected ? 2 : 1,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFFF3B00)
                                            .withAlpha(60),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: selected
                                      ? const LinearGradient(colors: [
                                          Color(0xFFFF6B35),
                                          Color(0xFFFF3B00),
                                        ])
                                      : LinearGradient(colors: [
                                          Colors.white.withAlpha(15),
                                          Colors.white.withAlpha(8),
                                        ]),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.lg),
                                ),
                                child: Icon(icon,
                                    color: selected
                                        ? Colors.white
                                        : Colors.white.withAlpha(150),
                                    size: 24),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: selected
                                            ? const Color(0xFFFF6B35)
                                            : Colors.white.withAlpha(220),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      desc,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withAlpha(120),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Color(0xFFFF6B35),
                                      Color(0xFFFF3B00),
                                    ]),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 14),
                                ),
                            ]),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(
                            color: Colors.white.withAlpha(20)),
                      ),
                      child: TextField(
                        controller: _descCtl,
                        maxLines: 3,
                        style: TextStyle(
                            color: Colors.white.withAlpha(220),
                            fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Brief description (optional)',
                          hintStyle: TextStyle(
                              color: Colors.white.withAlpha(80)),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.all(AppSpacing.lg),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    GestureDetector(
                      onTap: (_selectedService != null && !_submitting)
                          ? _submitEmergency
                          : null,
                      child: AnimatedContainer(
                        duration: AppDurations.fast,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg + 4),
                        decoration: BoxDecoration(
                          gradient: _selectedService != null
                              ? const LinearGradient(colors: [
                                  Color(0xFFFF6B35),
                                  Color(0xFFFF3B00),
                                ])
                              : LinearGradient(colors: [
                                  Colors.white.withAlpha(15),
                                  Colors.white.withAlpha(10),
                                ]),
                          borderRadius:
                              BorderRadius.circular(AppRadius.xl),
                          boxShadow: _selectedService != null
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFF3B00)
                                        .withAlpha(100),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_submitting)
                              const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white))
                            else
                              const Icon(Icons.emergency_rounded,
                                  color: Colors.white, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              _submitting
                                  ? 'Submitting...'
                                  : 'Request Emergency Service',
                              style: TextStyle(
                                color: _selectedService != null
                                    ? Colors.white
                                    : Colors.white.withAlpha(80),
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildDarkHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      child: Row(children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white.withAlpha(220)),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withAlpha(15),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🚨 Emergency Booking',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Priority matching — professionals within 5 min',
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withAlpha(150)),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B00).withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: const Color(0xFFFF3B00).withAlpha(60)),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFF3B00).withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.info_outline_rounded,
              color: Color(0xFFFF6B35), size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'Emergency bookings have priority matching. Higher pricing may apply.',
            style: TextStyle(
                color: const Color(0xFFFF9060).withAlpha(220),
                fontSize: 13,
                height: 1.4),
          ),
        ),
      ]),
    );
  }
}
