import { Link } from 'react-router-dom';

function NotFound() {
  return (
    <div style={{
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      minHeight: 'calc(100vh - 300px)',
      padding: '2rem',
      textAlign: 'center',
    }}>
      <h1 style={{ fontSize: '5rem', color: 'var(--primary)', marginBottom: '0.5rem' }}>404</h1>
      <h2 style={{ marginBottom: '1rem', color: 'var(--gray-700)' }}>Page Not Found</h2>
      <p style={{ color: 'var(--gray-500)', marginBottom: '2rem', maxWidth: '400px' }}>
        The page you&apos;re looking for doesn&apos;t exist or has been moved.
      </p>
      <Link to="/" className="btn btn-primary">
        Go Home
      </Link>
    </div>
  );
}

export default NotFound;
