#!/bin/bash
set -e

echo "===================================="
echo " Passivbot Runtime Entrypoint"
echo "===================================="

# ---- Paths ----
PB6_DIR="/app/pb6"
PB7_DIR="/app/pb7"
PBGUI_DIR="/app/pbgui"

PB6_PYTHON="$PB6_DIR/venv/bin/python"
PB7_PYTHON="$PB7_DIR/venv/bin/python"

# ---- Sanity checks ----
echo "[CHECK] PB6 Python:"
$PB6_PYTHON --version

echo "[CHECK] PB7 Python:"
$PB7_PYTHON --version

# Export for PBGUI usage
export PB6_PYTHON
export PB7_PYTHON

# ---- Go to PBGUI ----
cd "$PBGUI_DIR"

echo "[START] PBGUI (Streamlit)"
exec streamlit run pbgui.py \
  --server.port=8507 \
  --server.address=0.0.0.0 \
  --server.enableCORS=false \
  --server.enableXsrfProtection=false
