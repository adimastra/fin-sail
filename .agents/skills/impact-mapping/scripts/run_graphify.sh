#!/usr/bin/env bash
set -e

# ==============================================================================
# Fin Sail — Automated AST & Dependency Graph Generator (Graphify)
# ==============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$REPO_ROOT"

export PATH="/Library/Frameworks/Python.framework/Versions/3.12/bin:$HOME/Library/Python/3.12/bin:$PATH"

echo "⛵ [Graphify] Scanning repository at: $REPO_ROOT"

# Ensure pip3/python3 exists
if ! command -v python3 &>/dev/null; then
  echo "❌ Error: python3 is required to run Graphify."
  exit 1
fi

# Check if graphify CLI is available, install if missing
if ! command -v graphify &>/dev/null; then
  echo "📦 Installing graphifyy via pip3..."
  python3 -m pip install --quiet --upgrade graphifyy || {
    echo "⚠️ Warning: Failed to install graphifyy globally, trying user space..."
    python3 -m pip install --user --quiet --upgrade graphifyy
  }
fi

OUTPUT_DIR="$REPO_ROOT/graphify-out"
mkdir -p "$OUTPUT_DIR"

echo "🔍 Running Graphify AST analysis..."
graphify extract . --code-only --output "$REPO_ROOT" || python3 -m graphify extract . --code-only --output "$REPO_ROOT"

echo "📊 Generating interactive visual maps and Mermaid call flows..."
graphify export html 2>/dev/null || true
graphify tree 2>/dev/null || true
graphify export callflow-html 2>/dev/null || true

echo "✅ [Graphify] Complete! Artifacts located in: $OUTPUT_DIR"
echo "   - Interactive 2D/3D Map: file://$OUTPUT_DIR/graph.html"
echo "   - Call-Flow & Mermaid Architecture: file://$OUTPUT_DIR/fin-logs-callflow.html"
echo "   - Collapsible Tree Explorer: file://$OUTPUT_DIR/GRAPH_TREE.html"
echo "   - Graph AST Dataset: file://$OUTPUT_DIR/graph.json"
