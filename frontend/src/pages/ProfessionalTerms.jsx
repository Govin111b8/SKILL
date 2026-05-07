import SEOMeta from '../components/SEOMeta';
import './Legal.css';

function ProfessionalTerms() {
  return (
    <div className="legal-page">
      <SEOMeta title="Professional Terms & Conditions" description="Terms and conditions governing SkillConnect professionals — commission, KYC, subscription, and code of conduct." />
      <div className="container legal-container">
        <h1>Professional Terms & Conditions</h1>
        <p className="legal-effective">Effective date: 1 January 2025</p>

        <section>
          <h2>1. Independent Contractor Status</h2>
          <p>Professionals using SkillConnect are independent contractors, not employees, agents, or partners of SkillConnect. You are solely responsible for your taxes, insurance, tools, and compliance with applicable laws.</p>
        </section>

        <section>
          <h2>2. Subscription Plans & Pricing</h2>
          <table className="legal-table">
            <thead><tr><th>Plan</th><th>Monthly</th><th>Annual (33% off)</th><th>Benefits</th></tr></thead>
            <tbody>
              <tr><td>Basic</td><td>Free</td><td>Free</td><td>5 photos, standard listing</td></tr>
              <tr><td>Premium</td><td>₹499/mo</td><td>₹4,020/yr</td><td>20 photos, 5 videos, priority ranking, analytics</td></tr>
              <tr><td>Featured</td><td>₹999/mo</td><td>₹8,040/yr</td><td>All Premium + home page placement, featured badge</td></tr>
            </tbody>
          </table>
          <p>A 3-day grace period is applied after subscription expiry before downgrade to Basic.</p>
        </section>

        <section>
          <h2>3. Platform Commission</h2>
          <p>SkillConnect charges a 5% platform fee + 18% GST on all booking payments. This fee is deducted before payout. Payouts are processed within 3 business days of job completion confirmation.</p>
        </section>

        <section>
          <h2>4. KYC Requirements</h2>
          <p>All professionals must complete KYC (Know Your Customer) verification before appearing in search results. Accepted documents: Aadhaar, PAN, Passport, Voter ID, or Driving Licence. KYC documents are stored for up to 12 months after verification and then purged per our data retention policy.</p>
        </section>

        <section>
          <h2>5. Quality Standards</h2>
          <ul>
            <li>Maintain a Trust Index of at least 40/100 to remain in search</li>
            <li>Respond to contact requests within 24 hours</li>
            <li>Do not solicit customers to bypass the platform</li>
            <li>Do not submit fake reviews or manipulate ratings</li>
          </ul>
        </section>

        <section>
          <h2>6. Termination</h2>
          <p>SkillConnect may suspend or terminate your account for violations of these Terms, low Trust Index (below 20), or fraudulent behaviour. You may appeal within 30 days of suspension.</p>
        </section>

        <section>
          <h2>7. Disputes with Customers</h2>
          <p>All disputes must be handled through SkillConnect's dispute resolution system. Do not engage in off-platform settlement without notifying SkillConnect first.</p>
        </section>

        <section>
          <h2>8. Contact</h2>
          <p>Professional support: <a href="mailto:pros@skillconnect.in">pros@skillconnect.in</a></p>
        </section>
      </div>
    </div>
  );
}

export default ProfessionalTerms;
