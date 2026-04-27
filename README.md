# SkillConnect

A trusted digital platform that connects customers with verified skilled professionals across all service categories. Find, compare, and contact service providers with verified profiles, skill portfolios, transparent ratings, and location-based search.

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌────────────┐
│   Frontend   │────▶│   Backend    │────▶│ PostgreSQL │
│  React/Vite  │     │ Express API  │     │  Database   │
└─────────────┘     └──────────────┘     └────────────┘
```

- **Frontend**: React 19 with Vite, React Router, pure CSS
- **Backend**: Node.js/Express REST API with JWT authentication
- **Database**: PostgreSQL with full relational schema

## Features

- **User Registration** — Customer and professional signup with validation
- **Professional Profiles** — Bio, experience, pricing, portfolio, certifications
- **Category System** — Hierarchical categories (Home, Event, Personal, Technical, Creative services)
- **Search & Discovery** — Filter by location, rating, price, availability with proximity sorting
- **Portfolio Showcase** — Photos, videos, certificates for professionals
- **Reviews & Ratings** — 1-5 star ratings, verified through contact interactions
- **Reputation Score** — Weighted trust score (ratings, jobs, response time, complaints)
- **Contact System** — Call, message, or request quotes from professionals
- **Complaint System** — Report fraud, harassment, fake profiles with auto-moderation

## Quick Start

### Prerequisites

- Node.js 18+
- PostgreSQL 14+

### Database Setup

```bash
# Create the database
createdb skillconnect

# Run schema
psql skillconnect < database/schema.sql

# Seed categories
psql skillconnect < database/seed.sql
```

### Backend

```bash
cd backend

# Copy and configure environment variables
cp .env.example .env
# Edit .env with your database credentials and JWT secret

# Install dependencies
npm install

# Start development server
npm run dev

# Run tests
npm test
```

The API runs on `http://localhost:5000`.

### Frontend

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Run tests
npm test
```

The app runs on `http://localhost:5173` and proxies API requests to the backend.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login and get JWT |
| GET | `/api/categories` | List all categories |
| GET | `/api/categories/:id` | Get category with subcategories |
| GET | `/api/search` | Search professionals (with filters) |
| POST | `/api/professionals` | Create professional profile |
| GET | `/api/professionals/:id` | Get professional profile |
| PUT | `/api/professionals/:id` | Update professional profile |
| POST | `/api/portfolio` | Add portfolio item |
| GET | `/api/portfolio/:professionalId` | List portfolio items |
| DELETE | `/api/portfolio/:id` | Delete portfolio item |
| POST | `/api/reviews` | Create review (requires prior contact) |
| GET | `/api/reviews/:professionalId` | Get reviews for professional |
| POST | `/api/contacts` | Create contact request |
| GET | `/api/contacts` | List own contacts |
| PUT | `/api/contacts/:id/status` | Update contact status |
| POST | `/api/complaints` | File a complaint |
| GET | `/api/complaints` | List complaints (admin) |

### Search Query Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `q` | string | Text search (name, headline) |
| `category_id` | integer | Filter by category |
| `min_rating` | number | Minimum average rating |
| `max_price` | number | Maximum estimated price |
| `latitude` | number | User latitude for proximity |
| `longitude` | number | User longitude for proximity |
| `radius_km` | number | Search radius in km |
| `availability` | string | Filter by availability status |
| `sort_by` | string | Sort: `reputation`, `distance`, `experience` |
| `page` | integer | Page number (default: 1) |
| `limit` | integer | Results per page (default: 10) |

## Project Structure

```
├── backend/
│   ├── src/
│   │   ├── app.js                # Express app setup
│   │   ├── server.js             # Server entry point
│   │   ├── config/database.js    # PostgreSQL connection
│   │   ├── middleware/           # Auth, validation, error handling
│   │   ├── controllers/         # Business logic
│   │   ├── routes/              # API route definitions
│   │   └── utils/               # Reputation score calculator
│   └── tests/                   # Jest + Supertest tests
├── frontend/
│   ├── src/
│   │   ├── api/client.js        # API client
│   │   ├── context/AuthContext.jsx
│   │   ├── components/          # Reusable UI components
│   │   ├── pages/               # Page components
│   │   └── tests/               # Vitest + Testing Library
│   └── index.html
└── database/
    ├── schema.sql               # Full PostgreSQL schema
    └── seed.sql                 # Category seed data
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React 19, Vite 8, React Router 7 |
| Backend | Node.js, Express 5 |
| Database | PostgreSQL |
| Auth | JWT (jsonwebtoken, bcryptjs) |
| Testing | Jest, Supertest, Vitest, Testing Library |

## License

ISC