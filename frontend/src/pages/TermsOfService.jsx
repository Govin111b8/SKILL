import SEOMeta from '../components/SEOMeta';
import './Legal.css';

function TermsOfService() {
  return (
    <div className="legal-page">
      <SEOMeta title="Terms of Service" description="SkillConnect Terms of Service — the rules and conditions governing your use of the platform." />
      <div className="container legal-container">
        <h1>Terms of Service</h1>
        <p className="legal-effective">Effective date: 1 January 2025</p>

        <section>
          <h2>1. Acceptance of Terms</h2>
          <p>By accessing or using SkillConnect ("Platform", "we", "us"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree, do not use the Platform. These Terms apply to all visitors, customers, and professionals.</p>
        </section>

        <section>
          <h2>2. Platform Description</h2>
          <p>SkillConnect is a marketplace that connects customers with independent service professionals ("Professionals"). We do not employ Professionals; they are independent contractors. We facilitate connections but do not guarantee the quality of services rendered.</p>
        </section>

        <section>
          <h2>3. Account Registration</h2>
          <p>You must be at least 18 years old to create an account. You are responsible for maintaining the confidentiality of your credentials. You agree to provide accurate, current, and complete information during registration and to update it as necessary.</p>
        </section>

        <section>
          <h2>4. Platform Fees & Payments</h2>
          <p>SkillConnect charges a platform fee of 5% + 18% GST on transactions. Professionals pay subscription fees (Basic: Free, Premium: ₹499/month or ₹4,020/year, Featured: ₹999/month or ₹8,040/year). All prices are inclusive of applicable taxes unless stated otherwise.</p>
          <p>Annual subscriptions offer a 33% discount over monthly billing. Subscriptions renew automatically unless cancelled before the renewal date.</p>
        </section>

        <section>
          <h2>5. Refund Policy</h2>
          <p>Service payments are held in escrow and released to Professionals only after job completion confirmation. If a dispute arises, SkillConnect will mediate per our Dispute Resolution Policy. Subscription fees are non-refundable except where required by law.</p>
        </section>

        <section>
          <h2>6. Prohibited Conduct</h2>
          <ul>
            <li>Providing false information during registration or verification</li>
            <li>Harassing, abusing, or threatening other users</li>
            <li>Circumventing platform payments (off-platform transactions)</li>
            <li>Submitting fake reviews or manipulating ratings</li>
            <li>Using the platform for illegal activities</li>
          </ul>
        </section>

        <section>
          <h2>7. Intellectual Property</h2>
          <p>All content on SkillConnect (logos, text, software, design) is owned by SkillConnect Pvt. Ltd. or licensed to us. You may not reproduce, distribute, or create derivative works without our express permission.</p>
        </section>

        <section>
          <h2>8. Limitation of Liability</h2>
          <p>To the maximum extent permitted by law, SkillConnect shall not be liable for indirect, incidental, special, consequential, or punitive damages arising from your use of the Platform. Our total liability shall not exceed the greater of ₹5,000 or the fees paid by you in the last 12 months.</p>
        </section>

        <section>
          <h2>9. Governing Law</h2>
          <p>These Terms are governed by the laws of India. Any disputes shall be subject to the exclusive jurisdiction of courts in Bangalore, Karnataka.</p>
        </section>

        <section>
          <h2>10. Contact</h2>
          <p>For questions about these Terms, contact us at <a href="mailto:legal@skillconnect.in">legal@skillconnect.in</a> or SkillConnect Pvt. Ltd., No. 1, MG Road, Bangalore 560001.</p>
        </section>
      </div>
    </div>
  );
}

export default TermsOfService;
