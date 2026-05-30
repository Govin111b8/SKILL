# k6 smoke scripts

Set environment variables before running:

- `BASE_URL` — API base, default `http://localhost:5000/api`
- `AUTH_TOKEN` — bearer token for authenticated endpoints
- `VUS` / `DURATION` — optional k6 overrides
- `PROFESSIONAL_ID`, `CATEGORY_ID`, `BOOKING_ID`, `PAYMENT_METHOD` — optional endpoint-specific fixtures

Examples:

```bash
k6 run tests/load/search.js
AUTH_TOKEN=your-token PROFESSIONAL_ID=uuid k6 run tests/load/booking.js
AUTH_TOKEN=your-token BOOKING_ID=uuid PAYMENT_METHOD=cod k6 run tests/load/payment.js
```
