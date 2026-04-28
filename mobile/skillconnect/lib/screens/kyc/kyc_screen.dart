import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/kyc_catalog.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/trust_badge.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _myDocs = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.get('/kyc/me', auth: true);
      _myDocs = r['data'] ?? [];
      _summary = (r['user'] as Map<String, dynamic>?) ?? {};
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _add(KycDocType doc) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmitSheet(doc: doc),
    );
    if (result == null) return;
    try {
      final r = await ApiService.post('/kyc/submit', result, auth: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: r['success'] == false ? Colors.red.shade600 : Colors.green.shade600,
          content: Text(r['message'] ?? 'Submitted'),
        ));
      }
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')));
    }
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove document?'),
        content: const Text('You will need to re-verify if you remove this document.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.delete('/kyc/$id', auth: true);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Map<String, dynamic>? _docFor(String code) {
    try { return _myDocs.firstWhere((d) => d['doc_type'] == code) as Map<String, dynamic>; } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final role = (auth.user?['role'] as String?) ?? 'customer';
    final available = kycDocsForRole(role);
    final byCategory = <String, List<KycDocType>>{};
    for (final d in available) { (byCategory[d.category] ??= []).add(d); }

    final lvl = (_summary['kyc_level'] ?? 0) as int;
    final score = ((_summary['trust_score'] ?? 0) as num).toInt();

    return Scaffold(
      appBar: AppBar(title: const Text('KYC & Verification'), elevation: 0),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Trust score header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF06B6D4)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withAlpha(80), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 10),
                        const Text('Trust Score', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        TrustBadge(kycLevel: lvl, trustScore: score),
                      ]),
                      const SizedBox(height: 16),
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('$score', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, height: 1)),
                        Padding(padding: const EdgeInsets.only(bottom: 8, left: 4), child: Text('/100', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 18, fontWeight: FontWeight.w600))),
                        const Spacer(),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('Level $lvl / 3', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                          Text(_levelLabel(lvl), style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 11)),
                        ]),
                      ]),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          minHeight: 8,
                          backgroundColor: Colors.white.withAlpha(60),
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_nextStepHint(lvl, score), style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 12)),
                    ]),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.error, color: Colors.red), const SizedBox(width: 8), Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade800, fontSize: 12)))])),
                  ],
                  const SizedBox(height: 24),

                  // Per category
                  for (final cat in byCategory.keys) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 8),
                      child: Row(children: [
                        Icon(_catIcon(cat), size: 18, color: const Color(0xFF6366F1)),
                        const SizedBox(width: 8),
                        Text(cat, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
                      ]),
                    ),
                    Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                      child: Column(children: [
                        for (var i = 0; i < byCategory[cat]!.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 60),
                          _docTile(byCategory[cat]![i]),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.amber.shade200)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.shield_outlined, color: Color(0xFFB45309)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Privacy & Security', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF92400E))),
                        const SizedBox(height: 4),
                        Text('Document numbers are masked everywhere. Originals are encrypted at rest. We never share your KYC data with third parties — only verification status is shown publicly.', style: TextStyle(fontSize: 12, color: Colors.brown.shade700)),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _docTile(KycDocType doc) {
    final existing = _docFor(doc.code);
    final status = existing?['status'] as String?;
    final masked = existing?['doc_number'] as String?;
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(doc.emoji, style: const TextStyle(fontSize: 20))),
      ),
      title: Text(doc.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(masked ?? doc.hint, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: status == null
          ? FilledButton.tonal(onPressed: () => _add(doc), style: FilledButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6)), child: const Text('Add', style: TextStyle(fontSize: 12)))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              _statusChip(status),
              IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _delete(existing!['id'] as String)),
            ]),
      onTap: status == null ? () => _add(doc) : null,
    );
  }

  Widget _statusChip(String s) {
    final (c, lbl, ic) = switch (s) {
      'verified' => (const Color(0xFF10B981), 'Verified', Icons.check_circle_rounded),
      'pending'  => (const Color(0xFFF59E0B), 'Pending',  Icons.access_time_rounded),
      'rejected' => (const Color(0xFFEF4444), 'Rejected', Icons.error_rounded),
      _          => (const Color(0xFF94A3B8), s,          Icons.help_outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withAlpha(30), borderRadius: BorderRadius.circular(100)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ic, size: 12, color: c),
        const SizedBox(width: 3),
        Text(lbl, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  String _levelLabel(int l) => switch (l) { 0 => 'Get verified to unlock more', 1 => 'Phone verified', 2 => 'Government ID verified', _ => 'Pro-grade trust' };
  String _nextStepHint(int l, int s) {
    if (l >= 3) return 'You have full Pro-grade verification.';
    if (l >= 2) return 'Add a credential or business doc to reach Level 3.';
    if (l >= 1) return 'Add a government ID (Aadhaar, PAN) to reach Level 2.';
    return 'Verify your phone number to reach Level 1.';
  }

  IconData _catIcon(String cat) => switch (cat) {
    'Identity' => Icons.fingerprint_rounded,
    'Employment' => Icons.work_outline_rounded,
    'Business' => Icons.store_mall_directory_rounded,
    'Credential' => Icons.workspace_premium_rounded,
    _ => Icons.folder_outlined,
  };
}

class _SubmitSheet extends StatefulWidget {
  final KycDocType doc;
  const _SubmitSheet({required this.doc});

  @override
  State<_SubmitSheet> createState() => _SubmitSheetState();
}

class _SubmitSheetState extends State<_SubmitSheet> {
  final _form = GlobalKey<FormState>();
  final _num = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() { _num.dispose(); _name.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          top: false,
          child: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(widget.doc.emoji, style: const TextStyle(fontSize: 24)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.doc.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(widget.doc.hint, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ])),
              ]),
              const SizedBox(height: 20),
              TextFormField(
                controller: _num,
                decoration: InputDecoration(labelText: 'Document number', hintText: widget.doc.exampleFormat ?? 'Enter number', prefixIcon: const Icon(Icons.numbers_rounded)),
                textCapitalization: TextCapitalization.characters,
                autofocus: true,
                validator: (v) => widget.doc.clientValidate(v ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name as on document (optional)', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Format will be re-validated server-side. Document numbers are masked on display and stored hashed.', style: TextStyle(fontSize: 11, color: Colors.blue.shade900))),
              ])),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (!_form.currentState!.validate()) return;
                    Navigator.pop(context, {
                      'doc_type': widget.doc.code,
                      'doc_number': _num.text.trim(),
                      if (_name.text.trim().isNotEmpty) 'holder_name': _name.text.trim(),
                    });
                  },
                  icon: const Icon(Icons.verified_rounded),
                  label: const Text('Submit for verification'),
                ),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
  }
}
