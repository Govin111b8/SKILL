import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../services/api_service.dart';

class WriteReviewScreen extends StatefulWidget {
  final String professionalId;
  final String contactId;
  final String professionalName;

  const WriteReviewScreen({
    super.key,
    required this.professionalId,
    required this.contactId,
    required this.professionalName,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  double _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a rating'), backgroundColor: Colors.orange));
      return;
    }
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write a comment'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService.post('/reviews', {
        'professional_id': widget.professionalId,
        'contact_id': widget.contactId,
        'rating': _rating.toInt(),
        'comment': _commentCtrl.text.trim(),
      }, auth: true);
      setState(() => _submitted = true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Submitted')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: Icon(Icons.check_circle, size: 64, color: Colors.green.shade600),
              ),
              const SizedBox(height: 24),
              Text('Thank You!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Your review for ${widget.professionalName} has been submitted.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Done'),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Write a Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Professional info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.primaryContainer,
                  child: Text(widget.professionalName[0].toUpperCase(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.primary)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Reviewing', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    Text(widget.professionalName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),

          // Rating
          Text('Your Rating', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Center(
            child: RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              itemCount: 5,
              itemSize: 44,
              glow: false,
              unratedColor: Colors.grey.shade300,
              itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Colors.amber),
              onRatingUpdate: (rating) => setState(() => _rating = rating),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _rating == 0 ? 'Tap to rate' : _ratingLabel(_rating.toInt()),
                style: TextStyle(fontSize: 14, color: _rating == 0 ? Colors.grey : cs.primary, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Comment
          Text('Your Review', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _commentCtrl,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Share your experience with ${widget.professionalName}...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),

          // Submit
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
              label: Text(_submitting ? 'Submitting...' : 'Submit Review'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ]),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent';
      default: return '';
    }
  }
}
