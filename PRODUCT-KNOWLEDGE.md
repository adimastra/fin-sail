# 🧠 PRODUCT-KNOWLEDGE.md — Fin Sail Comprehensive Product & Feature Guide

This document contains a thorough architectural and feature-level explanation of **Fin Sail**, detailing each module, screen, workflow, data model, and user experience interaction.

---

## 📌 Table of Contents
1. [Product Overview & Value Proposition](#1-product-overview--value-proposition)
2. [High-Level System Architecture](#2-high-level-system-architecture)
3. [Module 1: Authentication & Onboarding](#3-module-1-authentication--onboarding)
4. [Module 2: Overview & Home Dashboard](#4-module-2-overview--home-dashboard)
5. [Module 3: Manual Expense Entry (Keypad)](#5-module-3-manual-expense-entry-keypad)
6. [Module 4: AI Receipt Scanner & OCR Vision](#6-module-4-ai-receipt-scanner--ocr-vision)
7. [Module 5: Dual-Mode Analytics & Trends](#7-module-5-dual-mode-analytics--trends)
8. [Module 6: Category Management & Design Tokens](#8-module-6-category-management--design-tokens)
9. [Module 7: Detail & Edit Expense Lifecycle](#9-module-7-detail--edit-expense-lifecycle)
10. [Module 8: Settings, Preferences & System Modes](#10-module-8-settings-preferences--system-modes)
11. [Module 9: Responsive Desktop Canvas Engine](#11-module-9-responsive-desktop-canvas-engine)
12. [Data Models & Schema Reference](#12-data-models--schema-reference)

---

## 1. Product Overview & Value Proposition

### The Problem
Traditional personal finance apps often fail users for three main reasons:
1. **Income/Balance Clutter**: Showing balances, checking accounts, credit limits, and investments distracts from the core daily habit—knowing exactly how much money went out the door today.
2. **High-Friction Data Entry**: Typing amounts on tiny mobile forms or connecting unreliable banking aggregators leads to tracking fatigue and abandonment.
3. **Generic Aesthetic**: Boring spreadsheets and monotonous grey tables make budgeting a chore.

### The Solution: Fin Sail
**Fin Sail** takes a minimalist, "pure-expense" approach:
- **No income or balance confusion**: Everything recorded is money spent.
- **Zero-friction capture**: Snap a receipt or tap out numbers on a bespoke numerical keypad in under 4 seconds.
- **AI Vision parsing**: Paper receipts are instantly broken down into itemized line items with Gemini 2.5 Flash.
- **Signature Category Accents**: Every spending category has an identity reinforced by distinctive colors and vector icons throughout the entire product.
- **Instant Demo Accessibility**: Users can explore 100% of the functionality in seconds without linking bank accounts or registering passwords.

---

## 2. High-Level System Architecture

```mermaid
graph TD
    User([User Device]) -->|Web Canvas| MobileFrame[ResponsiveMobileFrame]
    MobileFrame --> App[MaterialApp: Fin Sail]
    
    subgraph State Management
        App --> Provider[ExpenseProvider (ChangeNotifier)]
    end

    subgraph Screens & Navigation
        Provider --> Login[LoginScreen]
        Provider --> MainNav[MainNavigationScreen]
        MainNav --> Tab1[DashboardScreen (Home)]
        MainNav --> Tab2[TransactionsListScreen (Analytics)]
        MainNav --> Tab3[SettingsScreen]
        MainNav --> Modal1[KeypadExpenseScreen]
        MainNav --> Modal2[ReceiptScannerModal]
        Modal2 --> Review[ReviewReceiptScreen]
        Tab3 --> ManageCat[ManageCategoriesScreen]
    end

    subgraph Data & Cloud Services
        Provider --> LocalMock[(Local Mock Seed Store)]
        Provider --> SupabaseService[SupabaseService / PostgREST]
        Modal2 --> ScannerService[ReceiptScannerService]
        ScannerService --> EdgeFunction[Supabase Edge Function: parse-receipt]
        EdgeFunction --> Gemini[Google Gemini 2.5 Flash Vision]
        SupabaseService --> Storage[(Supabase Storage: Receipts)]
        SupabaseService --> Postgres[(Supabase Postgres DB with RLS)]
    end
```

---

## 3. Module 1: Authentication & Onboarding
**File**: `lib/screens/login_screen.dart`, `lib/models/auth_user.dart`

### Features & Capabilities
1. **Google Single Sign-On (SSO)**:
   - Powered by Supabase Auth (`supabase.auth.signInWithOAuth(OAuthProvider.google)`).
   - Seamless authentication without passwords.
2. **Quick Demo / Guest Access**:
   - 1-Tap entry allowing immediate evaluation of the application without an account.
   - Pre-seeds realistic Indonesian Rupiah (Rp) / multi-currency transactions, categories, and sample receipts.
3. **Branded Visual Experience**:
   - Official **Fin Sail** header with stylized boat/wave logo in Sea Blue (`#0284C7`).
   - Feature highlight cards explaining *Receipt-First Tracking*, *Analytics & Monthly Trends*, and *End-to-End Privacy*.
   - Dark mode compliant Google SSO button (white pill with multi-color G-icon) and translucent outline demo button.

---

## 4. Module 2: Overview & Home Dashboard
**File**: `lib/screens/dashboard_screen.dart`, `lib/widgets/transaction_tile.dart`

### Features & Capabilities
1. **Hero Monthly Spend Display**:
   - Prominent currency typography (`Rp 1.152.000` / `$1,152.00`) displaying current month spending.
   - Animated ocean wave graphic (`FinSailWavePainter`) with a boat icon cruising across the monthly spending curve.
2. **Horizontal Month Scrubber**:
   - Scrollable timeline showing previous months (`Jun`, `Jul`, `Aug`, `Sep`, `Oct`) with active month pill indicator.
   - Dynamically re-filters spending curves and recent transactions upon selection.
3. **Daily Transaction Groups**:
   - Categorized into "today", "yesterday", and older dates with daily expense subtotals.
   - Rendered using `TransactionTile`:
     - Avatar box styled in the category's signature color accent.
     - Category name, merchant notes, and has-receipt indicator badge (`receipt_long` icon).
     - Formatted negative currency amount (`-Rp 25.000`).
     - Tap to view full detail sheet or swipe to delete.
4. **Pinned Dual Floating Action Buttons**:
   - Circular **Scan Receipt Button** (white in dark mode, document scanner icon).
   - Circular **Manual Expense Button** (`+` icon with mechanical click feel).

---

## 5. Module 3: Manual Expense Entry (Keypad)
**File**: `lib/screens/keypad_expense_screen.dart`

### Features & Capabilities
1. **Bespoke Tactile Numerical Keypad**:
   - Numbers `1` through `9`, `0`, `000` (for rapid high-denomination logging such as IDR or JPY), and `C` (Clear).
   - Keypad keys provide smooth scale animations and haptic feedback.
2. **Inline Backspace / Delete Action**:
   - A dedicated delete button positioned **directly next to the displayed currency digits** for effortless correction without hand re-positioning.
3. **Category Selector Pill**:
   - Tapping the category pill opens a bottom sheet featuring all 10 default and user custom categories.
   - Each chip displays the category's vector icon in its distinctive color accent.
4. **Merchant & Date Entry**:
   - Quick text field for store or payee name.
   - Interactive calendar picker defaulting to today.

---

## 6. Module 4: AI Receipt Scanner & OCR Vision
**Files**: `lib/screens/receipt_scanner_modal.dart`, `lib/screens/review_receipt_screen.dart`, `lib/services/receipt_scanner_service.dart`, `supabase/functions/parse-receipt/index.ts`

### Features & Capabilities
1. **Scanner Modal Interface**:
   - Support for **Camera Capture** on mobile devices and **File Upload** on desktop.
   - Animated high-tech laser scanner HUD with glowing progress line.
   - **1-Tap Demo Receipt**: Instantly loads a realistic sample receipt for testing without camera permissions.
2. **Gemini 2.5 Flash Vision Parsing**:
   - Image is uploaded to Supabase Storage (`Receipts` bucket) and analyzed via edge function.
   - Edge function issues structured prompt instructions to Gemini 2.5 Flash:
     - Merchant name
     - Date of purchase
     - Subtotal, tax, tip, and total amount
     - Suggested category
     - Line items with individual item names, quantities, and prices.
3. **Review Scanned Expense Screen**:
   - **Hero Card**: Total detected amount with edit capability.
   - **Merchant & Date Fields**: Pre-filled from OCR with manual override.
   - **Category Selector**: Selects matching category chip highlighted in that category's color accent.
   - **Itemized Line Items Table**: Displays each individual item purchased, with unit price and remove item buttons.
   - **Receipt Image Thumbnail**: Expandable preview of original photo.
   - **Save Action**: Saves to transactions table with `hasReceipt = true` and full itemized metadata.

---

## 7. Module 5: Dual-Mode Analytics & Trends
**Files**: `lib/screens/transactions_list_screen.dart`, `lib/widgets/top_categories_donut_chart.dart`

Fin Sail offers two complementary analytical views switched via an ergonomic top-right toggle pill:

### Subtab 1: All Expense Transactions (Bar Chart Icon)
- **Date Range Picker**:
  - Filter transactions between two dates (enforced `<= today` to prevent future expense errors).
  - Displays formatted range label (e.g. `1 Oct - 25 Oct 2026`) with a 1-tap `x` clear button.
- **Search Bar**:
  - Real-time search across merchant names, notes, and category labels.
- **Filter Chips Row**:
  - `all` chip for resetting filters.
  - `Receipts` filter chip for isolating scanned paper/electronic receipts.
  - Category filter chips displaying each category's vector icon in its signature color accent.
- **Date-Grouped Transaction Stream**:
  - Groups matching expenses by day with daily totals and transaction count.

### Subtab 2: Chart by Categories (Pie/Donut Icon)
- **Top Categories Donut Chart**:
  - Multi-segment rounded arc donut chart where **every slice is colored directly by the category's configured color accent**.
  - Center display shows total monthly spend. Tapping the center opens a modal listing all transactions for that month.
- **Month & Year Picker**:
  - Dropdown chip opening a 12-month grid selector for navigating historic spending.
- **Category Spending Cards**:
  - Displays category icon in a tinted square box using its color accent.
  - Shows category name, percentage of total monthly spend (`32.6% of total`), and total amount spent.
  - **Month-over-Month Delta Badge**: Green for decreased spend (savings), red for increased spend (`+11% vs previous month`), or `new` for freshly logged categories.
  - Category horizontal progress bar colored in that category's exact accent.
- **Drill-Down Category Detail Sheet**:
  - Tapping any category card opens an isolated transaction list for that category and month, with category icon branding in the sheet header.

---

## 8. Module 6: Category Management & Design Tokens
**Files**: `lib/screens/manage_categories_screen.dart`, `lib/models/category_model.dart`

### Features & Capabilities
1. **10 Signature Default Categories**:
   - Coffee, Pet Care, Commute, House Repair, Food & Snacks, Groceries, Shopping, Bills & Utilities, Health, Other.
   - Protected from accidental deletion.
   - Pre-assigned signature vibrant color hex codes.
2. **Inline Add Action**:
   - Positioned cleanly at the **far right edge inline with the `custom categories` section header**.
3. **Custom Category Creator**:
   - Modal bottom sheet with real-time live preview card.
   - Text input for custom category name.
   - 24+ vector icon picker (Gaming, Gym, Travel, Movies, Music, Education, Gift, Investment, Work, Dining, etc.).
   - **Color Accent Palette**: 9 curated vibrant colors with interactive selection ring.
4. **Deletion Safety**:
   - Custom categories can be deleted with confirmation dialog.
   - Default categories are locked with a "System default" security badge.

---

## 9. Module 7: Detail & Edit Expense Lifecycle
**File**: `lib/widgets/transaction_detail_sheet.dart`

### Features & Capabilities
1. **Transaction Inspection Sheet**:
   - Header container with category icon in that category's color accent.
   - Merchant title, transaction date, and formatted currency amount.
   - Category pill badge.
   - Optional receipt image thumbnail if captured via OCR.
   - Itemized line items list with item names and prices.
2. **In-Place Editing**:
   - Switch into Edit Mode without leaving the sheet.
   - Modify amount, merchant, date, notes, and re-assign category using color accent chips.
3. **Deletion Workflow**:
   - Trash icon with AlertDialog confirmation ensuring zero accidental data loss.

---

## 10. Module 8: Settings, Preferences & System Modes
**File**: `lib/screens/settings_screen.dart`

### Features & Capabilities
1. **User Profile Card**:
   - Displays authenticated Google user avatar, name, email, and SSO badge.
2. **Theme Switcher**:
   - Three-way selector: **Dark Mode**, **Light Mode**, or **Use System**.
3. **Multi-Currency Support**:
   - Instant switching between **IDR (Rp)**, **USD ($)**, **EUR (€)**, and **GBP (£)**.
4. **Haptic Feedback**:
   - Toggle tactile vibrations for keypad presses and button taps.
5. **Manage Categories Shortcut**:
   - Shows active custom category count and default category count.
   - Direct navigation to `ManageCategoriesScreen`.
6. **Cloud & Storage Status**:
   - Live badge showing Supabase connection status or Local Demo Mode.
   - Gemini 2.5 Flash Vision OCR status badge.
   - "Test Skeleton Loader" developer utility to preview shimmer loading states.
7. **Sign Out**:
   - Confirmation dialog terminating Supabase session and returning to login.

---

## 11. Module 9: Responsive Desktop Canvas Engine
**File**: `lib/widgets/mobile_frame.dart`

### Features & Capabilities
1. **Adaptive Desktop Smartphone Shell**:
   - On desktop screens (`width > 650px`), the app centers within a sleek 420px smartphone bezel complete with subtle glass shadows, ambient indigo radial glow, and speaker pill.
2. **Top Control Bar**:
   - Displays "Fin Sail Web Mobile View" branding.
   - Live backend status badge (Demo Mode / Supabase Active).
   - Fullscreen / Phone Frame toggle button allowing developers to preview in raw full-width or framed mobile viewport.
3. **Pure Mobile Responsiveness**:
   - Automatically bypasses the mock frame on actual mobile browsers or tablets, providing a native 100% full-screen mobile app feel.

---

## 12. Data Models & Schema Reference

### `TransactionModel`
```dart
class TransactionModel {
  final String id;
  final String? userId;
  final String? categoryId;
  final double amount;
  final String type; // 'expense'
  final String? merchant;
  final String? note;
  final DateTime transactionDate;
  final String? receiptUrl;
  final bool hasReceipt;
  final List<ReceiptItem>? items;
  final CategoryModel? category;
}
```

### `CategoryModel`
```dart
class CategoryModel {
  final String id;
  final String? userId;
  final String name;
  final String emoji;
  final String colorHex;
  final bool isDefault;
  final String? iconName;
  
  Color get color; // Resolves colorHex to signature Vibrant Color
  IconData get icon; // Resolves iconName or name to Material Icon
}
```

### `ReceiptData` & `ReceiptItem`
```dart
class ReceiptData {
  final String? merchant;
  final double? totalAmount;
  final DateTime? date;
  final String? category;
  final List<ReceiptItem> items;
  final double confidence;
}

class ReceiptItem {
  final String name;
  final double price;
  final int quantity;
}
```

### Supabase Database Tables (`supabase/migrations/20261024000001_initial_schema.sql`)
1. **`public.profiles`**: `id (UUID FK auth.users)`, `full_name`, `avatar_url`, `currency`, `created_at`.
2. **`public.categories`**: `id (UUID)`, `user_id (UUID null for system defaults)`, `name`, `emoji`, `color_hex`, `is_default (BOOLEAN)`, `icon_name`.
3. **`public.transactions`**: `id (UUID)`, `user_id (UUID)`, `category_id (UUID FK categories)`, `amount (NUMERIC)`, `type (VARCHAR)`, `merchant`, `note`, `transaction_date (TIMESTAMPTZ)`, `receipt_url`, `has_receipt (BOOLEAN)`, `items (JSONB)`.
4. **`storage.buckets`**: **`Receipts`** bucket configured with authenticated user upload policies.
