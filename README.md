# BillFlow CRM

A CRM and billing application built with Next.js, Go, PostgreSQL, and Docker.

## Structure

- `frontend/`: Next.js App Router, TypeScript, Tailwind CSS
- `backend/`: Go REST API with Fiber v2
- `backend/migrations/`: versioned PostgreSQL migrations
- `docker-compose.yml`: frontend, backend, PostgreSQL, and Redis

## Run locally using Docker

1. Copy `.env.example` to `.env` and change `POSTGRES_PASSWORD` and the password in `DATABASE_URL` to the **same** value.
2. Run `docker compose up --build` for the full stack, or `docker compose up --build backend` for the API and its dependencies.
3. Check http://localhost:8080/health for liveness and http://localhost:8080/ready for PostgreSQL and Redis connectivity. The frontend is at http://localhost:3000.

PostgreSQL and Redis are only accessible on the Compose network. If you change `API_PORT`, use that port for the health checks from your host and update `NEXT_PUBLIC_API_URL` to match.

Docker Compose is intended for local development. Do not deploy the sample database credentials.

## Run without Docker

- Frontend: `cd frontend && npm install && npm run dev`
- Backend: With Go 1.26+ and reachable PostgreSQL and Redis instances, set `DATABASE_URL` and `REDIS_URL` in your shell. Then run `cd backend` and `go run ./cmd/api`. The Compose hostnames in `.env.example` are for containers. Use addresses reachable from your host when running Go directly.

`GET /ready` returns HTTP 503 when either dependency is unavailable.

## Database migrations

Run the following from the repository root. The dedicated Compose service uses
[golang-migrate](https://github.com/golang-migrate/migrate/tree/v4.19.1) and the
container-facing `DATABASE_URL` from `.env`. The service runs only when
explicitly targeted or when starting Compose with the `tools` profile enabled.
Keep credentials in `.env` and URL-encode reserved characters in the database URL.

| Operation | Command |
| --- | --- |
| Apply pending migrations | `docker compose run --rm migrate up` |
| Show the recorded version and dirty state | `docker compose run --rm migrate version` |
| Roll back one migration | `docker compose run --rm migrate down 1` |
| Generate the next migration pair in PowerShell | `docker run --rm --mount "type=bind,source=$($PWD.Path)/backend/migrations,target=/migrations" migrate/migrate:v4.19.1 create -ext sql -dir /migrations -seq add_example` |

Confirm which database `DATABASE_URL` targets before applying or rolling back.
On a fresh database, `version` reports no migration until the first successful
`up`. Rolling back version 1 drops all eight BillFlow tables and their data.
Use a disposable database to test that rollback.

### Initial schema and assumptions

The attached requirements are the schema reference. A separate PRD and ERD
were unavailable. All eight tables use BIGINT identity keys. Timestamp columns
use TIMESTAMPTZ, and update triggers maintain `updated_at` where present.

| Table | Relationships and indexes |
| --- | --- |
| `users` | Global application accounts. A unique index on `lower(email)` prevents case-only duplicates. |
| `companies` | Parent of customers. Company contact fields and logo are optional. |
| `customers` | Each belongs to one company. Company-scoped indexes support case-insensitive prefix searches on name and email using `lower(column) LIKE 'prefix%'`. |
| `products` | Shared catalog of products and services. Existing line items reference their catalog entries. |
| `transactions` | The composite foreign key on `(company_id, customer_id)` rejects cross-company references and prevents moving a billed customer to another company. Invoice numbers are globally unique. An index on company and issue time supports reporting. |
| `transaction_items` | Each belongs to one transaction and references one product. Both foreign key columns are indexed. |
| `payments` | A transaction can have multiple payment attempts. The transaction foreign key is indexed and each Midtrans order ID is globally unique. |
| `invoice_logs` | A transaction can have multiple audit events, indexed by transaction, time, and ID for stable chronological reads. |

- User roles are `admin` and `staff`. User membership and company-specific
  authorization are outside this schema. Future authentication must write a
  secure password hash to `password_hash`; the database checks that it is nonblank.
- Roles, product types, invoice statuses, and internal payment statuses use
  text with CHECK constraints so changes can be made through versioned SQL.
  The migration lists the initial values. Provider status strings are kept
  separately so additional Midtrans statuses can be retained. An issued invoice
  requires an issue timestamp, and paid or refunded invoices require a payment
  timestamp. The optional due date is a calendar date.
- Amounts are nonnegative whole rupiah stored as BIGINT. Quantities are positive
  integers. At transaction creation the write path must copy the catalog price
  into each line item and set the invoice total from its lines within the same
  database transaction. PostgreSQL generates each subtotal from the stored
  quantity and price. Issued invoice edits and state transitions must be
  controlled by the future write path.
- Foreign keys restrict parent deletion. The future write path should append
  invoice audit events in the same database transaction as the audited changes
  and restrict direct edits and deletion of financial rows and logs.
- Each payment row represents the current state of one Midtrans order.
  `raw_response` is an optional JSONB projection limited to a three-digit
  `status_code` string and `currency` set to `IDR`. Future webhook ingestion must
  verify the signature and persist only selected fields. Discard complete
  webhook bodies, card details including masked numbers, and card tokens.
  The optional `signature_key` holds the webhook digest. Keep the signing secret
  outside the database.

## GitHub

Initialize or publish this repository with `git remote add origin <your-repo-url>` and `git push -u origin main`. Never commit `.env` files.

