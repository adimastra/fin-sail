# 🗺️ Fin Sail — Comprehensive Impact Mapping & Dependency Matrix

> **Living Architecture Document**: Updated upon every realized application update per `.agents/skills/impact-mapping/SKILL.md`.  
> **Last Updated**: 2026-10-25

---

## 📌 1. Visual Architecture & Dependency Graph

The Mermaid graph below details how every layer of Fin Sail connects—from UI presentation down to Supabase storage, edge functions, and unit tests.

```mermaid
graph TD
    %% Entry & Frame
    Main[main.dart] --> App[FinSailApp]
    App --> Frame[ResponsiveMobileFrame]
    Frame --> Login[LoginScreen]
    Frame --> Nav[MainNavigationScreen]

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

    %% State Management
    TabHome --> Provider[ExpenseProvider]
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
    ScannerSvc --> Bucket_Receipts[(storage.Receipts)]

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

    classDef screen fill:#1E1B4B,stroke:#6366F1,stroke-width:2px,color:#fff;
    classDef provider fill:#064E3B,stroke:#10B981,stroke-width:2px,color:#fff;
    classDef model fill:#78350F,stroke:#F59E0B,stroke-width:2px,color:#fff;
    classDef backend fill:#831843,stroke:#EC4899,stroke-width:2px,color:#fff;
    classDef test fill:#14532D,stroke:#22C55E,stroke-width:2px,color:#fff;

    class TabHome,TabAnalytics,TabSettings,KeypadModal,ScannerModal,ReviewModal,ManageCat,DetailModal screen;
    class Provider provider;
    class ModelTx,ModelCat,ModelReceipt,ModelUser model;
    class DB_Tx,DB_Cat,DB_Prof,Bucket_Receipts,EdgeFunc,Gemini backend;
    class TestCat,TestTx,TestCurr,TestProv test;
```

---

## 📊 2. Component & Downstream Blast Radius Matrix

When modifying any component, consult this table to assess which downstream dependencies are impacted:

| Component / Layer | File Path | Dependent UI / Logic | Impacted Backend / State | Unit Test Coverage |
| :--- | :--- | :--- | :--- | :--- |
| **`CategoryModel`** | `lib/models/category_model.dart` | Manage Categories, Overview Avatars, Analytics Filter Chips, Donut Slices, Keypad Pill, Review Chips, Detail Pill | `categories` table, `ExpenseProvider.categories` | `test/unit/category_model_test.dart` |
| **`TransactionModel`** | `lib/models/transaction_model.dart` | Overview List, All Expense Stream, Detail Sheet, Review Scanned Expense | `transactions` table, `items (JSONB)` | `test/unit/transaction_model_test.dart` |
| **`ReceiptData`** | `lib/models/receipt_data.dart` | `ReceiptScannerService`, `ReviewReceiptScreen` | Gemini Edge Function output, Storage `Receipts` | `test/unit/transaction_model_test.dart` |
| **`ExpenseProvider`** | `lib/providers/expense_provider.dart` | All screens, modals, and FAB buttons | Local Demo Mock, Supabase PostgREST sync | `test/unit/expense_provider_test.dart` |
| **`TopCategoriesDonutChart`** | `lib/widgets/top_categories_donut_chart.dart` | `TransactionsListScreen` (Tab 1), Category Modal | Provider monthly spend & category map | `test/widget_test.dart` |
| **`TransactionTile`** | `lib/widgets/transaction_tile.dart` | `DashboardScreen`, `TransactionsListScreen`, `MonthDetailsSheetModal` | Category color accents, receipt flags | `test/widget_test.dart` |
| **`CurrencyFormat`** | `lib/utils/currency_format.dart` | All price displays, cards, keypad, and donut chart | `NumberFormat` localization | `test/unit/currency_format_test.dart` |
| **`SupabaseService`** | `lib/services/supabase_service.dart` | `ExpenseProvider` | Supabase Client, Auth, Storage, RLS | Covered via mock provider tests |

---

## 🧪 3. Unit Test Coverage Matrix

Every module in Fin Sail is mapped to automated unit tests:

| Module / Area | Test File | Coverage Details | Verification Command |
| :--- | :--- | :--- | :--- |
| **Categories** | `test/unit/category_model_test.dart` | 10 default categories, vibrant color defaults, hex parsing, color fallback, vector icon resolution, `toJson`/`fromJson` | `flutter test test/unit/category_model_test.dart` |
| **Currencies & Formats** | `test/unit/currency_format_test.dart` | IDR (`Rp 1.152.000`), USD (`$1,152.00`), EUR, GBP, zero amounts, negative numbers | `flutter test test/unit/currency_format_test.dart` |
| **Transactions & Receipts** | `test/unit/transaction_model_test.dart` | Expense transaction serialization, receipt flags, itemized line items list, confidence calculation | `flutter test test/unit/transaction_model_test.dart` |
| **Expense State & Providers** | `test/unit/expense_provider_test.dart` | Mock data seeding, month-over-month trend % delta, add/edit/delete transactions, custom category creation & default protection | `flutter test test/unit/expense_provider_test.dart` |
| **App Smoke Test** | `test/widget_test.dart` | Material app bootstrap & theme initialization | `flutter test test/widget_test.dart` |

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
