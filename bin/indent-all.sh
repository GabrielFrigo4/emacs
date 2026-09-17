#!/usr/bin/env sh
# ----------------------------------------------------------------
# Utility: Emacs Configuration Auto-Indenter
# ----------------------------------------------------------------
set -eu

_dir="$(cd "$(dirname "$0")" && pwd)"
if command -v emacs > "/dev/null" 2>&1; then
	emacs --batch -l "${_dir}/indent-all.el"
else
	echo "⚠️  Emacs binary not found in PATH." >&2
	exit 1
fi
