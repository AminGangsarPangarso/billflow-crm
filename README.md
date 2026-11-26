# BillFlow CRM

A CRM and billing application built with Next.js, Go, PostgreSQL, and Docker.

## Structure

- `frontend/`: Next.js App Router, TypeScript, Tailwind CSS
- `backend/`: Go REST API with Fiber v2
- `backend/migrations/`: future SQL migrations
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

`GET /ready` returns HTTP 503 when either dependency is unavailable. CRM APIs and database migrations will be added after review of the PRD.

## GitHub

Initialize or publish this repository with `git remote add origin <your-repo-url>` and `git push -u origin main`. Never commit `.env` files.

