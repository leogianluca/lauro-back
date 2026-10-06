# Lauro Project API

Rails API-only backend for the Lauro investment platform. The React frontend is intentionally separate.

## Stack

- Ruby 4.0.6
- Rails 8.1
- PostgreSQL 16 via Docker
- Devise + devise-jwt
- Pundit
- Active Storage with local development storage and S3-ready production storage
- RSpec, Rswag, RuboCop, Brakeman

## Setup

```bash
cp .env.example .env
docker compose up -d postgres
bundle install
bin/rails db:create db:migrate db:seed
```

Seeded local admin:

```text
email: admin@example.com
password: password123
```

The development seed also creates a small, idempotent catalog for demonstrations
(cards, report, institutional page, newsletter template, campaign and subscribers).
It runs only when `RAILS_ENV=development`; it never creates demo content in production.

## Development

```bash
bin/rails server
```

From WSL, the API is available at `http://127.0.0.1:3000`. In a second terminal,
start the separate React app from `minimal_typescript_v7` with `npm run dev -- --host
0.0.0.0 --port 8080`; the panel is available at `http://localhost:8080/login`.

If the local database is empty, run the seed explicitly:

```bash
DISABLE_BOOTSNAP=1 bundle exec rails db:seed
```

Health check:

```text
GET /up
GET /api/v1/health
```

Authentication:

```text
POST /api/v1/auth/login
DELETE /api/v1/auth/logout
GET /api/v1/me
```

Public product endpoints:

```text
GET /api/v1/investment_cards
GET /api/v1/investment_cards/:slug
GET /api/v1/newsletter_editions
GET /api/v1/newsletter_editions/:slug
GET /api/v1/market_reports
GET /api/v1/market_reports/:slug
GET /api/v1/content_pages
GET /api/v1/content_pages/:slug
GET /api/v1/site_settings
GET /api/v1/me/favorites
POST|DELETE /api/v1/investment_cards/:investment_card_id/favorite
POST /api/v1/leads
POST /api/v1/deal_submissions
DELETE /api/v1/newsletter_subscribers/:signed_token
```

Admin resources are available under `/api/v1/admin`. Investment cards support editorial
transitions, highlighting and multi-file media through
`POST /api/v1/admin/investment_cards/:id/media` with `cover_image`, `gallery_images[]`
and `documents[]`. Development uses local Active Storage; production is S3-ready.
Large imports use `POST /api/v1/admin/investment_cards/:investment_card_id/media_imports`
or the equivalent newsletter route with `kind` and `files[]`; the response contains a
batch id and processing progress.
Published newsletter editions can be dispatched with
`POST /api/v1/admin/newsletter_editions/:id/dispatch`; delivery is queued and tracked per
subscriber.
The dashboard aggregate is available at `GET /api/v1/admin/dashboard`.

## Production checklist

- Set `DATABASE_URL`, `RAILS_MASTER_KEY`, `DEVISE_JWT_SECRET_KEY` and explicit `CORS_ORIGINS`.
- Set `ACTIVE_STORAGE_SERVICE=amazon` and the AWS bucket; production uses a least-privilege IAM role, not static AWS keys.
- Set `MAILER_DELIVERY_METHOD=smtp` and SMTP credentials for the verified sender domain.
- Configure SPF, DKIM and DMARC before enabling campaign delivery.
- Run the checks below during deploy and keep web, worker and scheduler processes observable.
- The seeded admin credentials are for local development only and must be changed before staging.

Production preflight:

```bash
RAILS_ENV=production bin/rails production:check
```

API docs:

```text
/api-docs
```

## Checks

```bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman -q
bin/rails zeitwerk:check
```
