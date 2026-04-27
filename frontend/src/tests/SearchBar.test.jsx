import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import { describe, it, expect } from 'vitest';
import SearchBar from '../components/SearchBar';

function renderSearchBar(props = {}) {
  return render(
    <MemoryRouter>
      <SearchBar {...props} />
    </MemoryRouter>
  );
}

describe('SearchBar', () => {
  it('renders search input', () => {
    renderSearchBar();
    expect(screen.getByPlaceholderText('What service are you looking for?')).toBeInTheDocument();
  });

  it('renders location input', () => {
    renderSearchBar();
    expect(screen.getByPlaceholderText('Location')).toBeInTheDocument();
  });

  it('renders search button', () => {
    renderSearchBar();
    expect(screen.getByRole('button', { name: /search/i })).toBeInTheDocument();
  });

  it('accepts user input in search field', async () => {
    const user = userEvent.setup();
    renderSearchBar();
    const input = screen.getByPlaceholderText('What service are you looking for?');
    await user.type(input, 'plumber');
    expect(input).toHaveValue('plumber');
  });

  it('accepts user input in location field', async () => {
    const user = userEvent.setup();
    renderSearchBar();
    const input = screen.getByPlaceholderText('Location');
    await user.type(input, 'New York');
    expect(input).toHaveValue('New York');
  });

  it('renders with initial values', () => {
    renderSearchBar({ initialQuery: 'electrician', initialLocation: 'Boston' });
    expect(screen.getByPlaceholderText('What service are you looking for?')).toHaveValue('electrician');
    expect(screen.getByPlaceholderText('Location')).toHaveValue('Boston');
  });
});
