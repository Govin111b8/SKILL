import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { FiHeart, FiShare2, FiMessageSquare, FiUser, FiClock } from 'react-icons/fi';
import { get, post } from '../api/client';
import { useAuth } from '../context/AuthContext';
import LoadingSpinner from '../components/LoadingSpinner';
import './CommunityFeed.css';

const CATEGORIES = ['All', 'Beauty', 'Home Services', 'Fitness', 'Tutoring', 'Photography', 'Technology', 'Other'];

export default function CommunityFeed() {
  const { isAuthenticated } = useAuth();
  const [posts, setPosts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [category, setCategory] = useState('All');
  const [page, setPage] = useState(1);

  useEffect(() => {
    loadPosts();
  }, [category, page]);

  async function loadPosts() {
    setLoading(true);
    try {
      const params = new URLSearchParams({ page: String(page), limit: '20' });
      if (category !== 'All') params.set('category', category);
      const res = await get(`/community/posts?${params}`);
      setPosts(res.data || []);
    } catch {
      setPosts([]);
    } finally {
      setLoading(false);
    }
  }

  async function handleLike(postId) {
    if (!isAuthenticated) return;
    try {
      const res = await post(`/community/posts/${postId}/like`);
      setPosts(prev =>
        prev.map(p =>
          p.id === postId
            ? { ...p, likes_count: res.liked ? p.likes_count + 1 : Math.max(0, p.likes_count - 1), user_liked: res.liked }
            : p
        )
      );
    } catch (err) { console.error('Failed to toggle like:', err.message); }
  }

  function formatDate(d) {
    const diff = Date.now() - new Date(d).getTime();
    const hours = Math.floor(diff / 3600000);
    if (hours < 1) return 'Just now';
    if (hours < 24) return `${hours}h ago`;
    const days = Math.floor(hours / 24);
    if (days < 7) return `${days}d ago`;
    return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  }

  return (
    <div className="community-feed">
      <div className="community-header">
        <h1>💡 Community Tips</h1>
        <p className="community-subtitle">Expert tips and advice from professionals</p>
      </div>

      <div className="category-filters">
        {CATEGORIES.map(cat => (
          <button
            key={cat}
            className={`cat-filter ${category === cat ? 'active' : ''}`}
            onClick={() => { setCategory(cat); setPage(1); }}
          >
            {cat}
          </button>
        ))}
      </div>

      {loading ? (
        <LoadingSpinner />
      ) : posts.length === 0 ? (
        <div className="empty-feed">
          <FiMessageSquare size={48} />
          <h3>No posts yet</h3>
          <p>Check back later for tips from professionals.</p>
        </div>
      ) : (
        <div className="posts-list">
          {posts.map(p => (
            <article key={p.id} className="post-card">
              <div className="post-author">
                <div className="post-avatar">
                  {p.author_avatar
                    ? <img src={p.author_avatar} alt={p.author_name} />
                    : <FiUser size={18} />
                  }
                </div>
                <div>
                  <Link
                    to={p.professional_id ? `/professionals/${p.professional_id}/storefront` : '#'}
                    className="author-name"
                  >
                    {p.author_name}
                  </Link>
                  {p.author_headline && <span className="author-headline">{p.author_headline}</span>}
                </div>
                <span className="post-time"><FiClock size={12} /> {formatDate(p.created_at)}</span>
              </div>

              <h2 className="post-title">{p.title}</h2>
              <p className="post-content">{p.content?.substring(0, 300)}{p.content?.length > 300 ? '...' : ''}</p>

              {p.media_urls?.length > 0 && (
                <div className="post-media">
                  {p.media_urls.slice(0, 3).map((url, i) => (
                    <img key={i} src={url} alt="" className="post-image" />
                  ))}
                </div>
              )}

              {p.category && <span className="post-category">{p.category}</span>}

              <div className="post-actions">
                <button
                  className={`action-btn ${p.user_liked ? 'liked' : ''}`}
                  onClick={() => handleLike(p.id)}
                >
                  <FiHeart size={16} fill={p.user_liked ? '#ef4444' : 'none'} />
                  {p.likes_count > 0 && <span>{p.likes_count}</span>}
                </button>
                <button className="action-btn" onClick={() => {
                  if (navigator.share) navigator.share({ title: p.title, url: window.location.href });
                }}>
                  <FiShare2 size={16} />
                </button>
              </div>
            </article>
          ))}
        </div>
      )}

      {posts.length >= 20 && (
        <div className="pagination">
          <button disabled={page <= 1} onClick={() => setPage(p => p - 1)}>Previous</button>
          <span>Page {page}</span>
          <button onClick={() => setPage(p => p + 1)}>Next</button>
        </div>
      )}
    </div>
  );
}
