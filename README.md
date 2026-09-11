# Shaw Enterprise

Production-oriented website for a wholesale and retail disposable-products business. The Vercel deployment is one integrated project: a Node.js serverless function serves the pages and APIs and connects directly to MySQL or MySQL-compatible TiDB Cloud. The Java 21/Spring Boot implementation remains available for traditional container hosting.

## What works

- Responsive Home, Products, Feedback, Contact, Login, and Admin pages
- 300-product MySQL catalog with search, category filters, sorting, details, product images, and reviews
- Transactional product create/update/delete APIs
- Contact enquiries stored directly in MySQL and managed through status workflows
- Email-verified feedback, replies, likes/hearts, product reviews, and admin moderation
- BCrypt for all newly created/reset administrator passwords
- Session rotation, CSRF checks, rate limits, validation, safe output escaping, security headers, and audit logs
- Server-sent events that synchronize product, feedback, enquiry, and business-setting changes across open browser tabs
- Embedded Google Map, Google Maps mobile directions URL, click-to-call, email, and WhatsApp links
- Flyway schema migrations, Actuator health, Docker packaging, and Render configuration

## Run locally

Requirements: Node.js 22+ and MySQL 8 or TiDB Cloud.

The ignored `.env` file is already configured for this computer. It keeps database/admin secrets out of committed source.

```powershell
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000). The admin portal is at [http://localhost:3000/login](http://localhost:3000/login).

To build and test:

```powershell
npm test
npm run build
```

Health checks:

```text
GET /healthz
```

## Business details and map

Sign in and open **Admin → Business & Map**. Set the real business name, phone, email, WhatsApp number, opening hours, and exact street address. Saving once updates the footer, contact page, embedded map, and mobile Google Maps directions links for every open visitor session.

The navigation link uses Google's cross-platform Maps URL (`api=1`), which opens the Google Maps app on supported phones and does not require an API key. The embedded map also avoids a paid JavaScript Maps SDK key.

The current database still contains placeholder contact details. Production mode intentionally refuses to launch until those are replaced.

## Configuration

Copy `.env.example` to `.env` on a new machine and fill in private values. Never commit `.env`.

Important values:

- `DATABASE_URL`, or `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`
- Vercel TiDB integration variables `TIDB_HOST`, `TIDB_PORT`, `TIDB_DATABASE`, `TIDB_USER`, `TIDB_PASSWORD`
- `ADMIN_USER`, `ADMIN_PASSWORD`
- `SESSION_SECRET`, `OTP_SECRET`
- Demo OTP mode is enabled for this project: each email or phone request creates a fresh six-digit code and displays it on the page for 10 minutes.
- Java admin registration and reset requests also return their fresh dummy codes to the on-screen status area.
- `APP_PRODUCTION=true` in production
- `ALLOW_ADMIN_REGISTRATION=false` except during an owner-approved onboarding window

The local `root` account is suitable only for development. For a sale/deployment, create a least-privilege MySQL user limited to the `shaw_enterprise` schema.

## API summary

Public:

- `GET /api/products`
- `GET /api/products/{id}`
- `POST /api/inquiries`
- `GET /api/feedback`
- `POST /api/feedback/request-otp` (visible dummy OTP for email or phone)
- `POST /api/feedback/verify-otp` (email or phone)
- `POST /api/feedback`
- `POST /api/feedback/{id}/react`
- `GET /api/live` (SSE)

Authenticated admin:

- Product CRUD under `/api/admin/products`
- Enquiry management under `/api/admin/inquiries`
- Moderation under `/api/admin/feedback`
- Audit history at `/api/admin/audits`
- Business/map settings at `/api/admin/settings`

All write endpoints require the CSRF token supplied in the page's `csrf-token` meta element.

## Vercel deployment

`vercel.json` routes the complete website through `api/index.js`, so pages and APIs ship as one Vercel project. Connect a MySQL-compatible TiDB Cloud database from Vercel Storage; its `TIDB_*` variables are recognized automatically. The function creates missing tables and seeds the 300-product catalog when the database is empty.

The Node runtime is required on Vercel because Vercel does not provide an official Java/Spring runtime. To run the Java version instead, build the included Dockerfile and deploy it to a container host using `render.yaml`.

Before enabling `APP_PRODUCTION=true`:

1. Replace every placeholder in **Admin → Business & Map**.
2. Use unique production database/admin/OTP secrets.
3. Confirm that the visible dummy OTP behavior is appropriate for the deployment. Replace it with a private email/SMS provider before using verification as a real security boundary.
4. Put the service behind HTTPS and take a MySQL backup.
5. Run `npm test`, verify `/healthz`, then perform one enquiry and admin status change.
