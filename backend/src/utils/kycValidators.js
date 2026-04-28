// Format validators for Indian KYC document numbers.
// All validators return { valid: bool, normalized?: string, reason?: string }.

const upper = (v) => String(v || '').trim().toUpperCase().replace(/\s+/g, '');
const digits = (v) => String(v || '').replace(/\D/g, '');

// Verhoeff algorithm — official Aadhaar checksum
const verhoeffD = [
  [0,1,2,3,4,5,6,7,8,9],[1,2,3,4,0,6,7,8,9,5],[2,3,4,0,1,7,8,9,5,6],
  [3,4,0,1,2,8,9,5,6,7],[4,0,1,2,3,9,5,6,7,8],[5,9,8,7,6,0,4,3,2,1],
  [6,5,9,8,7,1,0,4,3,2],[7,6,5,9,8,2,1,0,4,3],[8,7,6,5,9,3,2,1,0,4],[9,8,7,6,5,4,3,2,1,0]];
const verhoeffP = [
  [0,1,2,3,4,5,6,7,8,9],[1,5,7,6,2,8,3,0,9,4],[5,8,0,3,7,9,6,1,4,2],
  [8,9,1,6,0,4,3,5,2,7],[9,4,5,3,1,2,6,8,7,0],[4,2,8,6,5,7,3,9,0,1],
  [2,7,9,3,8,0,6,4,1,5],[7,0,4,6,9,1,3,2,5,8]];
function verhoeffValidate(s) {
  let c = 0;
  const arr = s.split('').reverse().map(Number);
  for (let i = 0; i < arr.length; i++) c = verhoeffD[c][verhoeffP[i % 8][arr[i]]];
  return c === 0;
}

const VALIDATORS = {
  aadhaar(v) {
    const d = digits(v);
    if (d.length !== 12) return { valid: false, reason: 'Aadhaar must be 12 digits' };
    if (d[0] === '0' || d[0] === '1') return { valid: false, reason: 'Aadhaar cannot start with 0 or 1' };
    if (!verhoeffValidate(d)) return { valid: false, reason: 'Invalid Aadhaar checksum' };
    return { valid: true, normalized: d };
  },
  pan(v) {
    const u = upper(v);
    if (!/^[A-Z]{5}[0-9]{4}[A-Z]$/.test(u)) return { valid: false, reason: 'PAN must be 5 letters + 4 digits + 1 letter (e.g. ABCDE1234F)' };
    const fourth = u[3]; // P=Individual, C=Company, H=HUF, F=Firm, A=AOP, T=Trust, B=BOI, L=Local, J=Artificial Juridical, G=Government
    if (!'PCHFATBLJG'.includes(fourth)) return { valid: false, reason: 'Invalid PAN holder type' };
    return { valid: true, normalized: u };
  },
  gstin(v) {
    const u = upper(v);
    if (!/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$/.test(u)) {
      return { valid: false, reason: 'GSTIN format invalid (15 chars: SS + PAN + entity + Z + check)' };
    }
    const stateCode = parseInt(u.slice(0, 2), 10);
    if (stateCode < 1 || stateCode > 38) return { valid: false, reason: 'Invalid GST state code' };
    return { valid: true, normalized: u };
  },
  cin(v) {
    const u = upper(v);
    // L/U + 5-digit industry + 2-letter state + 4-digit year + 3-letter type + 6-digit reg
    if (!/^[LU][0-9]{5}[A-Z]{2}[0-9]{4}[A-Z]{3}[0-9]{6}$/.test(u)) {
      return { valid: false, reason: 'CIN must be 21 chars (e.g. U12345MH2010PTC123456)' };
    }
    return { valid: true, normalized: u };
  },
  tan(v) {
    const u = upper(v);
    if (!/^[A-Z]{4}[0-9]{5}[A-Z]$/.test(u)) return { valid: false, reason: 'TAN must be 4 letters + 5 digits + 1 letter' };
    return { valid: true, normalized: u };
  },
  uan(v) {
    const d = digits(v);
    if (d.length !== 12) return { valid: false, reason: 'UAN must be 12 digits' };
    return { valid: true, normalized: d };
  },
  pf_number(v) {
    // EPF format: AA/BBB/CCCCCCC/DDD (region/office/establishment/member)
    const u = upper(v).replace(/[\s-]/g, '');
    if (!/^[A-Z]{2,5}[0-9]{6,15}$/.test(u) && !/^[A-Z]{2}\/[A-Z]{3}\/\d{7}\/\d{3}$/.test(upper(v))) {
      return { valid: false, reason: 'PF number format looks invalid' };
    }
    return { valid: true, normalized: upper(v).replace(/\s+/g, '') };
  },
  voter_id(v) {
    const u = upper(v);
    if (!/^[A-Z]{3}[0-9]{7}$/.test(u)) return { valid: false, reason: 'Voter ID (EPIC) must be 3 letters + 7 digits' };
    return { valid: true, normalized: u };
  },
  driving_license(v) {
    const u = upper(v).replace(/[\s-]/g, '');
    // SS-RR-YYYY-NNNNNNN — accept loose
    if (!/^[A-Z]{2}[0-9]{2,4}[0-9]{4,11}$/.test(u)) return { valid: false, reason: 'DL number format invalid' };
    return { valid: true, normalized: u };
  },
  passport(v) {
    const u = upper(v);
    if (!/^[A-PR-WY][0-9]{7}$/.test(u)) return { valid: false, reason: 'Passport must be 1 letter + 7 digits' };
    return { valid: true, normalized: u };
  },
  icai_membership(v) {
    const d = digits(v);
    if (d.length < 5 || d.length > 7) return { valid: false, reason: 'ICAI membership is 5-7 digits' };
    return { valid: true, normalized: d };
  },
  bar_council(v) {
    const u = upper(v).replace(/\s+/g, '');
    if (!/^[A-Z]{2,4}\/?[0-9]{2,6}\/?[0-9]{4}$/.test(u)) return { valid: false, reason: 'Bar Council ID format invalid' };
    return { valid: true, normalized: u };
  },
  mci_registration(v) {
    const d = digits(v);
    if (d.length < 5) return { valid: false, reason: 'MCI registration too short' };
    return { valid: true, normalized: d };
  },
  coa_registration(v) {
    const u = upper(v).replace(/\s+/g, '');
    if (!/^CA\/[0-9]{4}\/[0-9]{3,6}$/.test(u)) return { valid: false, reason: 'CoA format: CA/YYYY/NNNNN' };
    return { valid: true, normalized: u };
  },
  iei_membership(v) {
    const u = upper(v).replace(/\s+/g, '');
    if (u.length < 6) return { valid: false, reason: 'IEI membership too short' };
    return { valid: true, normalized: u };
  },
  fssai(v) {
    const d = digits(v);
    if (d.length !== 14) return { valid: false, reason: 'FSSAI license must be 14 digits' };
    return { valid: true, normalized: d };
  },
  shop_act(v)            { return generic(v, 4, 30, 'Shop Act number'); },
  msme_udyam(v) {
    const u = upper(v).replace(/[\s-]/g, '');
    if (!/^UDYAM-[A-Z]{2}-[0-9]{2}-[0-9]{7}$/.test(u)) return { valid: false, reason: 'Udyam: UDYAM-SS-NN-NNNNNNN' };
    return { valid: true, normalized: u };
  },
  trade_license(v)       { return generic(v, 4, 40, 'Trade license'); },
  electrical_license(v)  { return generic(v, 4, 40, 'Electrical license'); },
  plumbing_license(v)    { return generic(v, 4, 40, 'Plumbing license'); },
  iso_cert(v)            { return generic(v, 4, 40, 'ISO certificate'); },
  other(v)               { return generic(v, 3, 64, 'Document number'); },
};

function generic(v, min, max, label) {
  const t = String(v || '').trim();
  if (t.length < min || t.length > max) return { valid: false, reason: `${label} must be ${min}-${max} characters` };
  return { valid: true, normalized: t.toUpperCase() };
}

function validate(docType, docNumber) {
  const fn = VALIDATORS[docType];
  if (!fn) return { valid: false, reason: `Unsupported doc type: ${docType}` };
  return fn(docNumber);
}

// Mask for display: keep first 2 + last 4
function maskDocNumber(s) {
  if (!s) return '';
  if (s.length <= 6) return '*'.repeat(s.length);
  return s.slice(0, 2) + '*'.repeat(Math.max(s.length - 6, 4)) + s.slice(-4);
}

// Trust score derivation from verified doc set (max 100)
const TRUST_WEIGHTS = {
  aadhaar: 25, pan: 20, gstin: 15, cin: 15, tan: 10,
  passport: 15, voter_id: 10, driving_license: 10,
  uan: 10, pf_number: 10,
  icai_membership: 30, bar_council: 30, mci_registration: 30,
  coa_registration: 25, iei_membership: 20,
  fssai: 15, msme_udyam: 15, shop_act: 10, trade_license: 10,
  electrical_license: 25, plumbing_license: 25, iso_cert: 20, other: 5,
};

function computeTrustScore(verifiedTypes) {
  const sum = (verifiedTypes || []).reduce((acc, t) => acc + (TRUST_WEIGHTS[t] || 0), 0);
  return Math.min(sum, 100);
}

function computeKycLevel({ phoneVerified, emailVerified, hasGovId, hasSelfie, hasCredential }) {
  let lvl = 0;
  if (phoneVerified || emailVerified) lvl = 1;
  if (hasGovId) lvl = 2;
  if (hasGovId && hasSelfie && hasCredential) lvl = 3;
  return lvl;
}

// Doc types allowed per role
const ROLE_ALLOWED = {
  customer:     ['aadhaar','pan','voter_id','driving_license','passport','uan','pf_number','gstin'],
  professional: Object.keys(VALIDATORS),
};

function isAllowedForRole(role, docType) {
  return (ROLE_ALLOWED[role] || []).includes(docType);
}

module.exports = {
  validate, maskDocNumber, computeTrustScore, computeKycLevel,
  isAllowedForRole, ROLE_ALLOWED, TRUST_WEIGHTS,
};
