# Shaw Enterprise Website

A professional full-stack website for Shaw Enterprise, a wholesale and retail disposable items business.

## Run Locally

```powershell
node server.js
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

## Features

- Public pages for Home, Products, Feedback, and Contact
- Product catalog with 300 seeded products, generated product visuals, prices, detailed product panel, and product-specific reviews
- Feedback system with email identity verification, replies, likes, hearts, unlike/toggle behavior, sorting, and load more
- Admin panel with product CRUD, feedback moderation, inquiries, and audit logs
- Admin image picker with local file selection and preview
- SQLite database created automatically at `data/shaw-enterprise.db`
- Docker and Render deployment files included

## Notes

The OTP verification currently returns the OTP in the browser response for local testing. For live production, connect `/api/feedback/request-otp` to an email provider and stop returning `devOtp`.

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
