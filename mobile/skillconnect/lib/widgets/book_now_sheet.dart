import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/booking_service.dart';
import '../screens/bookings/booking_detail_screen.dart';

/// Bottom sheet for booking a professional. Steps:
/// 1. Title (service needed)
/// 2. Date & time preference
/// 3. Address + description
/// 4. Submit → navigate to booking detail
Future<void> showBookNowSheet(
  BuildContext context, {
  required String professionalId,
  required String professionalName,
  List<Map<String, dynamic>> categories = const [],
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BookNowSheet(
      professionalId: professionalId,
      professionalName: professionalName,
      categories: categories,
    ),
  );
}

class _BookNowSheet extends StatefulWidget {
  final String professionalId;
  final String professionalName;
  final List<Map<String, dynamic>> categories;
  const _BookNowSheet({required this.professionalId, required this.professionalName, required this.categories});

  @override
  State<_BookNowSheet> createState() => _BookNowSheetState();
}

class _BookNowSheetState extends State<_BookNowSheet> {
  final _form = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  DateTime? _scheduledFor;
  TimeOfDay? _scheduledTime;
  int? _selectedCategoryId;
  bool _submitting = false;
  String? _error;

  // Quick service title suggestions shown as chips
  static const _suggestions = [
    'Plumbing repair', 'Electrical work', 'Painting', 'Deep cleaning',
    'AC service', 'Carpenter work', 'Home shifting', 'Pest control',
    'Wiring installation', 'Leakage fix', 'Terrace waterproofing',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _scheduledFor = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  DateTime? _combinedDateTime() {
    if (_scheduledFor == null) return null;
    final t = _scheduledTime ?? const TimeOfDay(hour: 10, minute: 0);
    return DateTime(_scheduledFor!.year, _scheduledFor!.month, _scheduledFor!.day, t.hour, t.minute);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _submitting = true; _error = null; });
    try {
      final dt = _combinedDateTime();
      final booking = await BookingService.create(
        professionalId: widget.professionalId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        categoryId: _selectedCategoryId,
        serviceAddress: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        preferredDate: dt,
      );
      if (mounted) {
        Navigator.pop(context); // close sheet
        Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(booking: booking)));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Booking request sent! The professional will respond shortly.'),
          backgroundColor: Color(0xFF10B981),
        ));
      }
    } catch (e) {
      setState(() { _submitting = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Book Professional', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                Text('with ${widget.professionalName}', style: TextStyle(color: cs.primary, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ]),
          ),
          const Divider(height: 24),
          // Form
          Expanded(
            child: Form(
              key: _form,
              child: ListView(
                controller: scrollCtrl,
                padding: EdgeInsets.fromLTRB(20, 0, 20, mq.viewInsets.bottom + 20),
                children: [

                  // Service type (optional)
                  if (widget.categories.isNotEmpty) ...[
                    _label('Service Type'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        hintText: 'Select service type',
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        filled: true, fillColor: const Color(0xFFF1F5F9),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Not specified')),
                        ...widget.categories.map((c) => DropdownMenuItem(value: c['id'] as int?, child: Text(c['name']?.toString() ?? ''))),
                      ],
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Title
                  _label('What do you need? *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please describe what you need.' : null,
                    decoration: InputDecoration(
                      hintText: 'e.g., Fix leaking tap in bathroom',
                      prefixIcon: const Icon(Icons.work_outline),
                    ),
                    maxLength: 120,
                  ),
                  // Quick suggestions
                  Wrap(
                    spacing: 6, runSpacing: 4,
                    children: _suggestions.map((s) => ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      onPressed: () => setState(() => _titleCtrl.text = s),
                      backgroundColor: cs.primaryContainer.withAlpha(40),
                      side: BorderSide(color: cs.primary.withAlpha(30)),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Preferred date & time
                  _label('Preferred Date & Time'),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(children: [
                            Icon(Icons.calendar_today_outlined, size: 18, color: cs.primary),
                            const SizedBox(width: 8),
                            Text(
                              _scheduledFor != null ? DateFormat('d MMM yyyy').format(_scheduledFor!) : 'Select date',
                              style: TextStyle(fontSize: 14, color: _scheduledFor != null ? Colors.black87 : Colors.grey.shade500),
                            ),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                          child: Row(children: [
                            Icon(Icons.access_time, size: 18, color: cs.primary),
                            const SizedBox(width: 8),
                            Text(
                              _scheduledTime != null ? _scheduledTime!.format(context) : 'Select time',
                              style: TextStyle(fontSize: 14, color: _scheduledTime != null ? Colors.black87 : Colors.grey.shade500),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Address
                  _label('Service Address'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Enter your full address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Extra description
                  _label('Additional Details'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Describe the problem in detail, materials needed, etc.',
                      prefixIcon: Icon(Icons.notes_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 8),

                  // Error
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                      ]),
                    ),
                  const SizedBox(height: 16),

                  // Submit
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded),
                      label: Text(_submitting ? 'Sending...' : 'Send Booking Request'),
                      style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.professionalName} will review and respond with a quote. No payment until you accept.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13));
  }
}
