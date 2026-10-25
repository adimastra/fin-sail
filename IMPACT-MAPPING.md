# 🗺️ Fin Sail — Comprehensive Impact Mapping & Dependency Matrix

> **Living Architecture Document**: Updated upon every realized application update per `.agents/skills/impact-mapping/SKILL.md`.  
> **Last Updated**: 2026-10-25 (Action Confirmations, Animated Success Popups, Guards & Chart Animations)

---

## 📌 1. Visual Architecture & Dependency Graph

The Mermaid graph below details how every layer of Fin Sail connects—from UI presentation down to Supabase storage, edge functions, multi-cloud hosting, and unit tests.

```mermaid
graph TD
    %% Entry & Frame
    Main[main.dart] --> App[FinSailApp]
    App --> Frame[ResponsiveMobileFrame]
    Frame --> Login[LoginScreen]
    Frame --> Nav[MainNavigationScreen]

    %% Authentication Sub-flows
    Login --> GoogleSSO[Google OAuth SSO (Supabase Auth)]
    Login --> GuestAccess[1-Tap Quick Demo Access (In-Memory Mock)]

    %% Navigation Tabs
    Nav --> TabHome[DashboardScreen]
    Nav --> TabAnalytics[TransactionsListScreen]
    Nav --> TabSettings[SettingsScreen]

    %% Home Components
    TabHome --> WaveChart[FinSailWavePainter]
    TabHome --> MonthScrubber[Month Timeline Scrubber]
    TabHome --> TxTile[TransactionTile]
    TabHome --> FabScan[Scan Receipt FAB]
    TabHome --> FabAdd[Add Keypad Expense FAB]

    %% Analytics Components
    TabAnalytics --> SubTabAll[All Expense Transactions]
    TabAnalytics --> SubTabChart[TopCategoriesDonutChart]
    SubTabAll --> DateFilter[DateRangePicker <= today]
    SubTabAll --> SearchField[Merchant & Category Search]
    SubTabAll --> CatChips[Category Filter Chips]
    SubTabAll --> TxTile
    SubTabChart --> DonutPainter[_DonutChartPainter]
    SubTabChart --> CatCards[Category Spending Cards]
    CatCards --> CatModal[MonthDetailsSheetModal]
    CatModal --> TxTile

    %% Modals & Flows
    FabAdd --> KeypadModal[KeypadExpenseScreen]
    FabScan --> ScannerModal[ReceiptScannerModal]
    ScannerModal --> ReviewModal[ReviewReceiptScreen]
    TxTile --> DetailModal[TransactionDetailSheet]
    TabSettings --> ManageCat[ManageCategoriesScreen]
    ManageCat --> CreateCat[CreateCategorySheet]
    KeypadModal --> SuccessDialog[AnimatedSuccessDialog]
    ReviewModal --> SuccessDialog
    DetailModal --> ConfirmDialog[ActionConfirmationDialog]
    DetailModal --> SuccessDialog
    ManageCat --> ConfirmDialog
    ManageCat --> SuccessDialog
    CreateCat --> SuccessDialog

    %% State Management
    Login --> Provider[ExpenseProvider]
    TabHome --> Provider
    TabAnalytics --> Provider
    TabSettings --> Provider
    KeypadModal --> Provider
    ReviewModal --> Provider
    DetailModal --> Provider
    ManageCat --> Provider

    %% Services & Backend
    Provider --> MockData[Local Mock Store]
    Provider --> SupabaseSvc[SupabaseService]
    ScannerModal --> ScannerSvc[ReceiptScannerService]
    ScannerSvc --> EdgeFunc[parse-receipt Edge Function]
    EdgeFunc --> Gemini[Google Gemini 2.5 Flash]
    SupabaseSvc --> DB_Tx[(public.transactions)]
    SupabaseSvc --> DB_Cat[(public.categories)]
    SupabaseSvc --> DB_Prof[(public.profiles)]
    SupabaseSvc --> DB_Auth[(auth.users)]
    ScannerSvc --> Bucket_Receipts[(storage.Receipts)]

    %% Hosting Targets
    CI[GitHub Actions CI/CD] --> Vercel[Vercel Edge Global Network]
    CI --> Pages[GitHub Pages CDN]
    Vercel --> VercelConfig[vercel.json SPA Rewrites]

    %% Models
    Provider --> ModelTx[TransactionModel]
    Provider --> ModelCat[CategoryModel]
    ScannerSvc --> ModelReceipt[ReceiptData & ReceiptItem]
    Provider --> ModelUser[AuthUser]

    %% Automated Unit Tests
    TestCat[category_model_test.dart] -.-> ModelCat
    TestTx[transaction_model_test.dart] -.-> ModelTx
    TestTx -.-> ModelReceipt
    TestCurr[currency_format_test.dart] -.-> UtilCurr[CurrencyFormat]
    TestProv[expense_provider_test.dart] -.-> Provider
    TestProv -.-> MockData
    TestAuth[phone_auth_test.dart] -.-> GoogleSSO
    TestAuth -.-> GuestAccess
    TestAuth -.-> Provider
    TestAuth -.-> SupabaseSvc
    TestGuards[action_guards_and_animation_test.dart] -.-> ConfirmDialog
    TestGuards -.-> SuccessDialog
    TestGuards -.-> DonutPainter

    classDef screen fill:#1E1B4B,stroke:#6366F1,stroke-width:2px,color:#fff;
    classDef provider fill:#064E3B,stroke:#10B981,stroke-width:2px,color:#fff;
    classDef model fill:#78350F,stroke:#F59E0B,stroke-width:2px,color:#fff;
    classDef backend fill:#831843,stroke:#EC4899,stroke-width:2px,color:#fff;
    classDef test fill:#14532D,stroke:#22C55E,stroke-width:2px,color:#fff;
    classDef hosting fill:#1F2937,stroke:#0284C7,stroke-width:2px,color:#fff;

    class TabHome,TabAnalytics,TabSettings,KeypadModal,ScannerModal,ReviewModal,ManageCat,DetailModal,Login,ConfirmDialog,SuccessDialog screen;
    class Provider provider;
    class ModelTx,ModelCat,ModelReceipt,ModelUser model;
    class DB_Tx,DB_Cat,DB_Prof,DB_Auth,Bucket_Receipts,EdgeFunc,Gemini backend;
    class TestCat,TestTx,TestCurr,TestProv,TestAuth,TestGuards test;
    class Vercel,Pages,VercelConfig,CI hosting;
```

---

## 📊 2. Component & Downstream Blast Radius Matrix

When modifying any component, consult this table to assess which downstream dependencies are impacted:

| Component / Layer | File Path | Dependent UI / Logic | Impacted Backend / State | Unit Test Coverage |
| :--- | :--- | :--- | :--- | :--- |
| **`LoginScreen`** | `lib/screens/login_screen.dart` | Google SSO button, Quick Demo access button, value props | `SupabaseService.signInWithGoogle`, `signInAsGuest` | `test/unit/phone_auth_test.dart` |
| **`CategoryModel`** | `lib/models/category_model.dart` | Manage Categories, Overview Avatars, Analytics Filter Chips, Donut Slices, Keypad Pill, Review Chips, Detail Pill | `categories` table, `ExpenseProvider.categories` | `test/unit/category_model_test.dart` |
| **`TransactionModel`** | `lib/models/transaction_model.dart` | Overview List, All Expense Stream, Detail Sheet, Review Scanned Expense | `transactions` table, `items (JSONB)` | `test/unit/transaction_model_test.dart` |
| **`ReceiptData`** | `lib/models/receipt_data.dart` | `ReceiptScannerService`, `ReviewReceiptScreen` | Gemini Edge Function output, Storage `Receipts` | `test/unit/transaction_model_test.dart` |
| **`ExpenseProvider`** | `lib/providers/expense_provider.dart` | All screens, modals, and FAB buttons | Local Demo Mock, Supabase PostgREST sync, Phone Auth | `test/unit/expense_provider_test.dart`, `phone_auth_test.dart` |
| **`TopCategoriesDonutChart`** | `lib/widgets/top_categories_donut_chart.dart` | `TransactionsListScreen` (Tab 1), Category Modal | On-load radial sweep & line score progress animation | `test/unit/action_guards_and_animation_test.dart`, `test/widget_test.dart` |
| **`AnimatedActionDialog`** | `lib/widgets/animated_action_dialog.dart` | `TransactionDetailSheet`, `KeypadExpenseScreen`, `ReviewReceiptScreen`, `ManageCategoriesScreen` | Modal animations, popups, double-tap prevention guards | `test/unit/action_guards_and_animation_test.dart` |
| **`TransactionTile`** | `lib/widgets/transaction_tile.dart` | `DashboardScreen`, `TransactionsListScreen`, `MonthDetailsSheetModal` | Category color accents, receipt flags | `test/widget_test.dart` |
| **`CurrencyFormat`** | `lib/utils/currency_format.dart` | All price displays, cards, keypad, and donut chart | `NumberFormat` localization | `test/unit/currency_format_test.dart` |
| **`SupabaseService`** | `lib/services/supabase_service.dart` | `ExpenseProvider` | Supabase Client, Auth (`auth.users`), Storage, RLS | `test/unit/phone_auth_test.dart` |
| **`VercelConfig`** | `vercel.json` | Vercel Edge Hosting, clean URLs, SPA routing | Static delivery | Deployment pipeline check |

---

## 🧪 3. Unit Test Coverage Matrix

Every module in Fin Sail is mapped to automated unit tests (**30 tests, 100% pass rate**):

| Module / Area | Test File | Coverage Details | Verification Command |
| :--- | :--- | :--- | :--- |
| **Phone Auth & Session Guards** | `test/unit/phone_auth_test.dart` | Phone registration, phone sign-in, session reset on sign-out, guest demo login, strict auth guard | `flutter test test/unit/phone_auth_test.dart` |
| **Categories** | `test/unit/category_model_test.dart` | 10 default categories, vibrant color defaults, hex parsing, color fallback, vector icon resolution, `toJson`/`fromJson` | `flutter test test/unit/category_model_test.dart` |
| **Currencies & Formats** | `test/unit/currency_format_test.dart` | IDR (`Rp 1.152.000`), USD (`$1,152.00`), EUR, GBP, zero amounts, negative numbers | `flutter test test/unit/currency_format_test.dart` |
| **Transactions & Receipts** | `test/unit/transaction_model_test.dart` | Expense transaction serialization, receipt flags, itemized line items list, confidence calculation | `flutter test test/unit/transaction_model_test.dart` |
| **Expense State & Providers** | `test/unit/expense_provider_test.dart` | Mock data seeding, month-over-month trend % delta, add/edit/delete transactions, custom category creation & default protection | `flutter test test/unit/expense_provider_test.dart` |
| **App Smoke Test** | `test/widget_test.dart` | Material app bootstrap, mobile frame wrapping & theme initialization | `flutter test test/widget_test.dart` |

---

## 🔄 4. Update Protocol

Whenever changes to Fin Sail are realized:
1. Identify if new components, state handlers, or models were introduced.
2. Update the Mermaid graph in Section 1.
3. Update the Blast Radius Matrix in Section 2.
4. Add new test scenarios in Section 3 and execute:
   ```bash
   $HOME/flutter/bin/flutter test
   bash .agents/skills/impact-mapping/scripts/run_graphify.sh
   ```
