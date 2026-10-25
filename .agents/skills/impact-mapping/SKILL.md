---
name: impact-mapping
description: >-
  Guides the agent to analyze downstream dependencies and update the repository impact map.
  Use before planning changes to assess ripple effects and after implementing updates
  to keep IMPACT-MAPPING.md and Graphify artifacts synchronized.
---

# 🗺️ Impact Mapping & Dependency Tracing Skill

This skill ensures that no code is modified in isolation. Every component in Fin Sail is mapped to its dependent screens, providers, models, database schemas, and unit tests.

---

## 📌 Procedure: Two-Way Impact Synchronization

### Step 1: Pre-Change Impact Assessment (Before Writing Code)
Before drafting a plan or modifying code:
1. Open and consult [IMPACT-MAPPING.md](../../../IMPACT-MAPPING.md).
2. Trace the target file/component through the graph:
   - What UI Screens rely on this?
   - Does this touch `ExpenseProvider`?
   - Does this alter any database column or RLS policy in Supabase?
   - Which unit tests in `test/unit/` cover this component?
3. Document the downstream blast radius in the implementation plan under **Impact Mapping Trace**.

---

### Step 2: Post-Change Realization (After Writing Code)
Whenever updates are completed:
1. **Update `IMPACT-MAPPING.md`**:
   - If a new screen, widget, provider method, model, or unit test was added, insert the new node and connections into the Mermaid diagram.
   - Update the **Component & Impact Matrix** table.
   - Update the **Unit Test Coverage Matrix**.
2. **Run Graphify Tool**:
   Execute the automated AST mapper:
   ```bash
   bash .agents/skills/impact-mapping/scripts/run_graphify.sh
   ```
   This generates fresh interactive graph artifacts in `graphify-out/`:
   - `graph.html`: Interactive dependency visualizer.
   - `graph.json`: Machine-queryable graph data.
   - `GRAPH_REPORT.md`: Architecture cluster summary.

---

## 🛠️ Graphify Helper Command
To manually run Graphify at any time:
```bash
bash .agents/skills/impact-mapping/scripts/run_graphify.sh
```
