import { Component, Suspense, useState, useEffect } from 'react';
import LoadingSpinner from './LoadingSpinner';

/**
 * Error boundary specifically for lazy-loaded route chunks.
 * Handles chunk loading failures with automatic retry and provides
 * a user-friendly fallback with timeout detection.
 */
class RouteErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null, isChunkError: false };
  }

  static getDerivedStateFromError(error) {
    // Detect chunk load errors (dynamic import failures)
    const isChunkError =
      error?.name === 'ChunkLoadError' ||
      error?.message?.includes('Loading chunk') ||
      error?.message?.includes('Failed to fetch dynamically imported module') ||
      error?.message?.includes('Importing a module script failed');

    return { hasError: true, error, isChunkError };
  }

  componentDidCatch(error, errorInfo) {
    console.error('[RouteErrorBoundary]', error, errorInfo);
  }

  handleRetry = () => {
    if (this.state.isChunkError) {
      // For chunk errors, reload the page to get fresh assets
      window.location.reload();
    } else {
      this.setState({ hasError: false, error: null, isChunkError: false });
    }
  };

  render() {
    if (this.state.hasError) {
      if (this.state.isChunkError) {
        return (
          <div className="route-error" role="alert" style={{ padding: '2rem', textAlign: 'center' }}>
            <h2>Update Available</h2>
            <p>A newer version of the app is available. Please reload to continue.</p>
            <button
              onClick={this.handleRetry}
              style={{
                padding: '0.75rem 1.5rem',
                background: 'var(--primary, #6C63FF)',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                cursor: 'pointer',
                fontSize: '1rem',
              }}
            >
              🔄 Reload Page
            </button>
          </div>
        );
      }

      return (
        <div className="route-error" role="alert" style={{ padding: '2rem', textAlign: 'center' }}>
          <h2>Something went wrong</h2>
          <p>This page encountered an error. Please try again.</p>
          <button
            onClick={this.handleRetry}
            style={{
              padding: '0.75rem 1.5rem',
              background: 'var(--primary, #6C63FF)',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              cursor: 'pointer',
              fontSize: '1rem',
            }}
          >
            🔄 Try Again
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}

/**
 * Loading fallback with timeout detection.
 * Shows a spinner initially, then a "taking longer than expected" message
 * after 10 seconds with a reload option.
 */
function LoadingFallback() {
  const [isTimedOut, setIsTimedOut] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setIsTimedOut(true), 10000);
    return () => clearTimeout(timer);
  }, []);

  if (isTimedOut) {
    return (
      <div className="page-loading" style={{ textAlign: 'center', padding: '2rem' }}>
        <LoadingSpinner />
        <p style={{ marginTop: '1rem', color: 'var(--text-secondary, #666)' }}>
          Taking longer than expected...
        </p>
        <button
          onClick={() => window.location.reload()}
          style={{
            marginTop: '0.5rem',
            padding: '0.5rem 1rem',
            background: 'transparent',
            border: '1px solid var(--primary, #6C63FF)',
            color: 'var(--primary, #6C63FF)',
            borderRadius: '6px',
            cursor: 'pointer',
          }}
        >
          Reload Page
        </button>
      </div>
    );
  }

  return (
    <div className="page-loading">
      <LoadingSpinner />
    </div>
  );
}

/**
 * Wrapper for lazy-loaded route components.
 * Provides: error boundary, suspense fallback with timeout, chunk retry.
 * 
 * Usage:
 *   <Route path="/dashboard" element={<LazyRoute><Dashboard /></LazyRoute>} />
 */
function LazyRoute({ children }) {
  return (
    <RouteErrorBoundary>
      <Suspense fallback={<LoadingFallback />}>
        {children}
      </Suspense>
    </RouteErrorBoundary>
  );
}

export { RouteErrorBoundary, LoadingFallback };
export default LazyRoute;
