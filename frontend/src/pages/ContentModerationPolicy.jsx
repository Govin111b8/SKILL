import SEOMeta from '../components/SEOMeta';
import './Legal.css';

function ContentModerationPolicy() {
  return (
    <div className="legal-page">
      <SEOMeta title="Content Moderation Policy" description="How SkillConnect moderates reviews, profiles, and user-generated content." />
      <div className="container legal-container">
        <h1>Content Moderation Policy</h1>
        <p className="legal-effective">Effective date: 1 January 2025</p>

        <section>
          <h2>Reviews & Ratings</h2>
          <p>All reviews undergo automated and manual moderation before publishing. We hold reviews that:</p>
          <ul>
            <li>Contain profanity or hate speech</li>
            <li>Show velocity patterns (more than 5 reviews to one professional in 24 hours)</li>
            <li>Are submitted outside the allowed window (1 hour to 60 days after service)</li>
            <li>Appear to be incentivised or fake</li>
          </ul>
          <p>Professionals can flag reviews for re-moderation once. Customers can edit their review within 24 hours of submission (comment only; rating is locked).</p>
        </section>

        <section>
          <h2>Profile Content</h2>
          <p>Professional profiles must not contain false credentials, misleading pricing, or contact details that bypass the platform. Portfolio images must be original work. Violating profiles are suspended pending review.</p>
        </section>

        <section>
          <h2>Chat & Messages</h2>
          <p>Our automated system scans messages for prohibited content (spam, off-platform contact solicitation, abusive language). Reported messages are reviewed by our Trust & Safety team within 24 hours.</p>
        </section>

        <section>
          <h2>Penalties</h2>
          <table className="legal-table">
            <thead><tr><th>Violation</th><th>Action</th></tr></thead>
            <tbody>
              <tr><td>First minor violation</td><td>Warning + content removal</td></tr>
              <tr><td>Repeated minor violations</td><td>7-day suspension</td></tr>
              <tr><td>Major violation (fraud, abuse)</td><td>Immediate ban</td></tr>
              <tr><td>Criminal activity</td><td>Ban + law enforcement referral</td></tr>
            </tbody>
          </table>
        </section>

        <section>
          <h2>Appeals</h2>
          <p>Suspended or banned accounts may submit an appeal within 30 days via <a href="mailto:appeals@skillconnect.in">appeals@skillconnect.in</a>. Decisions are typically communicated within 5 business days.</p>
        </section>
      </div>
    </div>
  );
}

export default ContentModerationPolicy;
