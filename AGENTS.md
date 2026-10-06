# Lauro Project Backend Guidelines

## Architecture

- This is a Rails API-only backend. Do not add Rails-rendered HTML admin screens or CMS views.
- The React frontend is a separate application and consumes JSON APIs only.
- Keep the backend as a modular monolith: domain models, thin controllers, policies, blueprints, query objects, and focused services.
- Use `InvestmentCard` as the flexible central listing/card concept. Avoid naming new domain code `Opportunity` unless it is only presentation copy.
- Use `NewsletterEdition` for editorial newsletter issues and keep it independent from listings.
- Use `Lead` for public contact requests and the internal qualification workflow.
- Use `Favorite` for authenticated investor bookmarks; keep it separate from editorial card flags such as `featured`.

## API Conventions

- Version public API routes under `/api/v1`.
- Version admin API routes under `/api/v1/admin`.
- Return JSON in this envelope:
  `{ "data": ..., "meta": ..., "errors": [] }`.
- Use Blueprinter for response serialization.
- Use request specs for frontend-facing API contracts.
- Keep controllers responsible for HTTP concerns only: auth, params, orchestration, and render.

## Authorization And Auth

- Use Devise with JWT for authentication.
- Use Pundit for authorization, especially under `/api/v1/admin`.
- Public lead creation is intentionally unauthenticated; lead administration always requires JWT and Pundit.
- Supported roles are `admin`, `editor`, and `viewer`.
- Keep role permissions centralized on `User`.
- The frontend should use `GET /api/v1/me` as the source of truth for user role and permissions.

## Storage

- Active Storage is the only supported file attachment layer.
- Use S3-compatible storage in production.
- Keep image/document metadata in application tables or structured `jsonb`, not in ad hoc file paths.
- Bulk media import must be job-backed and track item failures instead of failing silently.
- Multi-file uploads must go through Active Storage and validate MIME type and size before attaching.
- Large imports use `MediaImportBatch` and `MediaImportItem`, with background processing and per-file failure tracking for cards and newsletter editions.

## Code Style

- Prefer Rails conventions before custom abstractions.
- Use model validations and database constraints for important invariants.
- Use query objects only when filters become too large for readable scopes.
- Use service objects only for multi-step workflows with transactions or side effects.
- Avoid complex callbacks, global mutable state, and STI for residential/commercial/business differences.
- Keep `metadata` structured with `store_model` when it grows beyond simple key/value usage.

## Testing

- This project is spec-supported, not strict TDD.
- Prioritize request specs for API contracts, model specs for real domain rules, and policy specs for non-trivial access rules.
- Do not add low-value specs for trivial getters or framework behavior.
- Keep OpenAPI documentation aligned with request specs through Rswag.
- Collection endpoints must use Pagy and expose stable pagination metadata in `meta`.
- Newsletter dispatch must be asynchronous and tracked per subscriber; never send to unsubscribed records.
