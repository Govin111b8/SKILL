function LoadingSpinner({ size = 'md', text = '' }) {
  const sizes = { sm: 28, md: 44, lg: 64 };
  const dim = sizes[size] || sizes.md;

  return (
    <div className="loading-spinner-container" style={{
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'center',
      alignItems: 'center',
      padding: '3rem',
      gap: '1rem',
    }}>
      <div className="loading-spinner-ring" style={{
        position: 'relative',
        width: `${dim}px`,
        height: `${dim}px`,
      }}>
        <div style={{
          position: 'absolute',
          inset: 0,
          borderRadius: '50%',
          border: `${dim > 40 ? 4 : 3}px solid var(--gray-100)`,
        }} />
        <div style={{
          position: 'absolute',
          inset: 0,
          borderRadius: '50%',
          border: `${dim > 40 ? 4 : 3}px solid transparent`,
          borderTopColor: 'var(--primary)',
          borderRightColor: 'var(--primary-light)',
          animation: 'spin 0.8s cubic-bezier(0.4, 0, 0.2, 1) infinite',
        }} />
        <div style={{
          position: 'absolute',
          inset: `${dim * 0.2}px`,
          borderRadius: '50%',
          background: 'var(--primary-50)',
          animation: 'pulse 1.5s ease-in-out infinite',
        }} />
      </div>
      {text && (
        <span style={{
          fontSize: '0.875rem',
          color: 'var(--gray-500)',
          fontWeight: 500,
        }}>{text}</span>
      )}
      <style>{`
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
        @keyframes pulse {
          0%, 100% { opacity: 0.4; transform: scale(0.9); }
          50% { opacity: 0.8; transform: scale(1); }
        }
      `}</style>
    </div>
  );
}

export default LoadingSpinner;
