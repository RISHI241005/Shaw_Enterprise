# Shaw Enterprise

Production-oriented website for a wholesale and retail disposable-products business. The active backend is Java 21 with Spring Boot 4.1.1. MySQL is the only runtime source of truth; the former Node/SQLite prototype remains in the repository only as migration history.

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

Requirements: Java 21, Maven 3.9+, MySQL 8.

The ignored `.env` file is already configured for this computer. It keeps database/admin secrets out of committed source.

```powershell
mvn spring-boot:run
```

Open [http://localhost:3000](http://localhost:3000). The admin portal is at [http://localhost:3000/login](http://localhost:3000/login).

To build and test:

```powershell
mvn test
mvn clean package
java -jar target/shaw-enterprise-2.0.0.jar
```

Health checks:

```text
GET /healthz
GET /actuator/health
```

## Business details and map

Sign in and open **Admin → Business & Map**. Set the real business name, phone, email, WhatsApp number, opening hours, and exact street address. Saving once updates the footer, contact page, embedded map, and mobile Google Maps directions links for every open visitor session.

The navigation link uses Google's cross-platform Maps URL (`api=1`), which opens the Google Maps app on supported phones and does not require an API key. The embedded map also avoids a paid JavaScript Maps SDK key.

The current database still contains placeholder contact details. Production mode intentionally refuses to launch until those are replaced.

## Configuration

Copy `.env.example` to `.env` on a new machine and fill in private values. Never commit `.env`.

Important values:

- `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`
- `ADMIN_USER`, `ADMIN_PASSWORD`
- `OTP_SECRET`
- `DEV_EXPOSE_OTP=false` in production
- `APP_PRODUCTION=true` in production
- `ALLOW_ADMIN_REGISTRATION=false` except during an owner-approved onboarding window

The local `root` account is suitable only for development. For a sale/deployment, create a least-privilege MySQL user limited to the `shaw_enterprise` schema.

## API summary

Public:

- `GET /api/products`
- `GET /api/products/{id}`
- `POST /api/inquiries`
- `GET /api/feedback`
- `POST /api/feedback/request-otp`
- `POST /api/feedback/verify-otp`
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

## Deployment

Build the included Dockerfile and supply secrets through the host's environment. `render.yaml` lists the required variables. The application automatically validates and migrates the database on startup.

Before enabling `APP_PRODUCTION=true`:

1. Replace every placeholder in **Admin → Business & Map**.
2. Use unique production database/admin/OTP secrets.
3. Set `DEV_EXPOSE_OTP=false` and connect a transactional email/SMS provider before offering public OTP flows.
4. Put the service behind HTTPS and take a MySQL backup.
5. Run `mvn test`, verify `/healthz`, then perform one enquiry and admin status change.
