# Local Backend Testing Guide for Rupaya

This guide will help you set up, migrate, and test the backend locally in a professional and repeatable way.

---

## 1. Prerequisites
- **Node.js** (v18+ recommended)
- **npm** (v9+ recommended)
- **PostgreSQL** (v14+ recommended)
- **Knex CLI** (installed locally via npm)
- **Docker** (optional, for running Postgres)

---

## 2. Database Setup

### Option A: Using Docker (Recommended)
Run this command to start a local Postgres instance:

```
docker run --name rupaya-postgres \
  -e POSTGRES_USER=rupaya \
  -e POSTGRES_PASSWORD=secure_password_here \
  -e POSTGRES_DB=rupaya_dev \
  -p 5432:5432 -d postgres:15
```

### Option B: Using Local Postgres
1. Start Postgres (e.g., `brew services start postgresql` on macOS).
2. Create the user and database:
   ```
   psql -U postgres -c "CREATE USER rupaya WITH PASSWORD 'secure_password_here';"
   psql -U postgres -c "CREATE DATABASE rupaya_dev OWNER rupaya;"
   ```

---

## 3. Environment Variables

Copy `.env.example` to `.env` and ensure these values match your setup:

```
DB_HOST=localhost
DB_PORT=5432
DB_USER=rupaya
DB_PASSWORD=secure_password_here
DB_NAME=rupaya_dev
```

---

## 4. Install Dependencies

```
cd backend
npm install
```

---

## 5. Run Database Migrations

```
npx knex migrate:latest
```

To reset and re-run all migrations:
```
npx knex migrate:rollback --all && npx knex migrate:latest
```

---

## 6. Verify Database Tables

```
psql -h localhost -U rupaya -d rupaya_dev -c '\dt'
```

You should see tables like `users`, `accounts`, `categories`, etc.

---

## 7. Run Backend Tests

```
npm test
```

---

## 8. Troubleshooting
- Ensure Postgres is running and accessible.
- If you see `relation "users" does not exist`, re-run migrations.
- For port conflicts, stop other Postgres containers/services.
- Use `docker logs rupaya-postgres` to debug Docker Postgres issues.

---

## 9. Clean Up
To stop and remove the Docker container:
```
docker stop rupaya-postgres && docker rm rupaya-postgres
```

---

## 10. Additional Notes
- Use a tool like [TablePlus](https://tableplus.com/) or `psql` CLI to inspect your database.
- For production, use a different database, user, and strong passwords.

---

_This guide ensures a professional, repeatable local backend test setup for all developers._
