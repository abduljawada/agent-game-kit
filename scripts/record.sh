#!/usr/bin/env bash
# Records a scene to PNG frames with Godot's Movie Maker so the agent can see what
# actually happens at runtime (GameDevBench found runtime video lifted Claude Sonnet
# 4.5 from 33% to 48% on Godot tasks). Needs a display (not --headless); it briefly
# opens a game window.
#
#   scripts/record.sh <res://scene.tscn> [seconds=4] [keep_every_nth_frame=10] [--inputs res://timeline.json]
#
# --inputs replays a scripted input timeline (see kit/core/input_playback.gd) so the
# frames show real play: running, jumping, talking. Each frame shows "t=<s> <held actions>".
# Output: .godot/recordings/<scene>/frame_*.png and contact.png (needs ImageMagick).
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT_BIN:-$(command -v godot || command -v godot4)}"

INPUTS=""
POS=()
while [ $# -gt 0 ]; do
	case "$1" in
		--inputs) INPUTS="$2"; shift 2 ;;
		*) POS+=("$1"); shift ;;
	esac
done
SCENE="${POS[0]:-res://example/level_01.tscn}"
SECONDS_TO_RECORD="${POS[1]:-4}"
KEEP_EVERY="${POS[2]:-10}"
FPS=30
NAME=$(basename "$SCENE" .tscn)
[ -n "$INPUTS" ] && NAME="$NAME-$(basename "$INPUTS" .json)"
OUT=".godot/recordings/$NAME"
rm -rf "$OUT" && mkdir -p "$OUT/raw"

USER_ARGS=()
if [ -n "$INPUTS" ]; then
	[[ "$INPUTS" == res://* ]] || INPUTS="res://${INPUTS#./}"
	USER_ARGS=(-- "--input-timeline=$INPUTS")
fi
LOG="$OUT/run.log"
"$GODOT" --path . --write-movie "$OUT/raw/frame.png" --fixed-fps $FPS \
	--quit-after $((SECONDS_TO_RECORD * FPS)) "$SCENE" "${USER_ARGS[@]}" >"$LOG" 2>&1 || true

i=0
for f in $(ls "$OUT"/raw/frame*.png 2>/dev/null | sort); do
	if [ $((i % KEEP_EVERY)) -eq 0 ]; then cp "$f" "$OUT/$(basename "$f")"; fi
	i=$((i + 1))
done
rm -rf "$OUT/raw"
kept=$(ls "$OUT"/frame*.png 2>/dev/null | wc -l)
if [ "$kept" -eq 0 ]; then echo "No frames recorded (is a display available?). Log: $LOG"; exit 1; fi
if command -v montage >/dev/null; then
	montage "$OUT"/frame*.png -tile 4x -geometry 480x270+4+4 "$OUT/contact.png" 2>/dev/null &&
		echo "contact sheet: $OUT/contact.png"
fi
errs=$(grep -E "SCRIPT ERROR|^ERROR" "$LOG" | grep -v "leaked\|still in use\|PagedAllocator\|RID alloc" || true)
[ -n "$errs" ] && { echo "Errors during recording:"; echo "$errs"; }
echo "$kept frames (every ${KEEP_EVERY}th at ${FPS} fps = one per $(awk "BEGIN{print $KEEP_EVERY/$FPS}") s) in $OUT"
