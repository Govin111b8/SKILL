import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';

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

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
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
      Navigator.pushNamed(context, '/professional', arguments: professionalId);
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
            tooltip: 'Toggle torch',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Camera preview placeholder ──────────────────────────────
          // Replace this Container with MobileScanner(onDetect: ...) when
          // mobile_scanner package is available in pubspec.yaml.
          Container(
            color: const Color(0xFF111111),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 60, color: Colors.white.withAlpha(80)),
                  const SizedBox(height: 12),
                  Text(
                    'Camera preview',
                    style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // ── Scan frame overlay ──────────────────────────────────────
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                children: [
                  // Corner brackets
                  ..._buildCorners(),
                  // Animated scan line
                  AnimatedBuilder(
                    animation: _scanLineAnim,
                    builder: (_, __) => Positioned(
                      top: _scanLineAnim.value * 220,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.superBlue.withAlpha(200),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom instructions ────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(200)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Point your camera at a QR code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withAlpha(220),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan a professional\'s profile QR or a booking confirmation code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withAlpha(140),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Demo button for testing
                  OutlinedButton.icon(
                    onPressed: () => _onScanResult('pro:demo-professional-id'),
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    label: const Text('Demo Scan', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withAlpha(120)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Last result chip ────────────────────────────────────────
          if (_lastResult != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scanned: $_lastResult',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const double len = 28;
    const double thick = 3;
    const color = AppColors.superBlue;
    return [
      // Top-left
      Positioned(top: 0, left: 0, child: _Corner(len, thick, color, top: true, left: true)),
      // Top-right
      Positioned(top: 0, right: 0, child: _Corner(len, thick, color, top: true, left: false)),
      // Bottom-left
      Positioned(bottom: 0, left: 0, child: _Corner(len, thick, color, top: false, left: true)),
      // Bottom-right
      Positioned(bottom: 0, right: 0, child: _Corner(len, thick, color, top: false, left: false)),
    ];
  }
}

class _Corner extends StatelessWidget {
  final double size;
  final double thickness;
  final Color color;
  final bool top;
  final bool left;

  const _Corner(this.size, this.thickness, this.color, {required this.top, required this.left});

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

  _CornerPainter(this.thickness, this.color, {required this.top, required this.left});

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
