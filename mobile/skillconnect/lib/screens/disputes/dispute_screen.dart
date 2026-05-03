import 'package:flutter/material.dart';
import '../../services/api_service.dart';

/// Simplified 3-step dispute flow for mobile.
/// Step 1: Select issue type
/// Step 2: Describe problem
/// Step 3: Submit (with optional photo)
class DisputeScreen extends StatefulWidget {
  final String bookingId;
  final String bookingTitle;

  const DisputeScreen({super.key, required this.bookingId, required this.bookingTitle});

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  int _step = 0;
  String? _issueType;
  final _descCtl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  final _issueTypes = [
    ('quality', 'Poor Quality Work', Icons.star_border),
    ('incomplete', 'Work Not Completed', Icons.pending_actions),
    ('overcharged', 'Overcharged', Icons.money_off),
    ('no_show', 'Professional Didn\'t Show', Icons.person_off),
    ('damage', 'Property Damaged', Icons.broken_image),
    ('other', 'Other Issue', Icons.help_outline),
  ];

  Future<void> _submit() async {
    if (_issueType == null || _descCtl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ApiService.post('/disputes', {
        'booking_id': widget.bookingId,
        'issue_type': _issueType,
        'description': _descCtl.text.trim(),
      }, auth: true);
      setState(() => _submitted = true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit. Please try again.')),
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
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 72, color: Colors.green.shade600),
                const SizedBox(height: 16),
                Text('Dispute Submitted', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text(
                  'Our team will review your dispute within 24 hours. You\'ll receive a notification with the resolution.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Raise a Dispute')),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(value: (_step + 1) / 3),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _step == 0 ? _buildStep1() : _step == 1 ? _buildStep2() : _buildStep3(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Step 1: What\'s the issue?', style: Theme.of(context).textTheme.titleMedium),
        Text('For: ${widget.bookingTitle}', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: _issueTypes.map((item) {
              final (id, label, icon) = item;
              final selected = _issueType == id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(icon, color: selected ? Theme.of(context).colorScheme.primary : null),
                  title: Text(label),
                  selected: selected,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor),
                  ),
                  onTap: () => setState(() { _issueType = id; _step = 1; }),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Step 2: Describe the problem', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        TextField(
          controller: _descCtl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Tell us what happened...',
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 0),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _descCtl.text.trim().isNotEmpty ? () => setState(() => _step = 2) : null,
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Step 3: Confirm & Submit', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Issue: ${_issueTypes.firstWhere((e) => e.$1 == _issueType).$2}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Description: ${_descCtl.text}'),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 1),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Dispute'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
