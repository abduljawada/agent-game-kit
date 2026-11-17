#!/usr/bin/env bash
# Version-exact Godot API lookup. Rebuilds the reference first if Godot, an addon or
# project scripts changed. See scripts/api.py --help.
set -euo pipefail
cd "$(dirname "$0")/.."
scripts/api_docs.sh
exec python3 -I scripts/api.py "$@"
