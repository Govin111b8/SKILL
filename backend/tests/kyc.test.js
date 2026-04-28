const v = require('../src/utils/kycValidators');

describe('KYC validators', () => {
  test('PAN: valid format with Person holder', () => {
    expect(v.validate('pan', 'ABCPE1234F').valid).toBe(true);
  });
  test('PAN: invalid format', () => {
    expect(v.validate('pan', 'WRONG').valid).toBe(false);
  });
  test('PAN: invalid holder type', () => {
    // 'D' is not a valid holder type
    expect(v.validate('pan', 'ABCDE1234F').valid).toBe(false);
  });

  test('Aadhaar: valid Verhoeff', () => {
    const r = v.validate('aadhaar', '234123412346');
    expect(r.valid).toBe(true);
  });
  test('Aadhaar: bad checksum', () => {
    expect(v.validate('aadhaar', '234123412345').valid).toBe(false);
  });
  test('Aadhaar: cannot start with 0/1', () => {
    expect(v.validate('aadhaar', '012345678901').valid).toBe(false);
  });

  test('GSTIN: valid', () => {
    expect(v.validate('gstin', '27AABCU9603R1ZX').valid).toBe(true);
  });
  test('GSTIN: bad state code', () => {
    expect(v.validate('gstin', '99AABCU9603R1ZX').valid).toBe(false);
  });

  test('UAN: 12 digits', () => {
    expect(v.validate('uan', '101234567890').valid).toBe(true);
    expect(v.validate('uan', '123').valid).toBe(false);
  });

  test('FSSAI: 14 digits', () => {
    expect(v.validate('fssai', '12345678901234').valid).toBe(true);
    expect(v.validate('fssai', '1234').valid).toBe(false);
  });

  test('CIN: structure', () => {
    expect(v.validate('cin', 'U12345MH2010PTC123456').valid).toBe(true);
    expect(v.validate('cin', 'INVALID').valid).toBe(false);
  });

  test('TAN: structure', () => {
    expect(v.validate('tan', 'ABCD12345E').valid).toBe(true);
  });

  test('Passport: structure', () => {
    expect(v.validate('passport', 'A1234567').valid).toBe(true);
    expect(v.validate('passport', 'Q1234567').valid).toBe(false); // Q not allowed
  });

  test('ICAI: 6 digits', () => {
    expect(v.validate('icai_membership', '123456').valid).toBe(true);
  });

  test('Trust score weighting', () => {
    expect(v.computeTrustScore(['pan', 'aadhaar'])).toBe(45);
    expect(v.computeTrustScore(['pan', 'aadhaar', 'gstin', 'icai_membership'])).toBeLessThanOrEqual(100);
  });

  test('Mask document number', () => {
    expect(v.maskDocNumber('ABCPE1234F')).toBe('AB****234F');
    expect(v.maskDocNumber('234123412346')).toBe('23******2346');
  });

  test('Role allowance', () => {
    expect(v.isAllowedForRole('customer', 'icai_membership')).toBe(false);
    expect(v.isAllowedForRole('professional', 'icai_membership')).toBe(true);
    expect(v.isAllowedForRole('customer', 'aadhaar')).toBe(true);
  });

  test('Unknown doc type rejected', () => {
    expect(v.validate('unknown', 'X').valid).toBe(false);
  });
});
