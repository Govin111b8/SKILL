import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  final String reportedUserId;
  final String reportedUserName;

  const ReportScreen({super.key, required this.reportedUserId, required this.reportedUserName});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? _selectedType;
  final _descCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  final _complaintTypes = [
    ('fraud', 'Fraud / Scam', Icons.warning_amber),
    ('harassment', 'Harassment', Icons.report),
    ('spam', 'Spam / Fake Profile', Icons.block),
    ('poor_service', 'Poor Service', Icons.thumb_down),
    ('inappropriate', 'Inappropriate Content', Icons.flag),
    ('other', 'Other', Icons.more_horiz),
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a complaint type'), backgroundColor: Colors.orange));
      return;
    }
    if (_descCtrl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Description must be at least 10 characters'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService.post('/complaints', {
        'reported_user_id': widget.reportedUserId,
        'complaint_type': _selectedType!,
        'description': _descCtrl.text.trim(),
      }, auth: true);
      setState(() => _submitted = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Submitted')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                child: Icon(Icons.check_circle, size: 64, color: Colors.blue.shade600),
              ),
              const SizedBox(height: 24),
              Text('Report Received', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('We will review your complaint about ${widget.reportedUserName} and take appropriate action.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Report User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.report, color: Colors.red.shade400),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Filing a report against', style: TextStyle(fontSize: 13)),
                    Text(widget.reportedUserName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),

          Text('Complaint Type', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...(_complaintTypes.map((t) => Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: RadioListTile<String>(
              value: t.$1,
              groupValue: _selectedType,
              onChanged: (v) => setState(() => _selectedType = v),
              title: Text(t.$2, style: const TextStyle(fontWeight: FontWeight.w500)),
              secondary: Icon(t.$3, color: _selectedType == t.$1 ? Theme.of(context).colorScheme.primary : Colors.grey),
            ),
          ))),
          const SizedBox(height: 20),

          Text('Description', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 5,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: 'Please provide details about your complaint...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
              label: Text(_submitting ? 'Submitting...' : 'Submit Report'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ]),
      ),
    );
  }
}
