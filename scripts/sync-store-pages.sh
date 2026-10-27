#!/bin/zsh
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$project_root/docs"
cp "$project_root/Store/privacy.html" "$project_root/docs/privacy.html"
cp "$project_root/Store/support.html" "$project_root/docs/support.html"
