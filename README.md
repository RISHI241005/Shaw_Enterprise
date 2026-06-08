# Shaw Enterprise Website

A professional full-stack website for Shaw Enterprise, a wholesale and retail disposable items business.

## Run Locally

```bash
npm run dev
```

Open:

```text
http://localhost:3000
```

Admin login:

```text
http://localhost:3000/login
```

Default local credentials:

```text
Username: admin
Password: change-me-now
```

Change these before real use by setting environment variables from `.env.example`.

Useful local checks:

```bash
curl http://localhost:3000/healthz
npm test
```

## Environment

Copy `.env.example` to `.env` for local use. Production startup now requires:

- `NODE_ENV=production`
- `ADMIN_USER`
- `ADMIN_PASSWORD` changed from the default and at least 12 characters
- `SESSION_SECRET` set to a strong 32+ character value
- `EMAIL_PROVIDER` set to a non-dev provider value

Optional MySQL live-sync is disabled unless both `MYSQL_SYNC_ENABLED=true` and `MYSQL_PASSWORD` are set.

## Features

- Public pages for Home, Products, Feedback, and Contact
- Product catalog with 300 seeded products, generated product visuals, prices, detailed product panel, and product-specific reviews
- Feedback system with email identity verification, replies, likes, hearts, unlike/toggle behavior, sorting, and load more
- Admin panel with product CRUD, feedback moderation, inquiries, and audit logs
- Admin image picker with local file selection and preview
- SQLite database created automatically at `data/shaw-enterprise.db`
- Docker and Render deployment files included

## Notes

OTP verification returns `devOtp` only outside production with `EMAIL_PROVIDER=dev`. Production blocks startup until a non-dev email provider is configured.

## Operations

Create a SQLite backup:

```bash
npm run db:backup
```

Export the MySQL Workbench SQL file:

```bash
npm run db:export:mysql
```

Backfill/rebuild the MySQL mirror from SQLite:

```bash
MYSQL_PASSWORD=your_mysql_password npm run db:sync:mysql
```

Health endpoint:

```text
GET /healthz
```

## MySQL Workbench Database

The full MySQL database export is generated at:

```text
data/shaw-enterprise-mysql.sql
```

The imported database name is:

```text
shaw_enterprise
```

It includes:

- `products`
- `product_images`
- `product_categories`
- `admin_users`
- `admin_audit_logs`
- `inquiries`
- `feedback_identities`
- `feedback_identity_otps`
- `feedback_comments`
- `feedback_reactions`
- `business_settings`

To view it in MySQL Workbench, refresh Schemas and open `shaw_enterprise`.

The running website now live-syncs writes into MySQL. Contact inquiries, admin product create/edit/delete, selected product images, feedback identity OTPs, feedback comments, reactions, moderation actions, login/logout audit entries, and admin audit logs are mirrored into `shaw_enterprise` immediately.

If MySQL Workbench is already showing a result grid, run the `SELECT` query again or click the refresh icon in Workbench to see the latest rows.

## Launch Checklist

- Set production `ADMIN_USER`, `ADMIN_PASSWORD`, `SESSION_SECRET`, and `EMAIL_PROVIDER`.
- Confirm `npm test` passes and `/healthz` returns `ok: true`.
- Run `npm run db:backup` before deployment.
- Confirm `/contact` submissions appear in Admin > Inquiries.
- Confirm Admin can mark inquiries as `new`, `contacted`, or `closed`.
- Confirm production OTP responses do not include `devOtp`.
- Deploy with Docker/Render using `npm start`.
