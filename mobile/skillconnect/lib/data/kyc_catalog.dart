// Master KYC document type catalog used by the Flutter UI.
// Mirrors backend kyc_doc_type enum + validators in /backend/src/utils/kycValidators.js

class KycDocType {
  final String code;
  final String label;
  final String emoji;
  final String hint;
  final String? exampleFormat;
  final List<String> roles; // 'customer' | 'professional'
  final String category;    // grouping in UI: identity / business / professional credential
  final RegExp? regex;
  final int? expectedLength;

  const KycDocType({
    required this.code,
    required this.label,
    required this.emoji,
    required this.hint,
    required this.roles,
    required this.category,
    this.exampleFormat,
    this.regex,
    this.expectedLength,
  });

  String? clientValidate(String input) {
    final v = input.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (v.isEmpty) return 'Required';
    if (expectedLength != null && v.replaceAll(RegExp(r'\D'), '').length != expectedLength && code != 'pf_number' && code != 'driving_license') {
      // length check only for digit-only docs
      final digitsOnly = v.replaceAll(RegExp(r'\D'), '');
      if (RegExp(r'^[0-9]+$').hasMatch(v) && digitsOnly.length != expectedLength) {
        return 'Must be $expectedLength digits';
      }
    }
    if (regex != null && !regex!.hasMatch(v)) {
      return 'Invalid format. Example: $exampleFormat';
    }
    return null;
  }
}

const kKycDocs = <KycDocType>[
  // Identity (individual)
  KycDocType(code: 'aadhaar',         label: 'Aadhaar',          emoji: '🆔', hint: '12-digit Aadhaar number',
    roles: ['customer','professional'], category: 'Identity', exampleFormat: '1234 5678 9012', expectedLength: 12),
  KycDocType(code: 'pan',             label: 'PAN Card',         emoji: '🪪', hint: 'Permanent Account Number',
    roles: ['customer','professional'], category: 'Identity', exampleFormat: 'ABCPE1234F'),
  KycDocType(code: 'voter_id',        label: 'Voter ID',         emoji: '🗳️', hint: 'EPIC number',
    roles: ['customer','professional'], category: 'Identity', exampleFormat: 'ABC1234567'),
  KycDocType(code: 'driving_license', label: 'Driving License',  emoji: '🚗', hint: 'State + RTO + year + serial',
    roles: ['customer','professional'], category: 'Identity', exampleFormat: 'TN0120240012345'),
  KycDocType(code: 'passport',        label: 'Passport',         emoji: '🛂', hint: 'Indian passport number',
    roles: ['customer','professional'], category: 'Identity', exampleFormat: 'A1234567'),

  // Employment / financial (individual)
  KycDocType(code: 'uan',             label: 'UAN (PF)',         emoji: '👔', hint: 'Universal Account Number — 12 digits',
    roles: ['customer','professional'], category: 'Employment', exampleFormat: '101234567890', expectedLength: 12),
  KycDocType(code: 'pf_number',       label: 'PF Member ID',     emoji: '💼', hint: 'EPF establishment + member ID',
    roles: ['customer','professional'], category: 'Employment', exampleFormat: 'TN/MAS/0012345/000'),

  // Business
  KycDocType(code: 'gstin',           label: 'GSTIN',            emoji: '🏢', hint: '15-character GST number',
    roles: ['customer','professional'], category: 'Business', exampleFormat: '27AABCU9603R1ZX'),
  KycDocType(code: 'cin',             label: 'CIN',              emoji: '🏛️', hint: 'Company registration ID',
    roles: ['professional'], category: 'Business', exampleFormat: 'U12345MH2010PTC123456'),
  KycDocType(code: 'tan',             label: 'TAN',              emoji: '📑', hint: 'Tax Deduction Account Number',
    roles: ['professional'], category: 'Business', exampleFormat: 'ABCD12345E'),
  KycDocType(code: 'msme_udyam',      label: 'Udyam (MSME)',     emoji: '🏭', hint: 'MSME / Udyam registration',
    roles: ['professional'], category: 'Business', exampleFormat: 'UDYAM-TN-12-1234567'),
  KycDocType(code: 'shop_act',        label: 'Shop & Establishment', emoji: '🏪', hint: 'Municipal license',
    roles: ['professional'], category: 'Business'),
  KycDocType(code: 'trade_license',   label: 'Trade License',    emoji: '📜', hint: 'Local trade license',
    roles: ['professional'], category: 'Business'),
  KycDocType(code: 'fssai',           label: 'FSSAI License',    emoji: '🍽️', hint: '14-digit food license',
    roles: ['professional'], category: 'Business', exampleFormat: '12345678901234', expectedLength: 14),
  KycDocType(code: 'iso_cert',        label: 'ISO Certificate',  emoji: '✅', hint: 'Quality certification',
    roles: ['professional'], category: 'Business'),

  // Professional credentials
  KycDocType(code: 'icai_membership', label: 'CA (ICAI)',        emoji: '📊', hint: 'Chartered Accountant member ID',
    roles: ['professional'], category: 'Credential', exampleFormat: '123456'),
  KycDocType(code: 'bar_council',     label: 'Bar Council',      emoji: '⚖️', hint: 'Lawyer / Advocate registration',
    roles: ['professional'], category: 'Credential', exampleFormat: 'TN/1234/2020'),
  KycDocType(code: 'mci_registration',label: 'Doctor (MCI/NMC)', emoji: '🩺', hint: 'Medical council registration',
    roles: ['professional'], category: 'Credential', exampleFormat: '123456'),
  KycDocType(code: 'coa_registration',label: 'Architect (CoA)',  emoji: '📐', hint: 'Council of Architecture',
    roles: ['professional'], category: 'Credential', exampleFormat: 'CA/2020/12345'),
  KycDocType(code: 'iei_membership',  label: 'Engineer (IEI)',   emoji: '⚙️', hint: 'Institution of Engineers India',
    roles: ['professional'], category: 'Credential'),
  KycDocType(code: 'electrical_license', label: 'Electrical License', emoji: '⚡', hint: 'State electrical contractor',
    roles: ['professional'], category: 'Credential'),
  KycDocType(code: 'plumbing_license',label: 'Plumbing License', emoji: '🔧', hint: 'State plumbing license',
    roles: ['professional'], category: 'Credential'),
  KycDocType(code: 'other',           label: 'Other Document',   emoji: '📄', hint: 'Any other supporting document',
    roles: ['customer','professional'], category: 'Other'),
];

KycDocType? findKycDoc(String code) {
  try { return kKycDocs.firstWhere((d) => d.code == code); } catch (_) { return null; }
}

List<KycDocType> kycDocsForRole(String role) {
  return kKycDocs.where((d) => d.roles.contains(role)).toList();
}
