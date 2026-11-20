#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

PYTHON=".venv/bin/python"
if [[ ! -x "$PYTHON" ]]; then
    echo "Python virtual environment not found. Create it with: python -m venv .venv" >&2
    exit 1
fi

"$PYTHON" -m pip install -r requirements.txt
"$PYTHON" -m pytest
