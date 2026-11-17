#!/usr/bin/env bash
# See 3D models before using them: renders every model in a folder as labelled pages
# (12 per page) and saves one PNG per page in .godot/previews/<folder>/.
# Needs a display (briefly opens a window).
#   scripts/assets/preview.sh res://assets/kenney/3d-platformer-kit
#   scripts/assets/preview.sh res://assets/local/synty/PolygonStarter
# For 2D sprites use the create-game-assets skill's build_preview_sheet.py instead.
set -euo pipefail
cd "$(dirname "$0")/../.."
GODOT="${GODOT_BIN:-$(command -v godot || command -v godot4)}"
FOLDER="${1:?usage: preview.sh res://folder [per_page]}"
PER_PAGE="${2:-12}"
OUT=".godot/previews/$(basename "$FOLDER")"
rm -rf "$OUT" && mkdir -p "$OUT/raw"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --path . --write-movie "$OUT/raw/f.png" --fixed-fps 30 --resolution 1280x720 \
	res://kit/tools/model_gallery.tscn -- "--gallery=$FOLDER" "--per-page=$PER_PAGE" >"$OUT/run.log" 2>&1 || true
# Keep the last frame of each 20-frame page (models finished loading, shadows settled).
n=$(ls "$OUT"/raw/*.png 2>/dev/null | wc -l)
p=1
for ((i = 19; i < n; i += 20)); do
	f=$(ls "$OUT"/raw/*.png | sort | sed -n "$((i + 1))p")
	cp "$f" "$OUT/page_$(printf '%02d' $p).png"
	p=$((p + 1))
done
rm -rf "$OUT/raw"
grep -E "model_gallery:|ERROR|SCRIPT ERROR" "$OUT/run.log" | grep -v "leaked\|still in use\|PagedAllocator\|RID alloc" || true
echo "$((p - 1)) page images in $OUT"
