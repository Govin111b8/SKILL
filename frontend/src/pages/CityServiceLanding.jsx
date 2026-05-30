import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { FiMapPin, FiStar, FiArrowRight, FiCheck } from 'react-icons/fi';
import { get } from '../api/client';
import SEOMeta from '../components/SEOMeta';
import LoadingSpinner from '../components/LoadingSpinner';
import './CityServiceLanding.css';

const CITY_DISPLAY = {
  hyderabad: 'Hyderabad', bengaluru: 'Bengaluru', bangalore: 'Bengaluru',
  mumbai: 'Mumbai', delhi: 'Delhi', chennai: 'Chennai',
  pune: 'Pune', ahmedabad: 'Ahmedabad', kolkata: 'Kolkata',
};

const SERVICE_DISPLAY = {
  'ac-repair': 'AC Repair & Service', cleaning: 'Home Cleaning',
  plumber: 'Plumber', electrician: 'Electrician',
  beauty: 'Beauty & Salon at Home', 'pest-control': 'Pest Control',
  carpenter: 'Carpenter', painting: 'Home Painting',
  'ro-service': 'RO Water Purifier Service', 'geyser-repair': 'Geyser Repair',
};

export default function CityServiceLanding() {
  const { city, service } = useParams();
  const [professionals, setProfessionals] = useState([]);
  const [loading, setLoading] = useState(true);

  const cityDisplay = CITY_DISPLAY[city?.toLowerCase()] || city?.charAt(0).toUpperCase() + city?.slice(1);
  const serviceDisplay = SERVICE_DISPLAY[service?.toLowerCase()] || service?.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');

  useEffect(() => {
    if (!city || !service) return;
    setLoading(true);
    get(`/search?q=${encodeURIComponent(serviceDisplay)}&city=${encodeURIComponent(cityDisplay)}&limit=6`)
      .then(res => setProfessionals(res.data?.professionals || res.data || []))
      .catch(() => setProfessionals([]))
      .finally(() => setLoading(false));
  }, [city, service, cityDisplay, serviceDisplay]);

  const title = `${serviceDisplay} in ${cityDisplay} — SkillConnect`;
  const description = `Book verified ${serviceDisplay} professionals in ${cityDisplay}. Trusted by thousands, with live tracking and 7-day service warranty. Starting ₹199.`;

  const WHY_US = [
    'Aadhaar-verified professionals',
    'Real-time GPS job tracking',
    '7-day service warranty',
    'Transparent pricing — no hidden charges',
    '9 Indian language support',
    'Pay via UPI, Card, EMI, or Cash',
  ];

  return (
    <div className="city-landing-page">
      <SEOMeta title={title} description={description} />

      <div className="city-landing-hero">
        <div className="city-landing-hero-content">
          <div className="city-landing-location"><FiMapPin /> {cityDisplay}</div>
          <h1>{serviceDisplay} <span>in {cityDisplay}</span></h1>
          <p>Verified professionals • Live tracking • 7-day warranty</p>
          <Link to={`/search?q=${encodeURIComponent(serviceDisplay)}&city=${encodeURIComponent(cityDisplay)}`} className="city-landing-cta">
            Book Now <FiArrowRight />
          </Link>
        </div>
      </div>

      <div className="city-landing-body">
        <section className="city-landing-why">
          <h2>Why SkillConnect?</h2>
          <ul>
            {WHY_US.map(item => <li key={item}><FiCheck color="#10b981" /> {item}</li>)}
          </ul>
        </section>

        <section className="city-landing-pros">
          <h2>Top {serviceDisplay} Professionals in {cityDisplay}</h2>
          {loading ? <LoadingSpinner /> : (
            <div className="city-landing-pro-grid">
              {professionals.slice(0, 6).map(pro => (
                <Link key={pro.id} to={`/storefront/${pro.professional_id || pro.id}`} className="city-landing-pro-card">
                  <img src={pro.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(pro.name || 'Pro')}&background=random`} alt={pro.name} />
                  <div>
                    <div className="pro-card-name">{pro.name}</div>
                    <div className="pro-card-rating">
                      <FiStar size={13} color="#f59e0b" />
                      {parseFloat(pro.average_rating || 4.5).toFixed(1)} · {pro.completed_jobs || 0}+ jobs
                    </div>
                    {pro.trust_level && <div className={`pro-card-trust trust-${pro.trust_level}`}>{pro.trust_level}</div>}
                  </div>
                </Link>
              ))}
              {professionals.length === 0 && (
                <div className="no-pros-yet">
                  <p>Be the first to find a {serviceDisplay} pro in {cityDisplay}!</p>
                  <Link to={`/search?q=${encodeURIComponent(serviceDisplay)}`} className="city-landing-cta">Search Nearby</Link>
                </div>
              )}
            </div>
          )}
        </section>

        <section className="city-landing-faq">
          <h2>Frequently Asked Questions</h2>
          <details><summary>How quickly can I get a {serviceDisplay} professional?</summary><p>Most professionals in {cityDisplay} respond within 30 minutes. You can also book a scheduled appointment for later.</p></details>
          <details><summary>What is the service warranty?</summary><p>All SkillConnect services come with a 7-day service warranty. If the issue recurs, we'll send a professional at no extra charge.</p></details>
          <details><summary>Are the professionals verified?</summary><p>Yes. Every professional on SkillConnect goes through Aadhaar identity verification and background checks before serving customers.</p></details>
          <details><summary>What payment methods are accepted?</summary><p>We accept UPI, debit/credit cards, net banking, EMI (for orders above ₹3,000), and cash on delivery.</p></details>
        </section>
      </div>
    </div>
  );
}
