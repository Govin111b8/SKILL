import SEOMeta from '../components/SEOMeta';
import './Legal.css';

function CookiePolicy() {
  return (
    <div className="legal-page">
      <SEOMeta title="Cookie Policy" description="SkillConnect Cookie Policy — how we use cookies and how you can control them." />
      <div className="container legal-container">
        <h1>Cookie Policy</h1>
        <p className="legal-effective">Effective date: 1 January 2025</p>

        <section>
          <h2>What Are Cookies?</h2>
          <p>Cookies are small text files stored on your device when you visit a website. They help us provide a personalised, secure experience.</p>
        </section>

        <section>
          <h2>Cookies We Use</h2>
          <table className="legal-table">
            <thead><tr><th>Cookie</th><th>Type</th><th>Purpose</th><th>Duration</th></tr></thead>
            <tbody>
              <tr><td>sc_session</td><td>Essential</td><td>Maintain login session</td><td>Session</td></tr>
              <tr><td>sc_city</td><td>Functional</td><td>Remember your selected city</td><td>1 year</td></tr>
              <tr><td>sc_cookie_consent</td><td>Essential</td><td>Store cookie consent decision</td><td>1 year</td></tr>
              <tr><td>sc_analytics</td><td>Analytics (optional)</td><td>Measure platform usage</td><td>90 days</td></tr>
            </tbody>
          </table>
        </section>

        <section>
          <h2>Managing Cookies</h2>
          <p>You can manage cookie preferences using the cookie banner at the bottom of this page. You can also clear cookies through your browser settings. Disabling essential cookies may affect platform functionality.</p>
        </section>

        <section>
          <h2>Third-Party Cookies</h2>
          <p>We do not use third-party advertising cookies. Analytics data is processed by Sentry (error tracking) and our own analytics system. No data is sold to ad networks.</p>
        </section>

        <section>
          <h2>Contact</h2>
          <p>Questions about our cookie use: <a href="mailto:privacy@skillconnect.in">privacy@skillconnect.in</a></p>
        </section>
      </div>
    </div>
  );
}

export default CookiePolicy;
