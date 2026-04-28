import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/booking_service.dart';

/// Checks for completed bookings without a review and shows a review prompt
/// as a non-blocking banner/card. Call [ReviewPrompt.check] from home/bookings screens.
class ReviewPromptBanner extends StatefulWidget {
  const ReviewPromptBanner({super.key});

  @override
  State<ReviewPromptBanner> createState() => _ReviewPromptBannerState();
}

class _ReviewPromptBannerState extends State<ReviewPromptBanner> {
  List<Map<String, dynamic>> _pending = [];
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.get('/reviews/pending', auth: true);
      final rows = (res['data'] as List).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _pending = rows);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _pending.isEmpty) return const SizedBox.shrink();
    final first = _pending.first;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF7ED), Color(0xFFFFFBEB)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withAlpha(80)),
        boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withAlpha(30), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        const Text('⭐', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Rate your experience with ${first['professional_name'] ?? 'your professional'}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            '${first['title']} — tap to leave a review',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          if (_pending.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('+${_pending.length - 1} more pending', style: const TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
            ),
        ])),
        const SizedBox(width: 8),
        Column(children: [
          FilledButton(
            onPressed: () => _openReviewSheet(context, first),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Rate Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => setState(() => _dismissed = true),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text('Later', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ),
        ]),
      ]),
    );
  }

  Future<void> _openReviewSheet(BuildContext context, Map<String, dynamic> item) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(
        bookingId: item['booking_id']?.toString() ?? '',
        professionalId: item['professional_id']?.toString() ?? '',
        professionalName: item['professional_name']?.toString() ?? 'Professional',
        jobTitle: item['title']?.toString() ?? '',
        onSubmitted: () {
          setState(() {
            _pending.removeWhere((p) => p['booking_id'] == item['booking_id']);
          });
        },
      ),
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  final String bookingId;
  final String professionalId;
  final String professionalName;
  final String jobTitle;
  final VoidCallback onSubmitted;
  const _ReviewSheet({required this.bookingId, required this.professionalId, required this.professionalName, required this.jobTitle, required this.onSubmitted});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Please select a rating.');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      await ApiService.post('/reviews', {
        'professional_id': widget.professionalId,
        'booking_id': widget.bookingId,
        'rating': _rating,
        'comment': _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      }, auth: true);
      widget.onSubmitted();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Thanks for your review!'),
          backgroundColor: Color(0xFF10B981),
        ));
      }
    } catch (e) {
      setState(() { _submitting = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 20),
        const Text('Rate your experience', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('with ${widget.professionalName}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(widget.jobTitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 24),

        // Star rating
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() => _rating = i + 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 44,
                color: const Color(0xFFF59E0B),
              ),
            ),
          )),
        ),
        const SizedBox(height: 8),
        Text(
          _rating == 0 ? 'Tap to rate' : ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent!'][_rating],
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: _rating == 0 ? Colors.grey : const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(height: 20),

        // Comment
        TextField(
          controller: _commentCtrl,
          decoration: InputDecoration(
            hintText: 'Share your experience (optional)...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            filled: true, fillColor: const Color(0xFFF1F5F9),
          ),
          maxLines: 3,
          maxLength: 400,
        ),
        const SizedBox(height: 12),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),

        SizedBox(
          width: double.infinity, height: 52,
          child: FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
            label: Text(_submitting ? 'Submitting...' : 'Submit Review'),
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ),
      ]),
    );
  }
}
