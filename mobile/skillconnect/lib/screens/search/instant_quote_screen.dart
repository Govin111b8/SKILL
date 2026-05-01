import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/upload_service.dart';

/// Camera → Instant Quote screen.
/// User takes a photo of a problem, tags the issue category,
/// and sends it to nearby providers for quick quotes.
class InstantQuoteScreen extends StatefulWidget {
  const InstantQuoteScreen({super.key});

  @override
  State<InstantQuoteScreen> createState() => _InstantQuoteScreenState();
}

class _InstantQuoteScreenState extends State<InstantQuoteScreen> {
  File? _imageFile;
  String? _selectedCategory;
  final _descriptionCtl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  final _categories = [
    'AC / Cooling',
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'Cleaning',
    'Appliance Repair',
    'Other',
  ];

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 70, // Compress for low data
    );
    if (result != null) {
      setState(() => _imageFile = File(result.path));
    }
  }

  Future<void> _submitQuoteRequest() async {
    if (_imageFile == null || _selectedCategory == null) return;

    setState(() => _submitting = true);
    try {
      // Upload image
      final imageUrl = await UploadService.uploadFile(_imageFile!.path, 'quote_images');

      // Create quote request
      await ApiService.post('/quotes/request', {
        'image_url': imageUrl,
        'category': _selectedCategory,
        'description': _descriptionCtl.text.trim(),
      }, auth: true);

      setState(() => _submitted = true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit. Will retry when online.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _descriptionCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccess(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Instant Quote'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step 1: Photo
            Text('📸 Take a photo of the problem',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _imageFile = null),
                icon: const Icon(Icons.refresh),
                label: const Text('Retake'),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Step 2: Category
            Text('🏷️ What type of issue?',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) => ChoiceChip(
                label: Text(cat),
                selected: _selectedCategory == cat,
                onSelected: (s) => setState(() => _selectedCategory = s ? cat : null),
              )).toList(),
            ),
            const SizedBox(height: 24),

            // Step 3: Optional description
            Text('📝 Describe briefly (optional)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionCtl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. "AC not cooling, making noise"',
              ),
            ),
            const SizedBox(height: 32),

            // Submit
            FilledButton.icon(
              onPressed: (_imageFile != null && _selectedCategory != null && !_submitting)
                  ? _submitQuoteRequest
                  : null,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: Text(_submitting ? 'Sending...' : 'Get Quotes from Nearby Pros'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 80, color: Colors.green.shade600),
              const SizedBox(height: 24),
              Text('Quote Request Sent! 🎉',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                'Nearby professionals will send you quotes shortly. You\'ll get a notification when quotes arrive.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
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
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
