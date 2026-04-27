import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { describe, it, expect, vi } from 'vitest';
import App from '../App';
import { AuthProvider } from '../context/AuthContext';

// Mock fetch to prevent API calls during tests
globalThis.fetch = vi.fn(() =>
  Promise.resolve({
    ok: false,
    json: () => Promise.resolve({}),
  })
);

function renderApp(route = '/') {
  return render(
    <MemoryRouter initialEntries={[route]}>
      <AuthProvider>
        <App />
      </AuthProvider>
    </MemoryRouter>
  );
}

describe('App', () => {
  it('renders the navbar with SkillConnect logo', () => {
    renderApp();
    const logos = screen.getAllByText('SkillConnect');
    expect(logos.length).toBeGreaterThanOrEqual(1);
    expect(logos[0]).toBeInTheDocument();
  });

  it('renders the home page by default', () => {
    renderApp();
    expect(screen.getByText('Find Trusted Professionals Near You')).toBeInTheDocument();
  });

  it('renders navigation links', () => {
    renderApp();
    const homeLinks = screen.getAllByText('Home');
    expect(homeLinks.length).toBeGreaterThanOrEqual(1);
    expect(screen.getAllByText('Categories').length).toBeGreaterThanOrEqual(1);
    expect(screen.getAllByText('Search').length).toBeGreaterThanOrEqual(1);
  });

  it('renders 404 page for unknown routes', () => {
    renderApp('/unknown-route');
    expect(screen.getByText('404')).toBeInTheDocument();
    expect(screen.getByText('Page Not Found')).toBeInTheDocument();
  });
});
