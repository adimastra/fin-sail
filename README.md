# ⛵ Fin Sail — Receipt Expense Tracker

[![Vercel Live Demo](https://img.shields.io/badge/Vercel-Live%20Demo-black?logo=vercel&logoColor=white)](https://fin-sail.vercel.app)
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Live%20Site-181717?logo=github&logoColor=white)](https://adimastra.github.io/fin-sail/)
[![Flutter Web](https://img.shields.io/badge/Flutter-Web-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend%20%26%20Auth-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Gemini](https://img.shields.io/badge/Gemini%202.5%20Flash-OCR%20Vision-4285F4?logo=google&logoColor=white)](https://ai.google.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Fin Sail** is a pure expense tracking web application engineered with **Flutter Web**, optimized for a **mobile-first view**, and backed by **Supabase** with **Google Gemini 2.5 Flash** for automated receipt OCR extraction.

Fin Sail is built around a single, uncompromising principle: **pure expense visibility**. By removing balance tracking, income management, and banking complications, it provides individuals with a fast, tactile, and aesthetic way to capture and analyze daily spending.

### 🌐 Live Production Deployments
- **Primary Domain (Vercel)**: **[https://fin-sail.vercel.app](https://fin-sail.vercel.app)**
- **Secondary Domain (GitHub Pages)**: **[https://adimastra.github.io/fin-sail/](https://adimastra.github.io/fin-sail/)**

---

## ✨ Flagship Features

### 1. 📸 AI Receipt Scanner & OCR Vision Parsing
- **Direct Camera or File Upload**: Snap photos of paper receipts on mobile or upload files on desktop.
- **Gemini 2.5 Flash Parsing**: Automatically extracts merchant name, date, subtotal, tax, tip, total amount, category, and line-by-line itemized items.
- **Laser Scanner Feedback**: Engaging animated scanner HUD during image analysis.
- **Interactive Review Screen**: Easily verify or modify line items, totals, and category before saving.
- **1-Tap Demo Receipt**: Built-in test receipt generator allowing full testing without camera or file uploads.

### 2. 🔢 Custom Tactile Keypad
- Built-in mechanical-feel numerical keypad with rapid currency formatting (`1-9`, `0`, `000`, `C`).
- **Inline Delete Action**: A dedicated backspace button positioned directly next to the active currency display for lightning-fast edits.
- Quick category selector pill opening an interactive modal picker.
- Merchant and notes input field.

### 3. 🎨 Category Module with Signature Color Accents
- **10 Signature Default Categories**: Pre-configured with distinct vibrant color accents:
  - ☕ **Coffee** (Amber `#F59E0B`)
  - 🐾 **Pet Care** (Pink `#EC4899`)
  - 🚗 **Commute** (Electric Blue `#3B82F6`)
  - 🔧 **House Repair** (Purple `#8B5CF6`)
  - 🍔 **Food & Snacks** (Warm Orange `#F97316`)
  - 🛒 **Groceries** (Emerald Green `#10B981`)
  - 🛍️ **Shopping** (Fuchsia `#D946EF`)
  - ⚡ **Bills & Utilities** (Yellow `#EAB308`)
  - 💊 **Health** (Red `#EF4444`)
  - 📦 **Other** (Cyan `#06B6D4`)
- **Custom Category Builder**:
  - Add action positioned neatly on the right edge inline with `custom categories`.
  - 24+ vector icons and a curated 9-color accent picker with real-time preview.
- **Full-App Color Accent Reflection**: Category colors reflect consistently on the Overview Home page, Analytics (both Transaction List and Chart tabs), Add Expense, Receipt Review, Detail Expense, and Edit Expense sheets.

### 4. 📊 Dual-Mode Analytics
- **Subtab 1: All Expense Transactions**:
  - Filter by date range (strictly `<=` today) with clean date span labels.
  - Live search across merchants and category names.
  - Receipts-only filter toggle.
  - Scrollable category filter chips styled with category color accents.
  - Transactions grouped chronologically with daily subtotals.
- **Subtab 2: Chart by Categories**:
  - Donut chart with rounded segments colored by each category's configured color accent.
  - Centered monthly total expense pill.
  - Month/Year grid picker.
  - Category spending breakdown cards showing amount, percentage of total spend, and month-over-month trend badges (`+11% vs previous month`).
  - Tap any category card to open a drill-down transaction modal with matching category header branding.

### 5. 🔐 Streamlined Authentication & Strict Data Segregation
- **Google SSO**: Authenticated via Google OAuth & Supabase Auth with Row-Level Security (RLS) and automatic OAuth callback handling. All data persists to live PostgreSQL database.
- **1-Tap Quick Demo / Guest Access**: Instant frictionless exploration with 14 pre-seeded in-memory mock expenses and 10 categories. Completely isolated from cloud tables without requiring credentials.
- **Clean Session Sign Out**: Accessible in Settings page to revoke sessions, reset memory state, and return securely to the welcome screen.

### 6. 📱 Responsive Desktop Mobile Canvas
- Renders inside an ultra-sleek, centered smartphone canvas on desktop displays.
- Includes a desktop top bar with branding, connection status badge, and fullscreen toggle.
- Expands automatically to 100% full-bleed layout on actual mobile browsers.

### 7. 🧼 Clean Production Interface
- Developer actions and simulated skeleton loader triggers are strictly guarded with `kDebugMode`. Production builds remain pristine and free of developer artifacts.

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK 3.47+** (Dart 3.x) installed and added to `PATH`.
- **Chrome** or any modern desktop/mobile web browser.

### 1. Run Locally

```bash
# Clone the repository
git clone https://github.com/adimastra/fin-sail.git
cd fin-sail

# Fetch dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome
```

Alternatively, run in web server mode:
```bash
flutter run -d web-server --web-port=4500 --web-hostname=localhost
```

### 2. Build for Production

```bash
flutter build web --release
```
The compiled bundle will be available in `build/web/`. You can serve it using any static web server:
```bash
npx serve -s build/web -l 4500
```

---

## ☁️ Multi-Cloud Deployment (Vercel & GitHub Pages)

Fin Sail features an automated GitHub Actions workflow [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) that triggers on every push to `main`:
1. Executes static analysis (`flutter analyze`).
2. Runs the 24 automated unit and widget tests (`flutter test`).
3. Compiles the production web bundle with injected Supabase credentials.
4. Deploys to **Vercel** with SPA rewrites via `vercel.json`.
5. Concurrently deploys to **GitHub Pages**.

---

## 🗄️ Supabase & Edge Function Configuration

### 1. Database Setup
1. Create a project at [supabase.com](https://supabase.com).
2. Open the **SQL Editor** in your Supabase Dashboard.
3. Paste and execute the migration script:
   ```
   supabase/migrations/20261024000001_initial_schema.sql
   ```
   This initializes:
   - `profiles` table (linked to `auth.users`).
   - `categories` table (with default categories and custom user categories).
   - `transactions` table (with itemized receipt line support).
   - Strict Row-Level Security (RLS) policies.
   - Storage bucket: **`Receipts`**.

### 2. Deploy Gemini OCR Edge Function
The OCR receipt parser runs on Supabase Edge Functions using Deno and the Gemini 2.5 Flash API:
```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Link your project
supabase link --project-ref your-project-id

# Set your Gemini API Key in Supabase secrets
supabase secrets set GEMINI_API_KEY=your-gemini-api-key

# Deploy the Edge Function
supabase functions deploy parse-receipt
```

### 3. Connect Client Credentials
Configure your Supabase URL and Anon Key via `--dart-define` at runtime:
```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://xywhladlyekplqvpiozg.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-public-anon-key
```

---

## 🧪 Testing

```bash
# Analyze code for errors and lint rules
flutter analyze

# Run unit and widget test suite (24 tests)
flutter test
```

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
