import { useState, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import { FiPlay, FiHeart, FiBookmark, FiShare2, FiStar, FiUser, FiChevronUp, FiChevronDown } from 'react-icons/fi';
import { get } from '../api/client';
import LoadingSpinner from '../components/LoadingSpinner';
import './ReelsFeed.css';

export default function ReelsFeed() {
  const [reels, setReels] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [current, setCurrent] = useState(0);
  const containerRef = useRef(null);

  useEffect(() => {
    loadReels();
  }, [page]);

  async function loadReels() {
    try {
      const res = await get(`/reels/feed?page=${page}&limit=10`);
      const data = res.data || [];
      setReels(prev => page === 1 ? data : [...prev, ...data]);
    } catch {
    } finally {
      setLoading(false);
    }
  }

  function navigate(direction) {
    setCurrent(prev => {
      const next = prev + direction;
      if (next < 0 || next >= reels.length) return prev;
      return next;
    });
  }

  function handleKeyDown(e) {
    if (e.key === 'ArrowUp') { e.preventDefault(); navigate(-1); }
    if (e.key === 'ArrowDown') { e.preventDefault(); navigate(1); }
  }

  useEffect(() => {
    if (current >= reels.length - 2 && reels.length > 0) {
      setPage(p => p + 1);
    }
  }, [current, reels.length]);

  if (loading && reels.length === 0) return <LoadingSpinner />;

  if (reels.length === 0) {
    return (
      <div className="reels-empty">
        <FiPlay size={48} />
        <h3>No Reels Yet</h3>
        <p>Professionals will post reels showing their work transformations.</p>
      </div>
    );
  }

  const reel = reels[current];

  return (
    <div className="reels-feed" ref={containerRef} tabIndex={0} onKeyDown={handleKeyDown}>
      <div className="reel-viewer">
        <video
          key={reel.id}
          src={reel.media_url}
          poster={reel.thumbnail_url}
          autoPlay muted loop playsInline
          className="reel-video"
          aria-label={`Reel by ${reel.professional_name}`}
        />

        <div className="reel-gradient" />

        <div className="reel-info">
          <Link to={`/professionals/${reel.professional_id}/storefront`} className="reel-author">
            <div className="reel-avatar">
              {reel.avatar_url
                ? <img src={reel.avatar_url} alt={reel.professional_name} />
                : <FiUser size={18} />
              }
            </div>
            <div>
              <strong>{reel.professional_name}</strong>
              {reel.headline && <span className="reel-headline">{reel.headline}</span>}
              {reel.average_rating > 0 && (
                <span className="reel-rating"><FiStar size={12} fill="#f59e0b" /> {reel.average_rating.toFixed(1)}</span>
              )}
            </div>
          </Link>
          {reel.caption && <p className="reel-caption">{reel.caption}</p>}
        </div>

        <div className="reel-actions-side">
          <button className="reel-action" aria-label="Like"><FiHeart size={22} /></button>
          <button className="reel-action" aria-label="Save"><FiBookmark size={22} /></button>
          <button className="reel-action" aria-label="Share" onClick={() => navigator.share?.({ url: window.location.href })}><FiShare2 size={22} /></button>
          <Link to={`/bookings/create?professional_id=${reel.professional_id}&professional_name=${encodeURIComponent(reel.professional_name)}`} className="reel-book-btn">
            Book
          </Link>
        </div>

        <div className="reel-nav">
          <button onClick={() => navigate(-1)} disabled={current === 0} aria-label="Previous reel"><FiChevronUp size={24} /></button>
          <span className="reel-counter">{current + 1}/{reels.length}</span>
          <button onClick={() => navigate(1)} disabled={current >= reels.length - 1} aria-label="Next reel"><FiChevronDown size={24} /></button>
        </div>
      </div>
    </div>
  );
}
