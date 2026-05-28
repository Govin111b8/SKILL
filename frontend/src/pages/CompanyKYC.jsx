import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  FiShield, FiCheckCircle, FiUpload, FiAlertCircle, FiArrowLeft, FiArrowRight,
  FiFileText, FiAward, FiBriefcase, FiLoader,
} from 'react-icons/fi';
import { get, post } from '../api/client';
import { useAuth } from '../context/AuthContext';
import './CompanyKYC.css';

// Company-specific KYC document types and their display info
const COMPANY_DOC_STEPS = [
  {
    key: 'gstin',
    label: 'GST Registration',
    icon: FiFileText,
    description: 'Your 15-character GSTIN issued by the Government of India',
    placeholder: '29ABCDE1234F1Z5',
    required: true,
    hint: 'Format: 2-digit state code + 10-char PAN + entity digit + Z + check digit',
  },
  {
    key: 'cin',
    label: 'Company Identification Number (CIN)',
    icon: FiBriefcase,
    description: 'CIN is issued by the Registrar of Companies (MCA). Required for Pvt Ltd / Ltd companies.',
    placeholder: 'U12345MH2010PTC123456',
    required: false,
    hint: 'Format: L/U + 5-digit industry + 2-letter state + 4-digit year + type + 6-digit reg',
  },
  {
    key: 'msme_udyam',
    label: 'Udyam / MSME Registration',
    icon: FiAward,
    description: 'Udyam certificate for Micro, Small and Medium Enterprises',
    placeholder: 'UDYAM-MH-01-0123456',
    required: false,
    hint: 'Format: UDYAM-SS-NN-NNNNNNN',
  },
  {
    key: 'pan',
    label: 'Company PAN Card',
    icon: FiFileText,
    description: 'PAN card issued in the company name (PAN type C for Company)',
    placeholder: 'ABCDE1234F',
    required: true,
    hint: 'Must be a company PAN (4th character = C for company, F for firm)',
  },
];

const STATUS_COLORS = {
  verified: 'green',
  pending: 'orange',
  rejected: 'red',
  not_submitted: 'gray',
};

export default function CompanyKYC() {
  const navigate = useNavigate();
  const { user } = useAuth();

  const [step, setStep] = useState(0);
  const [submissions, setSubmissions] = useState({});
  const [existing, setExisting] = useState([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  const [form, setForm] = useState({
    doc_number: '',
    holder_name: '',
    document_url: '',
    issuing_authority: '',
  });

  useEffect(() => {
    fetchExisting();
  }, []);

  async function fetchExisting() {
    setLoading(true);
    try {
      const res = await get('/kyc/me');
      setExisting(res.data.data || []);
    } catch (err) {
      console.error('Failed to load KYC data:', err);
    }
    setLoading(false);
  }

  function getExistingDoc(docType) {
    return existing.find(e => e.doc_type === docType);
  }

  function getDocStatus(docType) {
    const doc = getExistingDoc(docType);
    if (!doc) return 'not_submitted';
    return doc.status;
  }

  const currentDocStep = COMPANY_DOC_STEPS[step];

  function handleFormChange(field, value) {
    setForm(f => ({ ...f, [field]: value }));
    setError(null);
  }

  async function handleSubmitDoc() {
    if (!form.doc_number.trim()) {
      setError('Document number is required');
      return;
    }
    setSubmitting(true);
    setError(null);
    setSuccess(null);
    try {
      await post('/kyc/submit', {
        doc_type: currentDocStep.key,
        doc_number: form.doc_number.trim(),
        holder_name: form.holder_name.trim() || undefined,
        document_url: form.document_url.trim() || undefined,
        issuing_authority: form.issuing_authority.trim() || undefined,
      });
      setSuccess(`${currentDocStep.label} submitted successfully! Our team will verify it within 24-48 hours.`);
      setForm({ doc_number: '', holder_name: '', document_url: '', issuing_authority: '' });
      setSubmissions(s => ({ ...s, [currentDocStep.key]: true }));
      await fetchExisting();
    } catch (err) {
      setError(err.response?.data?.message || 'Submission failed. Please check the document number and try again.');
    }
    setSubmitting(false);
  }

  function handleSkip() {
    setError(null);
    setSuccess(null);
    setForm({ doc_number: '', holder_name: '', document_url: '', issuing_authority: '' });
    if (step < COMPANY_DOC_STEPS.length - 1) {
      setStep(s => s + 1);
    } else {
      navigate('/dashboard');
    }
  }

  function handleNext() {
    setError(null);
    setSuccess(null);
    setForm({ doc_number: '', holder_name: '', document_url: '', issuing_authority: '' });
    if (step < COMPANY_DOC_STEPS.length - 1) {
      setStep(s => s + 1);
    } else {
      navigate('/dashboard');
    }
  }

  const completedCount = COMPANY_DOC_STEPS.filter(d => {
    const status = getDocStatus(d.key);
    return status === 'verified' || status === 'pending' || submissions[d.key];
  }).length;

  const progressPct = Math.round((completedCount / COMPANY_DOC_STEPS.length) * 100);

  if (loading) {
    return (
      <div className="ckyc-page">
        <div className="ckyc-card" style={{ textAlign: 'center', padding: '3rem' }}>
          <FiLoader size={32} style={{ animation: 'spin 1s linear infinite', color: '#6366f1' }} />
          <p style={{ marginTop: '1rem', color: '#6b7280' }}>Loading KYC status…</p>
        </div>
      </div>
    );
  }

  const docStatus = getDocStatus(currentDocStep.key);
  const alreadySubmitted = docStatus !== 'not_submitted' || submissions[currentDocStep.key];

  return (
    <div className="ckyc-page">
      {/* Header */}
      <div className="ckyc-header">
        <button className="ckyc-back" onClick={() => navigate(-1)} aria-label="Go back">
          <FiArrowLeft size={18} /> Back
        </button>
        <div>
          <h1 className="ckyc-title">
            <FiShield size={22} /> Company KYC Verification
          </h1>
          <p className="ckyc-subtitle">Verify your company documents to unlock full platform access</p>
        </div>
      </div>

      <div className="ckyc-layout">
        {/* Sidebar — doc checklist */}
        <aside className="ckyc-sidebar">
          <h2 className="ckyc-sidebar-title">Documents</h2>
          <div className="ckyc-progress-bar">
            <div className="ckyc-progress-fill" style={{ width: `${progressPct}%` }} />
          </div>
          <p className="ckyc-progress-label">{completedCount}/{COMPANY_DOC_STEPS.length} submitted</p>
          <ul className="ckyc-checklist">
            {COMPANY_DOC_STEPS.map((d, i) => {
              const st = getDocStatus(d.key);
              const submitted = submissions[d.key] || st !== 'not_submitted';
              return (
                <li
                  key={d.key}
                  className={`ckyc-checklist-item ${i === step ? 'active' : ''}`}
                  onClick={() => { setStep(i); setError(null); setSuccess(null); setForm({ doc_number: '', holder_name: '', document_url: '', issuing_authority: '' }); }}
                >
                  <span className={`ckyc-status-dot ckyc-status-dot--${submitted ? (st === 'verified' ? 'green' : st === 'rejected' ? 'red' : 'orange') : 'gray'}`} />
                  <div className="ckyc-checklist-text">
                    <span className="ckyc-checklist-label">{d.label}</span>
                    {d.required && <span className="ckyc-required-badge">Required</span>}
                  </div>
                  {submitted && st === 'verified' && <FiCheckCircle size={14} color="#10b981" />}
                </li>
              );
            })}
          </ul>

          <div className="ckyc-trust-box">
            <FiShield size={16} />
            <p>All documents are encrypted with AES-256 and reviewed by our compliance team within 24–48 hours.</p>
          </div>
        </aside>

        {/* Main form */}
        <div className="ckyc-main">
          <div className="ckyc-card">
            {/* Step indicator */}
            <div className="ckyc-step-indicator">
              Step {step + 1} of {COMPANY_DOC_STEPS.length}
            </div>

            <div className="ckyc-card-header">
              <div className="ckyc-doc-icon">
                <currentDocStep.icon size={24} />
              </div>
              <div>
                <h2 className="ckyc-card-title">{currentDocStep.label}</h2>
                <p className="ckyc-card-desc">{currentDocStep.description}</p>
              </div>
              {!currentDocStep.required && (
                <span className="ckyc-optional-badge">Optional</span>
              )}
            </div>

            {/* Existing status */}
            {alreadySubmitted && (
              <div className={`ckyc-status-banner ckyc-status-banner--${STATUS_COLORS[docStatus] || 'orange'}`}>
                {docStatus === 'verified' && <><FiCheckCircle size={16} /> Document verified ✓</>}
                {docStatus === 'pending' && <><FiAlertCircle size={16} /> Under review — our team will notify you</>}
                {docStatus === 'rejected' && <><FiAlertCircle size={16} /> Rejected — you can resubmit below</>}
                {docStatus === 'not_submitted' && submissions[currentDocStep.key] && <><FiCheckCircle size={16} /> Submitted successfully — pending review</>}
              </div>
            )}

            {success && (
              <div className="ckyc-alert ckyc-alert--success">
                <FiCheckCircle size={16} /> {success}
              </div>
            )}

            {error && (
              <div className="ckyc-alert ckyc-alert--error">
                <FiAlertCircle size={16} /> {error}
              </div>
            )}

            {/* Form — show if not verified (allow resubmit if rejected) */}
            {(docStatus !== 'verified') && (
              <div className="ckyc-form">
                <div className="ckyc-field">
                  <label className="ckyc-label">
                    {currentDocStep.label} Number <span className="ckyc-req">*</span>
                  </label>
                  <input
                    className="ckyc-input"
                    type="text"
                    placeholder={currentDocStep.placeholder}
                    value={form.doc_number}
                    onChange={e => handleFormChange('doc_number', e.target.value.toUpperCase())}
                    disabled={submitting}
                  />
                  {currentDocStep.hint && (
                    <p className="ckyc-hint">{currentDocStep.hint}</p>
                  )}
                </div>

                <div className="ckyc-field">
                  <label className="ckyc-label">Registered Name (as on document)</label>
                  <input
                    className="ckyc-input"
                    type="text"
                    placeholder="Company legal name"
                    value={form.holder_name}
                    onChange={e => handleFormChange('holder_name', e.target.value)}
                    disabled={submitting}
                  />
                </div>

                <div className="ckyc-field">
                  <label className="ckyc-label">Document Upload URL <span className="ckyc-optional-label">(optional — upload via settings)</span></label>
                  <div className="ckyc-upload-row">
                    <input
                      className="ckyc-input"
                      type="url"
                      placeholder="https://... (link to scanned document)"
                      value={form.document_url}
                      onChange={e => handleFormChange('document_url', e.target.value)}
                      disabled={submitting}
                    />
                    <FiUpload size={16} className="ckyc-upload-icon" />
                  </div>
                </div>

                <div className="ckyc-actions">
                  <button
                    className="btn btn-primary ckyc-submit-btn"
                    onClick={handleSubmitDoc}
                    disabled={submitting}
                  >
                    {submitting ? 'Submitting…' : 'Submit for Verification'}
                  </button>
                  {!currentDocStep.required && (
                    <button className="btn btn-outline" onClick={handleSkip} disabled={submitting}>
                      Skip
                    </button>
                  )}
                </div>
              </div>
            )}

            {/* Navigation */}
            <div className="ckyc-nav">
              <button
                className="btn btn-outline"
                onClick={() => setStep(s => Math.max(0, s - 1))}
                disabled={step === 0}
              >
                <FiArrowLeft size={15} /> Previous
              </button>
              <button
                className="btn btn-primary"
                onClick={handleNext}
              >
                {step === COMPANY_DOC_STEPS.length - 1 ? 'Finish & Go to Dashboard' : 'Next'} <FiArrowRight size={15} />
              </button>
            </div>
          </div>

          {/* Benefits box */}
          <div className="ckyc-benefits">
            <h3>Benefits of Company Verification</h3>
            <ul>
              <li><FiCheckCircle size={14} /> 🏆 "Verified Company" badge on your storefront</li>
              <li><FiCheckCircle size={14} /> 📈 Higher ranking in search results</li>
              <li><FiCheckCircle size={14} /> 💼 Access to B2B and Society contracts</li>
              <li><FiCheckCircle size={14} /> 🔒 Customer trust increases booking conversion by 3x</li>
              <li><FiCheckCircle size={14} /> 💰 Unlock GST-compliant invoice generation</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}
