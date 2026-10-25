---
name: plan-first
description: >-
  Enforces a strict plan-first workflow for any application updates, features, or bug fixes.
  Activates whenever the user requests changes to the application, requiring an approved
  implementation plan covering Product Knowledge and Technical Approach before any code is modified.
---

# 📋 Plan-First Development Workflow

This skill enforces a disciplined engineering methodology: **Plan First, Review, Iterate, Approve, Code, and Test**.

---

## 🚫 The Golden Rule: Do Not Code Before Approval!

> [!CRITICAL]
> When the user asks for a feature, bug fix, or UI change:
> **YOU MUST NOT MODIFY ANY PROJECT SOURCE CODE** until the user has explicitly reviewed and approved your implementation plan.

---

## 🔄 Four-Phase Procedure

### Phase 1: Context Research & Discovery
1. Inspect affected files and models using `view_file` or `grep_search`.
2. Trace downstream dependencies using `IMPACT-MAPPING.md`.
3. Verify existing unit tests under `test/unit/`.

### Phase 2: Draft the Implementation Plan
Create an implementation plan artifact at:
`<Artifact Directory>/plan_<feature_name>.md`
using the structure defined in `templates/plan_template.md`:
1. **Executive Summary & Problem Statement**: Clear explanation of the requirement.
2. **Product Knowledge & UX**:
   - User flows, interactions, edge cases, and backward compatibility.
   - Design tokens: colors, spacing, typography, theme compliance.
3. **Technical Approach**:
   - Affected files and components.
   - State management modifications (`ExpenseProvider`).
   - Database schema or RLS impact.
   - Error handling and defensive code paths.
4. **Automated Unit Testing Plan**:
   - List specific unit tests that will be written in `test/unit/` per `.agents/rules/mandatory-unit-tests.md`.
5. **Impact Mapping Trace**:
   - Note which nodes in `IMPACT-MAPPING.md` will be affected and updated.

Set artifact metadata:
```json
{
  "RequestFeedback": true,
  "UserFacing": true,
  "Summary": "Detailed summary of the proposal"
}
```

### Phase 3: Interactive User Review Loop
1. Present the plan link to the user.
2. Ask for feedback or confirmation.
3. If the user requests modifications or provides feedback:
   - Update the plan artifact accordingly.
   - Re-request feedback.
4. **Wait for explicit approval** (e.g., "Proceed", "Approved", "Go ahead").

### Phase 4: Implementation, Unit Testing & Impact Synchronization
Once approved:
1. Write the code following repository design conventions.
2. Implement automated unit tests in `test/unit/`.
3. Run verification:
   ```bash
   $HOME/flutter/bin/flutter analyze
   $HOME/flutter/bin/flutter test
   ```
4. Update `IMPACT-MAPPING.md` to reflect new components and tests.
5. Create a `walkthrough.md` artifact showing before/after results and test logs.
