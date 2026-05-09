/**
 * Loading skeleton component for content loading states.
 * Provides animated placeholder UI while data is being fetched.
 * Uses shimmer animation for premium feel.
 */

function Skeleton({ width = '100%', height = '1rem', borderRadius = '8px', count = 1, className = '' }) {
  const style = {
    width,
    height,
    borderRadius,
    background: 'linear-gradient(90deg, var(--gray-200, #e2e8f0) 25%, var(--gray-100, #f1f5f9) 50%, var(--gray-200, #e2e8f0) 75%)',
    backgroundSize: '200% 100%',
    animation: 'shimmer 1.5s infinite',
    marginBottom: count > 1 ? '0.5rem' : 0,
  };

  return (
    <>
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className={`skeleton ${className}`} style={style} aria-hidden="true" />
      ))}
    </>
  );
}

function CardSkeleton({ count = 1 }) {
  return (
    <>
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="skeleton-card" aria-hidden="true">
          <Skeleton width="60%" height="1.25rem" />
          <div style={{ marginTop: '0.75rem' }}>
            <Skeleton count={2} height="0.85rem" />
          </div>
          <div style={{ display: 'flex', gap: '0.5rem', marginTop: '1rem' }}>
            <Skeleton width="80px" height="2rem" borderRadius="8px" />
            <Skeleton width="80px" height="2rem" borderRadius="8px" />
          </div>
        </div>
      ))}
    </>
  );
}

function ProfileSkeleton() {
  return (
    <div className="skeleton-profile" aria-hidden="true">
      <Skeleton width="64px" height="64px" borderRadius="50%" />
      <div style={{ flex: 1 }}>
        <Skeleton width="40%" height="1.25rem" />
        <div style={{ marginTop: '0.5rem' }}>
          <Skeleton width="80%" />
          <Skeleton width="60%" />
        </div>
      </div>
    </div>
  );
}

function PageSkeleton({ variant = 'default' }) {
  if (variant === 'detail') {
    return (
      <div className="skeleton-page" aria-hidden="true" aria-label="Loading content">
        <Skeleton width="100%" height="200px" borderRadius="16px" />
        <div style={{ marginTop: '1.5rem' }}>
          <Skeleton width="60%" height="1.5rem" />
          <div style={{ marginTop: '0.75rem' }}>
            <Skeleton count={4} />
          </div>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginTop: '1.5rem' }}>
          <Skeleton height="80px" borderRadius="12px" />
          <Skeleton height="80px" borderRadius="12px" />
        </div>
      </div>
    );
  }

  if (variant === 'list') {
    return (
      <div className="skeleton-page" aria-hidden="true" aria-label="Loading content">
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1.5rem' }}>
          <Skeleton width="200px" height="1.5rem" />
          <Skeleton width="100px" height="2rem" borderRadius="20px" />
        </div>
        <CardSkeleton count={4} />
      </div>
    );
  }

  if (variant === 'stats') {
    return (
      <div className="skeleton-page" aria-hidden="true" aria-label="Loading content">
        <Skeleton width="250px" height="1.75rem" />
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))', gap: '0.75rem', marginTop: '1rem' }}>
          <Skeleton height="80px" borderRadius="12px" />
          <Skeleton height="80px" borderRadius="12px" />
          <Skeleton height="80px" borderRadius="12px" />
        </div>
        <div style={{ marginTop: '1.5rem' }}>
          <CardSkeleton count={3} />
        </div>
      </div>
    );
  }

  // Default
  return (
    <div className="skeleton-page" aria-hidden="true" aria-label="Loading content">
      <Skeleton width="250px" height="1.75rem" />
      <div style={{ marginTop: '0.5rem' }}>
        <Skeleton width="350px" height="1rem" />
      </div>
      <div style={{ marginTop: '1.5rem' }}>
        <CardSkeleton count={3} />
      </div>
    </div>
  );
}

function StatsSkeleton({ count = 3 }) {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: `repeat(auto-fit, minmax(140px, 1fr))`, gap: '0.75rem' }} aria-hidden="true">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="skeleton-stat">
          <Skeleton width="32px" height="32px" borderRadius="8px" />
          <div style={{ flex: 1 }}>
            <Skeleton width="60%" height="1.25rem" />
            <Skeleton width="80%" height="0.7rem" />
          </div>
        </div>
      ))}
    </div>
  );
}

export { Skeleton, CardSkeleton, ProfileSkeleton, PageSkeleton, StatsSkeleton };
export default Skeleton;
