import SEOMeta from '../components/SEOMeta';
import './Legal.css';

function PrivacyPolicy() {
  return (
    <div className="legal-page">
      <SEOMeta title="Privacy Policy" description="SkillConnect Privacy Policy — how we collect, use, and protect your personal data under DPDPA 2023." />
      <div className="container legal-container">
        <h1>Privacy Policy</h1>
        <p className="legal-effective">Effective date: 1 January 2025 | Compliant with Digital Personal Data Protection Act 2023</p>

        <section>
          <h2>1. Data Controller</h2>
          <p>SkillConnect Pvt. Ltd. ("we", "us") is the Data Fiduciary under the Digital Personal Data Protection Act 2023 (DPDPA). Contact: <a href="mailto:privacy@skillconnect.in">privacy@skillconnect.in</a></p>
        </section>

        <section>
          <h2>2. Data We Collect</h2>
          <table className="legal-table">
            <thead><tr><th>Category</th><th>Examples</th><th>Purpose</th></tr></thead>
            <tbody>
              <tr><td>Identity</td><td>Name, email, phone</td><td>Account creation, communication</td></tr>
              <tr><td>Government ID</td><td>Aadhaar, PAN, Passport</td><td>KYC verification (Professionals only)</td></tr>
              <tr><td>Location</td><td>City, latitude/longitude</td><td>Search & matching</td></tr>
              <tr><td>Usage</td><td>Search history, views</td><td>Platform improvement</td></tr>
              <tr><td>Device</td><td>FCM token, IP address</td><td>Push notifications, security</td></tr>
            </tbody>
          </table>
        </section>

        <section>
          <h2>3. Legal Basis for Processing</h2>
          <p>We process your data based on: (a) your consent; (b) performance of a contract (service delivery); (c) legitimate interests (fraud prevention, security); (d) legal obligation (tax records, KYC compliance).</p>
        </section>

        <section>
          <h2>4. Data Sharing</h2>
          <p>We share data with: payment processors (Razorpay), communication providers (SendGrid, MSG91), cloud storage (AWS S3), and analytics (Sentry). We do not sell your personal data. All third parties are bound by data processing agreements.</p>
        </section>

        <section>
          <h2>5. Data Retention</h2>
          <ul>
            <li>Account data: 30-day soft delete, then permanent erasure within 90 days of deletion request</li>
            <li>KYC documents: deleted 12 months after verification</li>
            <li>Transaction records: 7 years (IT Act compliance)</li>
            <li>Logs: 90 days</li>
          </ul>
        </section>

        <section>
          <h2>6. Your Rights (DPDPA 2023)</h2>
          <ul>
            <li><strong>Right to Access</strong> — Download your data via Settings → Export My Data</li>
            <li><strong>Right to Correction</strong> — Update your profile at any time</li>
            <li><strong>Right to Erasure</strong> — Request account deletion via Settings → Delete Account</li>
            <li><strong>Right to Grievance Redressal</strong> — Contact our Data Protection Officer</li>
          </ul>
        </section>

        <section>
          <h2>7. Cookies</h2>
          <p>We use essential cookies for authentication and optional analytics cookies. You can manage cookie preferences in our Cookie Preference Centre (footer link).</p>
        </section>

        <section>
          <h2>8. Data Protection Officer</h2>
          <p>Email: <a href="mailto:dpo@skillconnect.in">dpo@skillconnect.in</a> | Response time: 72 hours for breach notifications, 30 days for data requests.</p>
        </section>
      </div>
    </div>
  );
}

export default PrivacyPolicy;
