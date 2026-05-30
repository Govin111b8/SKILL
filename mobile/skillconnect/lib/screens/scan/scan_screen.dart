import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/premium_ui.dart';

/// QR / barcode scanner screen.
/// Uses the device camera to scan:
///   - Professional QR codes → open their profile
///   - Booking QR codes     → check-in / confirm completion
///
/// Note: actual camera scanning requires the `mobile_scanner` package.
/// This screen provides the full UI shell; swap the placeholder camera
/// preview with a MobileScanner widget when the package is added.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;
  bool _torchOn = false;
  String? _lastResult;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    super.dispose();
  }

  void _onScanResult(String result) {
    HapticFeedback.mediumImpact();
    setState(() => _lastResult = result);

    // Route based on QR payload prefix
    if (result.startsWith('pro:')) {
      final professionalId = result.replaceFirst('pro:', '');
      Navigator.pushNamed(context, '/professional',
          arguments: professionalId);
    } else if (result.startsWith('booking:')) {
      final bookingId = result.replaceFirst('booking:', '');
      Navigator.pushNamed(context, '/booking', arguments: bookingId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned: $result'),
          backgroundColor: AppColors.superBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Dark premium background ──────────────────────────────────
          PremiumBackground(
            dark: true,
            colors: const [
              Color(0xFF020B1A),
              Color(0xFF061226),
              Color(0xFF040F22),
            ],
            child: const SizedBox.expand(),
          ),

          // ── Camera preview placeholder ──────────────────────────────
          // Replace this Container with MobileScanner(onDetect: ...) when
          // mobile_scanner package is available in pubspec.yaml.
          Container(
            color: Colors.transparent,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      size: 60, color: Colors.white.withAlpha(30)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Camera preview',
                    style: TextStyle(
                        color: Colors.white.withAlpha(50), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          // ── Top bar ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
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
                    const Expanded(
                      child: Text(
                        'Scan QR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _torchOn = !_torchOn);
                      },
                      child: AnimatedContainer(
                        duration: AppDurations.fast,
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: _torchOn
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFFC107),
                                    Color(0xFFFF9800),
                                  ],
                                )
                              : null,
                          color: _torchOn
                              ? null
                              : Colors.white.withAlpha(15),
                          shape: BoxShape.circle,
                          boxShadow: _torchOn
                              ? [
                                  BoxShadow(
                                    color:
                                        const Color(0xFFFFC107).withAlpha(100),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          _torchOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ]),
                ),

                // ── Last result chip ──────────────────────────────────
                if (_lastResult != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: AppColors.successGradient),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: AppShadows.md(AppColors.success),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Scanned: $_lastResult',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
          ),

          // ── Scan frame overlay ──────────────────────────────────────
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(children: [
                // Subtle dark overlay outside corners
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    border: Border.all(
                      color: AppColors.superBlue.withAlpha(30),
                      width: 1,
                    ),
                  ),
                ),
                // Corner brackets
                ..._buildCorners(),
                // Animated scan line
                AnimatedBuilder(
                  animation: _scanLineAnim,
                  builder: (_, __) => Positioned(
                    top: _scanLineAnim.value * 240,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.superBlue.withAlpha(80),
                            AppColors.superBlue,
                            AppColors.primaryLight,
                            AppColors.superBlue.withAlpha(80),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.superBlue.withAlpha(120),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),

          // ── Bottom instructions ─────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl, AppSpacing.xxxl, AppSpacing.xxl, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(160),
                    Colors.black.withAlpha(220),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Point your camera at a QR code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withAlpha(230),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      "Scan a professional's profile QR or a booking confirmation code",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withAlpha(150),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Demo button for testing
                    GestureDetector(
                      onTap: () => _onScanResult('pro:demo-professional-id'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: AppColors.superAppGradient),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          boxShadow: AppShadows.md(AppColors.superBlue),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_scanner_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Demo Scan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ScanTypeChip(
                            icon: Icons.person_rounded,
                            label: 'Profile QR',
                            color: AppColors.primary),
                        const SizedBox(width: AppSpacing.md),
                        _ScanTypeChip(
                            icon: Icons.confirmation_number_rounded,
                            label: 'Booking QR',
                            color: AppColors.success),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const double len = 32;
    const double thick = 3.5;
    const color = AppColors.superBlue;
    return [
      // Top-left
      Positioned(
          top: 0,
          left: 0,
          child: _Corner(len, thick, color, top: true, left: true)),
      // Top-right
      Positioned(
          top: 0,
          right: 0,
          child: _Corner(len, thick, color, top: true, left: false)),
      // Bottom-left
      Positioned(
          bottom: 0,
          left: 0,
          child: _Corner(len, thick, color, top: false, left: true)),
      // Bottom-right
      Positioned(
          bottom: 0,
          right: 0,
          child: _Corner(len, thick, color, top: false, left: false)),
    ];
  }
}

class _ScanTypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ScanTypeChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _Corner extends StatelessWidget {
  final double size;
  final double thickness;
  final Color color;
  final bool top;
  final bool left;

  const _Corner(this.size, this.thickness, this.color,
      {required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CornerPainter(thickness, color, top: top, left: left),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double thickness;
  final Color color;
  final bool top;
  final bool left;

  _CornerPainter(this.thickness, this.color,
      {required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? size.width : -size.width;
    final dy = top ? size.height : -size.height;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
