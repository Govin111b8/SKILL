/**
 * Loading skeleton component for content loading states.
 * Provides animated placeholder UI while data is being fetched.
 */

function Skeleton({ width = '100%', height = '1rem', borderRadius = '4px', count = 1, className = '' }) {
  const style = {
    width,
    height,
    borderRadius,
    backgroundColor: '#e2e8f0',
    animation: 'skeleton-pulse 1.5s ease-in-out infinite',
    marginBottom: count > 1 ? '0.5rem' : 0,
  };

  return (
    <>
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className={`skeleton ${className}`} style={style} aria-hidden="true" />
      ))}
      <style>{`
        @keyframes skeleton-pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.4; }
        }
      `}</style>
    </>
  );
}

function CardSkeleton() {
  return (
    <div style={{ padding: '1rem', border: '1px solid #e2e8f0', borderRadius: '12px', marginBottom: '1rem' }}>
      <Skeleton width="60%" height="1.25rem" />
      <div style={{ marginTop: '0.75rem' }}>
        <Skeleton count={3} />
      </div>
      <div style={{ display: 'flex', gap: '0.5rem', marginTop: '1rem' }}>
        <Skeleton width="80px" height="2rem" borderRadius="8px" />
        <Skeleton width="80px" height="2rem" borderRadius="8px" />
      </div>
    </div>
  );
}

function ProfileSkeleton() {
  return (
    <div style={{ display: 'flex', gap: '1rem', alignItems: 'flex-start', padding: '1rem' }}>
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

export { Skeleton, CardSkeleton, ProfileSkeleton };
export default Skeleton;
