# BillFlow CRM

A CRM and billing application built with Next.js, Go, PostgreSQL, and Docker.

## Structure

- `frontend/`: Next.js App Router, TypeScript, Tailwind CSS
- `backend/`: Go REST API (standard library for the initial health endpoint)
- `backend/migrations/`: future SQL migrations
- `docker-compose.yml`: frontend, backend, and PostgreSQL

## Run locally using Docker

1. Copy `.env.example` to `.env` and change `POSTGRES_PASSWORD` and the password in `DATABASE_URL` to the **same** value.
2. Run `docker compose up --build`.
3. Visit http://localhost:3000 and http://localhost:8080/health.

Docker Compose is intended for local development. Do not deploy the sample database credentials.

## Run without Docker

- Frontend: `cd frontend && npm install && npm run dev`
- Backend: `cd backend && go run ./cmd/api` (requires Go 1.23+)

The first API endpoint is `GET /health`. CRM APIs and database migrations will be added after review of the PRD.

## GitHub

Initialize or publish this repository with `git remote add origin <your-repo-url>` and `git push -u origin main`. Never commit `.env` files.

