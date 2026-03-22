#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./compile_final_report.sh
# Optional env:
#   REPORT_TEX=other-file.tex ./compile_final_report.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_TEX="${REPORT_TEX:-final-report.tex}"

if [[ ! -f "$ROOT_DIR/$REPORT_TEX" ]]; then
  echo "[ERROR] Cannot find $REPORT_TEX in $ROOT_DIR"
  exit 1
fi

TEXBIN="/Library/TeX/texbin"
LOCALTEX="$ROOT_DIR/.texlive"
if [[ ! -x "$TEXBIN/xelatex" ]]; then
  echo "[ERROR] XeLaTeX not found at $TEXBIN/xelatex"
  echo "        Install MacTeX first: https://tug.org/mactex/"
  exit 1
fi

echo "==> Step 1/4: Ensure tlmgr is available"
if [[ ! -x "$TEXBIN/tlmgr" ]]; then
  echo "[ERROR] tlmgr not found at $TEXBIN/tlmgr"
  exit 1
fi

echo "==> Step 2/4: Install required TeX packages locally (user tree)"
mkdir -p "$LOCALTEX"
"$TEXBIN/tlmgr" --usermode --usertree "$LOCALTEX" init-usertree || true
"$TEXBIN/tlmgr" --usermode --usertree "$LOCALTEX" \
  option repository https://mirror.kku.ac.th/CTAN/systems/texlive/tlnet
"$TEXBIN/tlmgr" --usermode --usertree "$LOCALTEX" \
  install tex-gyre inconsolata collection-langother || true

echo "==> Step 3/4: Quick font sanity check"
FC_LIST_BIN="$(command -v fc-list || true)"
for f in Laksaman Garuda TlwgTypist "TeX Gyre Termes" Inconsolata; do
  if [[ -n "$FC_LIST_BIN" ]] && "$FC_LIST_BIN" : family | grep -Fqi "$f"; then
    echo "  [OK] $f"
  else
    echo "  [WARN] $f not visible via fc-list (compile may still work if XeTeX can resolve it)"
  fi
done

echo "==> Step 4/4: Compile report"
cd "$ROOT_DIR"
TEXMFHOME="$LOCALTEX" "$TEXBIN/xelatex" -interaction=nonstopmode -halt-on-error "$REPORT_TEX"
TEXMFHOME="$LOCALTEX" "$TEXBIN/xelatex" -interaction=nonstopmode -halt-on-error "$REPORT_TEX"

echo "==> Done"
PDF_OUT="${REPORT_TEX%.tex}.pdf"
if [[ -f "$ROOT_DIR/$PDF_OUT" ]]; then
  echo "Output: $ROOT_DIR/$PDF_OUT"
else
  echo "[WARN] PDF not found at expected path: $ROOT_DIR/$PDF_OUT"
fi
