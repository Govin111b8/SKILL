import { Component, useState } from 'react';
import './ErrorBoundary.css';

/**
 * Error Boundary — catches JavaScript errors in child component tree
 * and displays a premium fallback UI instead of crashing the whole app.
 */
class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    this.setState({ errorInfo });
    console.error('[ErrorBoundary]', error, errorInfo);
  }

  handleReset = () => {
    this.setState({ hasError: false, error: null, errorInfo: null });
  };

  handleGoHome = () => {
    window.location.href = '/';
  };

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback;
      }

      return (
        <ErrorFallback
          error={this.state.error}
          errorInfo={this.state.errorInfo}
          onReset={this.handleReset}
          onGoHome={this.handleGoHome}
        />
      );
    }

    return this.props.children;
  }
}

function ErrorFallback({ error, errorInfo, onReset, onGoHome }) {
  const [showDetails, setShowDetails] = useState(false);

  return (
    <div className="error-boundary" role="alert">
      {/* Animated background */}
      <div className="error-boundary__bg">
        <div className="error-boundary__blob error-boundary__blob--1" />
        <div className="error-boundary__blob error-boundary__blob--2" />
      </div>

      <div className="error-boundary__content">
        {/* Animated illustration */}
        <div className="error-boundary__icon">
          <svg width="120" height="120" viewBox="0 0 120 120" fill="none" aria-hidden="true">
            <circle cx="60" cy="60" r="56" stroke="var(--primary-100)" strokeWidth="2" fill="var(--primary-50)" className="error-boundary__circle" />
            <circle cx="60" cy="60" r="40" stroke="var(--primary)" strokeWidth="2" fill="white" className="error-boundary__circle--inner" />
            <text x="60" y="68" textAnchor="middle" fontSize="40" className="error-boundary__emoji">😵</text>
          </svg>
          <div className="error-boundary__pulse" />
        </div>

        <h1 className="error-boundary__title">Oops, something went wrong!</h1>
        <p className="error-boundary__message">
          Don't worry — it's not your fault. An unexpected error occurred.
          <br />
          Let's try to get you back on track.
        </p>

        <div className="error-boundary__actions">
          <button className="error-boundary__btn error-boundary__btn--primary" onClick={onReset}>
            🔄 Try Again
          </button>
          <button className="error-boundary__btn error-boundary__btn--secondary" onClick={onGoHome}>
            🏠 Go Home
          </button>
        </div>

        <button
          className="error-boundary__details-toggle"
          onClick={() => setShowDetails(!showDetails)}
          aria-expanded={showDetails}
        >
          {showDetails ? '▲ Hide' : '▼ Show'} Error Details
        </button>

        {showDetails && (
          <div className="error-boundary__details">
            <p className="error-boundary__error-name">{error?.toString()}</p>
            {errorInfo?.componentStack && (
              <pre className="error-boundary__stack">{errorInfo.componentStack}</pre>
            )}
          </div>
        )}

        <p className="error-boundary__help">
          If this keeps happening, try refreshing the page or{' '}
          <a href="mailto:support@skillconnect.in">contact support</a>.
        </p>
      </div>
    </div>
  );
}

export default ErrorBoundary;
