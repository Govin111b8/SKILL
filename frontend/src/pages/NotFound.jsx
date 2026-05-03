import { Link } from 'react-router-dom';
import { FiHome, FiSearch, FiArrowLeft } from 'react-icons/fi';

function NotFound() {
  return (
    <div className="not-found-page">
      <div className="not-found-bg">
        <div className="nf-blob nf-blob-1" />
        <div className="nf-blob nf-blob-2" />
        <div className="nf-blob nf-blob-3" />
      </div>
      <div className="not-found-content">
        <div className="not-found-code">
          <span className="nf-4">4</span>
          <span className="nf-0">
            <span className="nf-circle" />
          </span>
          <span className="nf-4">4</span>
        </div>
        <h2 className="not-found-title">Page Not Found</h2>
        <p className="not-found-desc">
          Oops! The page you&apos;re looking for doesn&apos;t exist or has been moved to a new location.
        </p>
        <div className="not-found-actions">
          <Link to="/" className="btn btn-primary btn-lg">
            <FiHome size={18} /> Go Home
          </Link>
          <Link to="/search" className="btn btn-outline btn-lg">
            <FiSearch size={18} /> Search Services
          </Link>
        </div>
        <button
          className="not-found-back"
          onClick={() => window.history.back()}
        >
          <FiArrowLeft size={14} /> Go back to previous page
        </button>
      </div>
      <style>{`
        .not-found-page {
          display: flex;
          align-items: center;
          justify-content: center;
          min-height: calc(100vh - 200px);
          padding: 2rem;
          position: relative;
          overflow: hidden;
          text-align: center;
        }
        .not-found-bg {
          position: absolute;
          inset: 0;
          pointer-events: none;
        }
        .nf-blob {
          position: absolute;
          border-radius: 50%;
          filter: blur(100px);
          opacity: 0.15;
          animation: blob 10s ease-in-out infinite;
        }
        .nf-blob-1 { width: 400px; height: 400px; background: #6366f1; top: -150px; left: -100px; }
        .nf-blob-2 { width: 350px; height: 350px; background: #8b5cf6; bottom: -100px; right: -80px; animation-delay: 3s; }
        .nf-blob-3 { width: 250px; height: 250px; background: #f97316; top: 50%; left: 60%; animation-delay: 6s; }
        .not-found-content {
          position: relative;
          z-index: 2;
          animation: fadeInUp 0.6s ease both;
        }
        .not-found-code {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 0.5rem;
          margin-bottom: 1.5rem;
        }
        .nf-4 {
          font-size: clamp(5rem, 12vw, 8rem);
          font-weight: 900;
          background: var(--gradient-primary);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          background-clip: text;
          line-height: 1;
          letter-spacing: -0.04em;
        }
        .nf-0 {
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .nf-circle {
          width: clamp(4rem, 10vw, 6.5rem);
          height: clamp(4rem, 10vw, 6.5rem);
          border-radius: 50%;
          border: 8px solid var(--primary);
          animation: pulse-ring 2s ease-in-out infinite;
          opacity: 0.8;
        }
        .not-found-title {
          font-size: 1.75rem;
          font-weight: 800;
          color: var(--gray-900);
          margin-bottom: 0.75rem;
          letter-spacing: -0.02em;
        }
        .not-found-desc {
          color: var(--gray-500);
          font-size: 1.05rem;
          max-width: 480px;
          margin: 0 auto 2rem;
          line-height: 1.7;
        }
        .not-found-actions {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 1rem;
          flex-wrap: wrap;
          margin-bottom: 1.5rem;
        }
        .not-found-back {
          display: inline-flex;
          align-items: center;
          gap: 0.35rem;
          color: var(--gray-400);
          font-size: 0.85rem;
          cursor: pointer;
          transition: color 0.2s;
          background: none;
          border: none;
          font-family: inherit;
        }
        .not-found-back:hover { color: var(--primary); }
      `}</style>
    </div>
  );
}

export default NotFound;
