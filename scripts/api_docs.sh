#!/usr/bin/env bash
# Builds a version-exact API reference from the Godot binary and this project's code:
#   .godot/api/engine/   every engine class + GDExtensions (LimboAI) for the installed Godot
#   .godot/api/project/  classes from kit/, example/ and the GDScript addons (doc comments)
# Rebuilds only when the Godot version, addon versions or project scripts changed.
# Usage: scripts/api_docs.sh [--force]. Agents normally just call scripts/api.sh,
# which runs this automatically when needed.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT_BIN:-$(command -v godot || command -v godot4)}"
OUT=.godot/api

stamp() {
	"$GODOT" --version
	cat addons/*/plugin.cfg addons/limboai/version.txt 2>/dev/null | grep -i "version"
	find kit example -name '*.gd' -newer "$OUT/engine" -print 2>/dev/null | head -1
}

if [ "${1:-}" != "--force" ] && [ -f "$OUT/STAMP" ] && [ "$(stamp)" == "$(cat "$OUT/STAMP")" ]; then
	exit 0
fi

rm -rf "$OUT" && mkdir -p "$OUT/engine" "$OUT/project"
VERSION=$("$GODOT" --version)
echo "Building Godot API reference ($VERSION)..." >&2

# Descriptions: --doctool only knows signatures, so start from the official class XML at
# the exact commit the binary was built from (cached per commit), then let --doctool
# merge in the binary's real signatures and GDExtension classes.
COMMIT=$(echo "$VERSION" | awk -F. '{print $NF}')
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/godot-class-docs/$COMMIT"
if [[ "$COMMIT" =~ ^[0-9a-f]{7,40}$ ]] && [ ! -d "$CACHE/doc/classes" ]; then
	echo "Fetching class descriptions for Godot commit $COMMIT (once per engine version)..." >&2
	TMP=$(mktemp -d)
	if (cd "$TMP" && git init -q && git remote add origin https://github.com/godotengine/godot.git &&
		git sparse-checkout set --no-cone '/doc/classes/' '/modules/*/doc_classes/' '/platform/*/doc_classes/' &&
		FULL=$(git ls-remote origin 'refs/tags/*' | awk -v c="$COMMIT" 'index($1, c) == 1 {print $1; exit}') &&
		git fetch -q --depth 1 --filter=blob:none origin "${FULL:-$COMMIT}" && git checkout -q FETCH_HEAD) 2>/dev/null; then
		mkdir -p "$CACHE" && cp -r "$TMP"/doc "$TMP"/modules "$TMP"/platform "$CACHE"/
	else
		echo "  (offline or unknown commit: signatures only, no descriptions)" >&2
	fi
	rm -rf "$TMP"
fi
[ -d "$CACHE/doc/classes" ] && cp -r "$CACHE"/doc "$CACHE"/modules "$CACHE"/platform "$OUT/engine/"

# LimboAI (GDExtension) descriptions from its release tag.
LIMBO_TAG=$(tr -d '[:space:]' < addons/limboai/version.txt 2>/dev/null || true)
LCACHE="${XDG_CACHE_HOME:-$HOME/.cache}/godot-class-docs/limboai-$LIMBO_TAG"
if [ -n "$LIMBO_TAG" ] && [ ! -d "$LCACHE" ]; then
	TMP=$(mktemp -d)
	if (cd "$TMP" && git init -q && git remote add origin https://github.com/limbonaut/limboai.git &&
		git sparse-checkout set --no-cone '/doc_classes/' &&
		git fetch -q --depth 1 --filter=blob:none origin "refs/tags/$LIMBO_TAG" && git checkout -q FETCH_HEAD) 2>/dev/null; then
		mkdir -p "$LCACHE" && cp "$TMP"/doc_classes/*.xml "$LCACHE"/
	fi
	rm -rf "$TMP"
fi
[ -d "$LCACHE" ] && mkdir -p "$OUT/engine/modules/limboai/doc_classes" && cp "$LCACHE"/*.xml "$OUT/engine/modules/limboai/doc_classes/"
"$GODOT" --headless --path . --doctool "$OUT/engine" >/dev/null 2>&1 || true
for dir in res://kit res://example res://addons/phantom_camera res://addons/dialogue_manager res://addons/gloot; do
	"$GODOT" --headless --path . --doctool "$OUT/project" --gdscript-docs "$dir" >/dev/null 2>&1 || true
done
stamp >"$OUT/STAMP"
echo "$(find "$OUT/engine" -name '*.xml' | wc -l) engine classes, $(find "$OUT/project" -name '*.xml' | wc -l) project/addon classes in $OUT" >&2
