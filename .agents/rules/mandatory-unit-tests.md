# 🧪 Rule: Mandatory Automated Unit Testing

> **Scope**: All repository modifications, features, refactors, and bug fixes in Fin Sail.  
> **Enforcement**: Hard Requirement (`flutter test` must pass 100%).

---

## 📌 1. Policy Overview

Every code update to Fin Sail **MUST** include automated unit tests. No task or pull request is complete without accompanying unit tests verifying the changed logic.

---

## 🎯 2. Target Test Scope: Pure Unit Tests

The primary test scope for this repository is **Unit Testing** in `test/unit/`:
- **Fast & Deterministic**: Runs in milliseconds without launching headless Chrome or mobile emulators.
- **Isolated Logic**: Directly verifies state changes, formulas, serializers, filters, and validators.

### What MUST Be Covered by Unit Tests:
1. **Data Models (`lib/models/`)**:
   - `toJson()` and `fromJson()` serialization/deserialization.
   - Default values and null-safety fallbacks.
   - Color resolution (`CategoryModel.getDefaultColorForName`, color fallback logic).
   - Icon resolution (`CategoryModel.getIconForName`, custom icon lookup).
   - Itemized receipt breakdown (`ReceiptData`, `ReceiptItem`).
2. **Utilities & Formatters (`lib/utils/`)**:
   - Currency formatting for IDR, USD, EUR, GBP (`CurrencyFormat.format`).
   - Thousands separators and numeric sanitizers.
   - Date range validation (enforcing `<=` today).
3. **State Providers (`lib/providers/`)**:
   - Transaction additions, updates, and removals (`ExpenseProvider`).
   - Custom category creation and default category deletion safeguards.
   - Percentage distribution and month-over-month trend calculations (`getCategoryChangeVsLastMonth`).
   - Filter logic (date range, category filter, receipts-only filter, search query).
4. **Bug Fixes (Regression Prevention)**:
   - Every bug fix **MUST** have a unit test reproducing the condition and asserting the correct behavior.

---

## ⚙️ 3. Execution & Verification Standard

Before declaring any task complete:

```bash
# 1. Ensure zero lint/syntax warnings
$HOME/flutter/bin/flutter analyze

# 2. Run all unit and widget tests
$HOME/flutter/bin/flutter test
```

A task **CANNOT** be delivered if any test fails or if no unit test was added for a newly introduced feature.
