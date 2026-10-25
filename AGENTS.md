# 🤖 AGENTS.md — Developer & Agentic AI Guidelines for Fin Sail

This document serves as the single source of truth for AI coding agents and human developers maintaining, developing, or refactoring the **Fin Sail** codebase.

---

## ⛵ 1. Project Overview & Philosophy

**Fin Sail** is a pure expense tracking web application engineered with **Flutter Web**, optimized for a **mobile-first experience**, and backed by **Supabase** (Auth, Postgres RLS, Storage) with **Google Gemini 2.5 Flash** for intelligent OCR receipt parsing.

### Core Philosophy
1. **Pure Expenses**: No balance tracking, income tracking, or bank sync confusion. The entire app is tailored specifically for logging and understanding money spent.
2. **Frictionless Capture**: Users can log an expense in seconds via either the camera/file receipt scanner (OCR-powered) or the custom tactile numerical keypad.
3. **Rich, Cohesive Aesthetics**: Dark mode by default with curated vibrant color palettes, glassmorphism, responsive micro-animations, and clean typography.
4. **Resilient Offline/Demo Fallback**: Even without active Supabase credentials, the app operates seamlessly in **Local Demo Mode** with realistic seed data and OCR simulations.
5. **Production Cleanliness**: Developer triggers (such as simulated skeleton reloads) are strictly isolated to debug mode (`kDebugMode`) and omitted from production releases.

---

## 🛠️ 2. Technology Stack & Architecture

| Layer | Technology | Details |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.47+ / Dart 3.x | Web-first with CanvasKit / HTML rendering |
| **State Management** | `provider` (`ChangeNotifier`) | Central reactive store in `ExpenseProvider` |
| **Hosting & CDN** | Vercel & GitHub Pages | Dual-cloud automated deployment via GitHub Actions CI/CD |
| **Backend & Database** | Supabase (PostgreSQL) | Tables: `profiles`, `categories`, `transactions` |
| **Security** | Row-Level Security (RLS) | Strictly isolated user data (`auth.uid() = user_id`) |
| **Authentication** | Supabase Auth | Google SSO & 1-tap Guest Demo (Isolated Mock Data) |
| **Storage** | Supabase Storage | `Receipts` bucket for receipt scans |
| **AI / OCR** | Gemini 2.5 Flash Vision | Supabase Edge Function (`parse-receipt`) |
| **Internationalization** | `intl` | Multi-currency formatting (IDR, USD, EUR, GBP) |

---

## 📁 3. Directory Structure

```text
fin-logs/
├── .github/
│   └── workflows/
│       └── deploy.yml             # Automated multi-cloud CI/CD (Vercel + GitHub Pages)
├── lib/
│   ├── config/
│   │   ├── supabase_config.dart   # Backend URLs, keys, and Demo Mode detection
│   │   └── theme.dart             # Curated Dark & Light theme tokens and colors
│   ├── models/
│   │   ├── auth_user.dart         # Authenticated user representation
│   │   ├── category_model.dart    # Categories with signature vibrant color accents
│   │   ├── receipt_data.dart      # OCR parsing result & itemized receipt lines
│   │   └── transaction_model.dart # Expense transaction data structure
│   ├── providers/
│   │   └── expense_provider.dart  # Central store: transactions, categories, auth, theme
│   ├── screens/
│   │   ├── dashboard_screen.dart          # Home screen with monthly curve & recent spend
│   │   ├── keypad_expense_screen.dart     # Manual entry tactile keypad with inline delete
│   │   ├── login_screen.dart              # Google SSO & Quick Demo / Guest Access
│   │   ├── main_navigation_screen.dart    # Bottom nav (Analytics, Home, Settings) + FABs
│   │   ├── manage_categories_screen.dart  # Custom category manager with color palette picker
│   │   ├── receipt_scanner_modal.dart     # Live camera/file upload & laser scanner
│   │   ├── review_receipt_screen.dart     # Scanned expense review & itemized breakdown
│   │   ├── settings_screen.dart           # Preferences, theme, currency, Supabase status
│   │   └── transactions_list_screen.dart  # Dual analytics: All Expenses & Donut Chart
│   ├── services/
│   │   ├── receipt_scanner_service.dart   # Camera capture, mock parser, Supabase OCR client
│   │   └── supabase_service.dart          # PostgREST CRUD & Storage API integration
│   ├── utils/
│   │   ├── currency_format.dart           # Currency formatting utilities
│   │   └── thousands_separator_formatter.dart # Text field number formatting
│   ├── widgets/
│   │   ├── minimal_trend_chart.dart       # Sparkline charts
│   │   ├── mobile_frame.dart              # Desktop smartphone preview canvas container
│   │   ├── skeleton_loader.dart           # Shimmer skeleton loading placeholders
│   │   ├── top_categories_donut_chart.dart# Donut chart & category spending cards
│   │   ├── transaction_detail_sheet.dart  # Detail inspection & edit modal sheet
│   │   └── transaction_tile.dart          # Expense list item with category color avatar
│   └── main.dart                          # App entry point, MultiProvider & MaterialApp
├── supabase/
│   ├── functions/
│   │   └── parse-receipt/index.ts         # Edge Function using Gemini 2.5 Flash OCR
│   └── migrations/
│       └── 20261024000001_initial_schema.sql # Complete Postgres DDL, RLS & Storage setup
├── test/
│   ├── unit/
│   │   ├── category_model_test.dart       # Signature color & icon tests
│   │   ├── currency_format_test.dart      # Formatting precision tests
│   │   ├── expense_provider_test.dart     # State management CRUD tests
│   │   ├── phone_auth_test.dart           # Google SSO, Guest mock, and Sign Out tests
│   │   └── transaction_model_test.dart    # Transaction & Receipt parsing tests
│   ├── flutter_test_config.dart           # Hermetic test configuration
│   └── widget_test.dart                   # Smoke and widget tests
├── vercel.json                            # Vercel SPA rewrites and clean URLs
└── .vercelignore                          # Optimized build output filter
```

---

## 🎨 4. Design System & Branding Rules

1. **Brand Identity**:
   - Name: **Fin Sail** (two words, capitalized).
   - Brand Accent: **Sea Blue** (`#0284C7` / `AppTheme.seaBlue`).
   - "Sail" text in the logo is colored in Sea Blue.
2. **Category Color Accent Consistency**:
   - Every default category has a signature vibrant color defined in `CategoryModel.defaultCategories` and `CategoryModel.getDefaultColorForName`:
     - **Coffee**: Amber (`#F59E0B`)
     - **Pet Care**: Pink (`#EC4899`)
     - **Commute**: Electric Blue (`#3B82F6`)
     - **House Repair**: Purple (`#8B5CF6`)
     - **Food & Snacks**: Warm Orange (`#F97316`)
     - **Groceries**: Emerald Green (`#10B981`)
     - **Shopping**: Fuchsia (`#D946EF`)
     - **Bills & Utilities**: Yellow (`#EAB308`)
     - **Health**: Red (`#EF4444`)
     - **Other**: Cyan (`#06B6D4`)
   - Category color accents **MUST** reflect consistently across:
     - Manage Categories list tiles and custom badge.
     - Overview Home page transaction avatars.
     - Analytics All Expense Transaction filter chips & list avatars.
     - Analytics Chart Tab donut segments, category cards, and modal header.
     - Keypad manual expense selector capsule & category picker sheet.
     - Review Scanned Expense category chips.
     - Detail Expense header icon container and category pill.
     - Edit Expense category selector chips.
3. **Web Pointer & Hit-Testing Rule**:
   - In Flutter Web with CanvasKit, avoid wrapping opaque colored `Container`s directly around `InkWell` without a `Material` ancestor.
   - For custom interactive tiles or toggles, use either `Material(color: Colors.transparent, child: InkWell(...))` or `GestureDetector(behavior: HitTestBehavior.opaque, onTap: ...)`.
   - Never place decorative overlays (such as device mockups or camera cutouts) without `IgnorePointer`.
4. **Developer Debug Tooling Rule**:
   - Simulator actions, reload helpers, and "Test Skeleton" buttons **MUST** be conditionally rendered using `if (kDebugMode)`.
   - In production builds (`kReleaseMode`), these elements are strictly omitted to maintain a clean interface.

---

## ⚙️ 5. Development & Testing Commands

Always run commands using the project's configured Flutter SDK (`$HOME/flutter/bin`):

```bash
# 1. Check for static analysis or lint issues
$HOME/flutter/bin/flutter analyze

# 2. Run unit and widget test suite (24 tests)
$HOME/flutter/bin/flutter test

# 3. Build release web bundle
$HOME/flutter/bin/flutter build web --release

# 4. Deploy to Vercel production
npx vercel deploy --prod --yes
```

---

## 🔒 6. Security & Supabase Conventions

- Always enforce **Row Level Security (RLS)** in database migrations. Every table must check `auth.uid() = user_id`.
- Never expose service role keys in client code (`supabase_config.dart`). Only the `anon` public key is permitted on the client.
- The receipt storage bucket name is **`Receipts`**. Ensure proper storage policies exist before invoking uploads.
- The edge function `parse-receipt` requires `GEMINI_API_KEY` configured in Supabase secrets for production deployments.
- **Strict Auth Guarding**: Never allow unauthenticated users past `LoginScreen` on failed OAuth flows. The only way to access demo mode without credentials is via explicit `signInAsGuest()`.

---

## 🚦 7. Plan-First Workflow Gate

Per `.agents/skills/plan-first/SKILL.md`:
- **DO NOT MODIFY CODE IMMEDIATELY** upon receiving a feature, update, or bug fix request.
- First create a comprehensive implementation plan artifact covering:
  1. **Product Knowledge & UX**: User flows, interactions, edge cases, theme and aesthetic tokens.
  2. **Technical Approach**: Affected files, state mutations in `ExpenseProvider`, DB schema/RLS impact.
  3. **Automated Unit Testing Plan**: Specific test cases to be written in `test/unit/`.
  4. **Impact Mapping Trace**: Affected nodes in `IMPACT-MAPPING.md`.
- Present the plan to the user, incorporate any feedback, and wait for **explicit user approval** before writing or modifying any code.

---

## 🧪 8. Mandatory Unit Tests & Impact Mapping Rules

1. **Mandatory Unit Testing (`.agents/rules/mandatory-unit-tests.md`)**:
   - Every code update **MUST** include automated unit tests under `test/unit/`.
   - Test execution (`flutter test`) must achieve 100% pass rate across all 24 unit & widget tests.
   - PRs and tasks without unit tests are strictly rejected.
2. **Impact Mapping Maintenance (`IMPACT-MAPPING.md`)**:
   - Consult `IMPACT-MAPPING.md` before planning to assess blast radius.
   - When updates are realized, synchronize `IMPACT-MAPPING.md` with new components and test mappings.
   - Run the automated Graphify AST parser:
     ```bash
     bash .agents/skills/impact-mapping/scripts/run_graphify.sh
     ```
