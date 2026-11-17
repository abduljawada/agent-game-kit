#!/usr/bin/env bash
# One command for agents and CI: import, path/uid and compile checks, smoke-run every
# level, run all tests.
# Exit code is non-zero on any script error or failing test.
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT_BIN:-$(command -v godot || command -v godot4)}"
[ -x "$GODOT" ] || { echo "Godot not found. Set GODOT_BIN."; exit 2; }

NOISE='_try_connect|Remote Debugger|remote port|Capture not registered|leaked at exit|still in use at exit|PagedAllocator|RID allocations|^\s+at: (cleanup|clear|~PagedAllocator|~RID_Alloc)'
fail=0

echo "== import"
# A fresh clone's first import can log load-order errors (e.g. the theme font before it
# is imported), so import once to build the cache, then check a second, clean import.
[ -d .godot/imported ] || "$GODOT" --headless --path . --import >/dev/null 2>&1
out=$("$GODOT" --headless --path . --import 2>&1)
if echo "$out" | grep -E "SCRIPT ERROR|Parse Error|ERROR: Failed" | grep -Ev "$NOISE"; then fail=1; fi

SKILLS=.agents/skills
if [ -f "$SKILLS/godot-nodes-scenes/scripts/check_godot_project.py" ]; then
	echo "== res:// paths, uids and scene structure (godot-nodes-scenes skill)"
	# Errors anywhere fail the check. Warnings are shown only outside addons/, which
	# carry a few harmless upstream ones (stale uids in addon example scenes).
	out=$(python3 -I "$SKILLS/godot-nodes-scenes/scripts/check_godot_project.py" . 2>&1)
	status=$?
	echo "$out" | grep -E "^(ERROR|WARNING) " | grep -Ev "^WARNING addons/" -A1
	echo "$out" | grep -E "^Summary:"
	[ $status -eq 0 ] || fail=1
fi

if [ -f "$SKILLS/godot-gdscript/assets/check_scripts_compile.gd" ]; then
	echo "== every GDScript file compiles (godot-gdscript skill)"
	out=$("$GODOT" --headless --path . --script "$PWD/$SKILLS/godot-gdscript/assets/check_scripts_compile.gd" 2>&1)
	status=$?
	echo "$out" | grep -E "^BROKEN|Parse Error|SCRIPT ERROR|scripts checked" | grep -Ev "$NOISE"
	[ $status -eq 0 ] || fail=1
fi

echo "== smoke run scenes (3 s each)"
for scene in kit/ui/main_menu.tscn $(ls example/*.tscn levels/*.tscn 2>/dev/null | grep -i level); do
	out=$("$GODOT" --headless --path . "res://$scene" --quit-after 180 2>&1)
	errs=$(echo "$out" | grep -E "ERROR|SCRIPT ERROR|WARNING" | grep -Ev "$NOISE")
	if [ -n "$errs" ]; then echo "-- $scene"; echo "$errs"; fail=1; else echo "ok  $scene"; fi
done

echo "== tests"
"$GODOT" --headless --path . -s -d --remote-debug tcp://127.0.0.1:1 \
	res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode -c 2>&1 \
	| sed 's/\x1b\[[0-9;]*m//g' | grep -Ev "$NOISE" \
	| grep -E "FAILED|ERROR|SCRIPT|Expecting|but (is|was)| at '|orphan|Overall Summary"
test_status=${PIPESTATUS[0]}
"$GODOT" --headless --path . --quiet -s res://addons/gdUnit4/bin/GdUnitCopyLog.gd >/dev/null 2>&1
[ "$test_status" -eq 0 ] || fail=1

if [ $fail -eq 0 ]; then echo "== ALL CHECKS PASSED"; else echo "== CHECKS FAILED"; fi
exit $fail
