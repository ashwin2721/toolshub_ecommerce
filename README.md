# TOOLSHUB

**Professional Tools & Hardware Store — Enterprise e-commerce platform.**

A cross-platform Flutter e-commerce application for selling professional tools and
hardware, with a full customer storefront, an admin management panel, and a
companion Node/Express + PostgreSQL backend.

---

## Tech Stack

| Layer | Technology |
|---|---|
| App | Flutter 3.44 / Dart 3.12 (mobile + web) |
| State management | [Riverpod](https://riverpod.dev) (`flutter_riverpod`) |
| Navigation | [go_router](https://pub.dev/packages/go_router) |
| Auth & realtime data | Firebase (Auth, Cloud Firestore, Storage, Messaging, Analytics) |
| REST backend | Node.js + Express + TypeScript + PostgreSQL (Neon), accessed via Dio |
| Payments | Razorpay (COD / UPI / Stripe / PayPal payment method options) |
| AI assistant | Google Gemini (via backend `/assistant` route) |
| Maps & location | [flutter_map](https://pub.dev/packages/flutter_map) (OpenStreetMap) + [geolocator](https://pub.dev/packages/geolocator); reverse/forward geocoding via OSM Nominatim (proxied by the backend) |

> The app is a **hybrid** data platform: some data flows through Firebase and some
> through the custom REST backend (`server/`) via `dioProvider`.

## Project Structure

```
lib/
├── core/            # theme, router, config, constants, errors, utils
├── data/            # models + database seeder
├── domain/          # entities (product, cart, order, user, category, misc)
├── presentation/
│   ├── providers/   # Riverpod providers (auth, cart, product, app)
│   ├── screens/     # feature screens (auth, home, product, cart, checkout,
│   │                #   orders, profile, search, admin, extra)
│   └── widgets/     # reusable UI (common, home, product)
├── firebase_options.dart
└── main.dart
server/              # Express + Postgres API (TypeScript)
├── src/routes/      # auth, products, orders, assistant
├── src/middlewares/ # JWT auth
└── src/db/          # schema.sql, seed, mock db
```

## Features

- **Storefront** — home with hero banners & categories, product listing/detail,
  search (fuzzy), product comparison, wishlist, cart, multi-step checkout with
  **location-based delivery pricing**, order confirmation, order
  list/detail/tracking.
- **Accounts** — email/password + Google sign-in, OTP, password reset, addresses
  (with **"use my current location"** autofill), profile, settings, notifications.
- **Admin panel** — dashboard, products (add/edit with multi-image), orders,
  customers, inventory, banners, coupons, reports, storefront content
  (promo/hero copy), and **distance-based delivery fees** (map-based shop
  location, free radius, per-km charges, free-over-amount, third-party courier).
- **Extras** — Gemini AI assistant, tool-service booking, support tickets, and
  static pages (about, contact, FAQ, privacy, terms).
- **Platform** — light/dark theme, English/Hindi localization, offline banner.

## Getting Started

### Prerequisites
- Flutter 3.44+ / Dart 3.12+
- A Firebase project (config in `lib/firebase_options.dart`)
- Node.js 20+ (for the backend)

### Run the app
```bash
flutter pub get
flutter run                       # dev flavor (default)
flutter run --dart-define=FLAVOR=prod
```

Environment/flavor is selected in `lib/core/config/app_config.dart`
(`FLAVOR=dev|prod`). Dev points the API base URL at `http://localhost:5000/api`.

### Run the backend
```bash
cd server
cp .env.example .env   # then fill in DATABASE_URL, JWT_SECRET, etc.
npm install
npm run db:seed        # seed Postgres
npm run dev            # tsx watch on PORT (default 5000)
```
Backend config lives in `server/.env` — start from `server/.env.example`
(see **Configuration** below).

## Configuration & Secrets

The following are **placeholders** and must be replaced with real values before
release (they will not process real transactions as-is):

- `lib/core/constants/app_constants.dart` — `razorpayKeyId`, `stripePublishableKey`,
  `paypalClientId`, `gstNumber`, `baseUrl`.
- `server/.env` — `DATABASE_URL`, `JWT_SECRET`, `GEMINI_API_KEY` (start from
  `server/.env.example`). This file is git-ignored; **never commit real
  credentials**, and rotate any secret that has been shared.
- The Gemini key can also be supplied to the app at build time:
  `flutter run --dart-define=GEMINI_API_KEY=...`

## Quality

```bash
flutter analyze      # static analysis (currently: 0 issues)
flutter test         # widget/unit tests
cd server && npx tsc --noEmit   # backend type-check
```

## Firebase

Security rules and indexes are versioned in the repo root:
`firestore.rules`, `firestore.indexes.json`, `storage.rules`, `firebase.json`.
