import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

/// Availability toggle widget for professionals.
/// Shows current status and allows quick toggle between 'available', 'busy', 'offline'.
class AvailabilityToggle extends StatefulWidget {
  const AvailabilityToggle({super.key});

  @override
  State<AvailabilityToggle> createState() => _AvailabilityToggleState();
}

class _AvailabilityToggleState extends State<AvailabilityToggle> {
  String _status = 'offline';
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final result = await ApiService.get('/professionals/me/availability', auth: true);
      if (mounted) {
        setState(() {
          _status = result['availability_status']?.toString() ?? 'offline';
        });
      }
    } catch (_) {}
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_updating || newStatus == _status) return;
    setState(() => _updating = true);
    try {
      await ApiService.post('/professionals/me/availability', {'status': newStatus}, auth: true);
      HapticFeedback.mediumImpact();
      setState(() => _status = newStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;

    switch (_status) {
      case 'available':
        statusColor = Colors.green;
        statusIcon = Icons.circle;
        statusLabel = 'Available';
        break;
      case 'busy':
        statusColor = Colors.orange;
        statusIcon = Icons.do_not_disturb;
        statusLabel = 'Busy';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.circle_outlined;
        statusLabel = 'Offline';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(statusIcon, color: statusColor, size: 14),
              const SizedBox(width: 8),
              Text('Status: $statusLabel',
                  style: TextStyle(fontWeight: FontWeight.w600, color: statusColor)),
              const Spacer(),
              if (_updating)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _StatusButton(
                  label: 'Available',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  isSelected: _status == 'available',
                  onTap: () => _updateStatus('available'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusButton(
                  label: 'Busy',
                  icon: Icons.do_not_disturb,
                  color: Colors.orange,
                  isSelected: _status == 'busy',
                  onTap: () => _updateStatus('busy'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusButton(
                  label: 'Offline',
                  icon: Icons.power_settings_new,
                  color: Colors.grey,
                  isSelected: _status == 'offline',
                  onTap: () => _updateStatus('offline'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withAlpha(30) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Theme.of(context).colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
            )),
          ]),
        ),
      ),
    );
  }
}
