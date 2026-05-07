import SEOMeta from '../components/SEOMeta';
import './Legal.css';

function RefundPolicy() {
  return (
    <div className="legal-page">
      <SEOMeta title="Refund Policy" description="SkillConnect Refund and Cancellation Policy — when and how refunds are processed." />
      <div className="container legal-container">
        <h1>Refund & Cancellation Policy</h1>
        <p className="legal-effective">Effective date: 1 January 2025</p>

        <section>
          <h2>Service Payments (Bookings)</h2>
          <p>All service payments are held in escrow until the job is marked complete. If a dispute is raised within 7 days of completion, SkillConnect will investigate and may issue a full or partial refund based on the outcome.</p>
          <table className="legal-table">
            <thead><tr><th>Scenario</th><th>Refund</th><th>Timeline</th></tr></thead>
            <tbody>
              <tr><td>Cancelled by customer before professional accepts</td><td>100%</td><td>3–5 business days</td></tr>
              <tr><td>Cancelled by professional</td><td>100%</td><td>3–5 business days</td></tr>
              <tr><td>No-show by professional</td><td>100%</td><td>3–5 business days</td></tr>
              <tr><td>Service not delivered as agreed</td><td>Up to 100% (after investigation)</td><td>7–14 business days</td></tr>
              <tr><td>Cancellation by customer after acceptance</td><td>50% (platform fee deducted)</td><td>5–7 business days</td></tr>
            </tbody>
          </table>
        </section>

        <section>
          <h2>Subscription Fees</h2>
          <p>Monthly subscriptions are non-refundable once the billing period begins. Annual subscriptions may be refunded on a pro-rata basis within 7 days of purchase. No refund is available after 7 days.</p>
        </section>

        <section>
          <h2>How to Request a Refund</h2>
          <ol>
            <li>Go to your Booking or Payment history</li>
            <li>Click "Raise Dispute" on the relevant transaction</li>
            <li>Provide a description and supporting evidence (photos, messages)</li>
            <li>Our team will respond within 48 hours</li>
          </ol>
        </section>

        <section>
          <h2>Contact</h2>
          <p>Email: <a href="mailto:support@skillconnect.in">support@skillconnect.in</a></p>
        </section>
      </div>
    </div>
  );
}

export default RefundPolicy;
