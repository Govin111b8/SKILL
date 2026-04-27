function LoadingSpinner() {
  return (
    <div className="loading-spinner-container" style={{
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      padding: '3rem',
    }}>
      <div className="loading-spinner" style={{
        width: '40px',
        height: '40px',
        border: '4px solid var(--gray-200)',
        borderTopColor: 'var(--primary)',
        borderRadius: '50%',
        animation: 'spin 0.8s linear infinite',
      }} />
      <style>{`
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
}

export default LoadingSpinner;
