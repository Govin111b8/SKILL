# Contributing to SkillConnect

Thank you for contributing to SkillConnect! This guide will help you get set up and understand our development workflow.

## 🚀 Quick Start

### Prerequisites
- **Node.js** ≥ 20.x
- **PostgreSQL** ≥ 15
- **Redis** (optional, falls back to in-memory)
- **Flutter** ≥ 3.8 (for mobile development)

### Backend Setup

```bash
cd backend
npm install

# Copy environment file
cp .env.example .env  # Create from template below

# Run database migrations
cd ../database
psql -U postgres -d skillconnect -f migrations/001_kyc.sql
# ... (run all migrations in order)

# Start development server
cd ../backend
npm run dev
```

### Frontend Setup

```bash
cd frontend
npm install
npm run dev  # Starts on http://localhost:3000
```

### Mobile Setup

```bash
cd mobile/skillconnect
flutter pub get
flutter run  # For connected device/emulator
```

## 🏗️ Architecture

```
├── backend/          # Express 5 API server
│   ├── src/
│   │   ├── app.js              # Express app setup & middleware
│   │   ├── config/             # Config, database, Redis, logging
│   │   ├── controllers/        # Route handlers (50+ controllers)
│   │   ├── middleware/         # Auth, validation, rate limiting, CSRF
│   │   ├── routes/             # Route definitions (50+ route files)
│   │   ├── services/           # External services (email, SMS, storage)
│   │   ├── utils/              # Shared utilities
│   │   └── workers/            # Cron jobs & background tasks
│   └── tests/                  # Jest test suites
├── frontend/         # React 19 + Vite 8 SPA
│   └── src/
│       ├── components/         # Reusable UI components
│       ├── pages/              # Route pages
│       ├── context/            # React context providers
│       ├── api/                # API client
│       └── utils/              # Frontend utilities
├── mobile/           # Flutter mobile app
│   └── skillconnect/
│       └── lib/
│           ├── screens/        # App screens (70+)
│           ├── widgets/        # Custom widgets
│           ├── services/       # API & data services
│           ├── models/         # Data models
│           └── theme/          # Design tokens & theming
├── database/         # SQL migrations & seeds
├── k8s/              # Kubernetes manifests
├── monitoring/       # Prometheus & Grafana configs
└── nginx/            # Reverse proxy config
```

## 🔧 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Environment (development/staging/production) | development |
| `PORT` | Server port | 5000 |
| `DB_HOST` | PostgreSQL host | localhost |
| `DB_PORT` | PostgreSQL port | 5432 |
| `DB_NAME` | Database name | skillconnect |
| `DB_USER` | Database user | postgres |
| `DB_PASSWORD` | Database password | password |
| `JWT_SECRET` | JWT signing secret (≥32 chars in prod) | dev-secret-change-me |
| `JWT_EXPIRES_IN` | Access token TTL | 15m |
| `JWT_REFRESH_EXPIRES_IN` | Refresh token TTL | 7d |
| `REDIS_URL` | Redis connection URL | (disabled) |
| `RAZORPAY_KEY_ID` | Razorpay API key | |
| `RAZORPAY_KEY_SECRET` | Razorpay secret | |
| `SENDGRID_API_KEY` | SendGrid email API key | |
| `STORAGE_PROVIDER` | File storage (local/s3) | local |
| `S3_BUCKET` | AWS S3 bucket name | |

## 📝 Development Workflow

### Branch Naming
- `feature/description` — New features
- `fix/description` — Bug fixes
- `security/description` — Security improvements
- `docs/description` — Documentation changes

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):
```
feat(backend): add CSRF protection middleware
fix(frontend): resolve missing alt attributes on images
docs: add CONTRIBUTING guide
security: strengthen XSS sanitization with sanitize-html
```

### Running Tests

```bash
# Backend tests (Jest)
cd backend
npx jest --forceExit --detectOpenHandles

# Frontend build check
cd frontend
npm run build

# Syntax check (quick)
cd backend
node -c src/app.js
```

### Code Style
- **Backend:** Standard Node.js style, no semicolon-free zones
- **Frontend:** React functional components, hooks preferred
- **Mobile:** Flutter/Dart standard style (enforced by `flutter analyze`)

## 🔒 Security Guidelines

- **Never** commit secrets or API keys
- **Always** validate and sanitize user input (use express-validator on routes)
- **Always** use parameterized queries (no string interpolation in SQL)
- **Always** add authentication middleware on non-public endpoints
- File uploads must validate MIME types AND magic bytes
- Use `sanitize-html` for backend sanitization, `DOMPurify` for frontend

## 📚 API Documentation

In development, Swagger UI is available at:
```
http://localhost:5000/api/docs
```

JSON spec: `http://localhost:5000/api/docs/spec.json`

## 🧪 Testing Standards

- Backend coverage threshold: 80%+
- All new endpoints must have corresponding tests
- Critical flows (auth, booking, payment) require integration tests
- Security-sensitive code requires explicit security tests

## 📦 Adding Dependencies

- Only add new dependencies when absolutely necessary
- Prefer well-maintained packages with minimal transitive deps
- Run `npm audit` after adding any dependency
- Document why the dependency is needed in your PR description

## 🚢 Deployment

Deployments are automated via CI/CD:
1. Push to `main` → deploys to staging
2. Tag `v*` → deploys to production
3. Kubernetes manifests in `k8s/` directory
4. Docker images built via `build.sh`

## 🆘 Getting Help

- Check existing issues for similar problems
- Review architecture docs: `ARCHITECTURE.md`
- Runbooks for operations: `RUNBOOKS.md`
- Security concerns: `THREAT_MODEL.md`
