#!/usr/bin/env bash
# Starts a new game from this kit, keeping the kit linked for future updates.
#
#   scripts/new_game.sh "My Game" [target-dir] [--github private|public|none] [--synty Pack,Pack] [--check]
#
# - Clones this kit (including unpushed commits) into target-dir (default ~/Work/<slug>).
# - Renames remotes: `kit` = the kit on GitHub (pull updates with `git fetch kit && git merge kit/main`),
#   `origin` = the game's own repo (created with gh unless --github none; default private).
# - Sets the project name, adds GAME.md for game-specific design and agent rules,
#   copies assets/local/sources.cfg and, with --synty, copies those Synty packs.
# - Makes the first commit. --check also runs scripts/check.sh in the new game.
set -euo pipefail
KIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

NAME="" TARGET="" GITHUB="private" SYNTY="" CHECK=0
while [ $# -gt 0 ]; do
	case "$1" in
		--github) GITHUB="$2"; shift 2 ;;
		--synty) SYNTY="$2"; shift 2 ;;
		--check) CHECK=1; shift ;;
		-h|--help) sed -n '2,13p' "$0"; exit 0 ;;
		*) if [ -z "$NAME" ]; then NAME="$1"; elif [ -z "$TARGET" ]; then TARGET="$1"; else echo "Unexpected argument: $1"; exit 2; fi; shift ;;
	esac
done
[ -n "$NAME" ] || { sed -n '2,13p' "$0"; exit 2; }
case "$GITHUB" in private|public|none) ;; *) echo "--github must be private, public or none"; exit 2 ;; esac
SLUG=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')
TARGET="${TARGET:-$HOME/Work/$SLUG}"
[ -e "$TARGET" ] && { echo "$TARGET already exists"; exit 1; }

KIT_URL=$(git -C "$KIT_DIR" remote get-url origin 2>/dev/null || git -C "$KIT_DIR" remote get-url kit 2>/dev/null || echo "")
if [ -n "$(git -C "$KIT_DIR" status --porcelain)" ]; then
	echo "Note: the kit has uncommitted changes; they are NOT included (only committed work is cloned)."
fi
AHEAD=$(git -C "$KIT_DIR" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
[ "$AHEAD" != "0" ] && echo "Note: the kit is $AHEAD commit(s) ahead of GitHub; push it so 'git fetch kit' can see them."

echo "== Cloning the kit into $TARGET"
git clone -q "$KIT_DIR" "$TARGET"
cd "$TARGET"
git remote remove origin
[ -n "$KIT_URL" ] && git remote add kit "$KIT_URL"
KIT_SHA=$(git rev-parse --short HEAD)

echo "== Naming the project \"$NAME\""
python3 -I - "$NAME" <<'EOF'
import re, sys
name = sys.argv[1]
s = open("project.godot").read()
s = re.sub(r'^config/name=".*"$', f'config/name="{name}"', s, flags=re.M)
s = re.sub(r'^config/description=".*"$', f'config/description="{name}, built on the Agent Game Kit."', s, flags=re.M)
open("project.godot", "w").write(s)
EOF

cat > GAME.md <<EOF
# $NAME

Game-specific design and rules. Agents read this after AGENTS.md: for design questions
this file wins; for how to use the kit, AGENTS.md wins. Keep it short and current.

## Pitch
One or two sentences: what the player does and why it is fun. (TODO)

## Pillars
- (TODO: 2-3 things every feature must serve)

## Controls
Default kit actions (move, jump, interact, attack, pause) unless listed here.

## Art direction
Packs in use and the look (see assets/README.md and the create-game-assets skill). (TODO)

## Levels
| Scene | Layout | Timeline | Status |
|---|---|---|---|
| (TODO) | | | |

## Rules for agents in this game
- (TODO: anything specific, e.g. "no combat", "top-down only")
EOF

if [ -f "$KIT_DIR/assets/local/sources.cfg" ]; then
	mkdir -p assets/local && cp "$KIT_DIR/assets/local/sources.cfg" assets/local/
	echo "== Copied assets/local/sources.cfg"
fi
if [ -n "$SYNTY" ]; then
	echo "== Copying Synty packs: $SYNTY"
	IFS=',' read -ra PACKS <<<"$SYNTY"
	python3 -I scripts/assets/synty.py add "${PACKS[@]}"
fi

git add -A
git commit -q -m "Start $NAME from Agent Game Kit $KIT_SHA"
echo "== First commit: $(git log --oneline -1)"

if [ "$GITHUB" != "none" ]; then
	echo "== Creating $GITHUB GitHub repo $SLUG"
	gh repo create "$SLUG" "--$GITHUB" --source . --remote origin --push
fi

if [ $CHECK -eq 1 ]; then
	scripts/check.sh
fi

cat <<EOF

Done: $TARGET
Next:
  1. Open it in Godot 4.7 once (or run scripts/check.sh) so assets import.
  2. Fill in GAME.md (pitch, pillars, art direction), then describe the game to your agent.
  3. Point Game.first_level (kit/core/game.gd) at your first level; keep example/ as a reference until then.
  4. Kit updates later: git fetch kit && git merge kit/main
EOF
