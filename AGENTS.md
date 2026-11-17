# Agent rules for this Godot project

This is a game built on the Agent Game Kit (Godot 4.7, GDScript, 2D).
You (the coding agent) write the game; the human directs design and judges feel.
Read this file fully before changing anything. Component reference: `docs/KIT.md`.
If `GAME.md` exists, read it next: it holds this game's design and game-specific rules.
For design questions `GAME.md` wins; for how to use the kit, this file wins. Put
game-specific rules in `GAME.md`, not here, so kit updates merge cleanly.

## 1. Reuse before you write

Never re-implement a system the kit or an addon already provides. Configure,
extend or compose it instead. If something is missing, say so and extend the
existing piece; do not write a parallel version.

| Need | Use | Do NOT write |
|---|---|---|
| Side-view player movement | `PlatformerController2D` + a `PlatformerProfile` `.tres` | your own gravity/jump/coyote code |
| Top-down movement | `TopDownController2D` | a new 8-direction mover |
| Camera follow, framing, shake, zones | Phantom Camera (`PhantomCamera2D` + `PhantomCameraHost` under a `Camera2D`) | camera scripts that set `Camera2D.position` |
| Dialogue, branching, choices | Dialogue Manager `.dialogue` files + `DialogueTrigger` | dialogue arrays in GDScript, custom text boxes |
| Inventory, items, stacks | GLoot `Inventory` + protoset JSON + `Pickup` | item dictionaries, custom inventory classes |
| Enemy / NPC behaviour | LimboAI `LimboHSM` + `LimboState` (see `PatrolChaseEnemy2D`) or behaviour trees (`BTPlayer`) | `match state:` state machines in `_physics_process` |
| HP, damage, i-frames | `Health`, `Hitbox`, `Hurtbox` | `hp` variables on each actor |
| Using things in the world | `Interactable` (extend it) | per-object input checks |
| Respawn, pits | `Checkpoint`, `KillZone` | ad-hoc teleport code |
| Menus, pause, options | `kit/ui/*` | new menu systems |
| Save / load | `SaveSystem` + `persist` group with `save_state()` / `load_state()` | direct `FileAccess` save code |
| Story flags | `Game.flags` (also readable from dialogue) | new global singletons |
| Input bindings | `KitInput.DEFAULT_ACTIONS` | `Input.is_key_pressed(KEY_...)` |
| Level layout | `AsciiTileMapLayer` + a `.txt` layout (see `example/level_01.txt`) | levels built in code, hand-placed platforms |
| Sound effects, music | `Audio.play(stream)`, `Audio.play_music(stream)`; `sound` exports on `Pickup`/`Checkpoint` | `AudioStreamPlayer` nodes per sound |
| Art, models, sounds | existing packs first, see section 4b and `assets/README.md` | new assets when a pack already has one |
| Tests | gdUnit4 in `tests/` | ad-hoc print debugging as proof |

Game-specific code goes in your game's folders (`example/` shows the pattern:
`example/player.gd extends PlatformerController2D`). Edit `kit/` only to fix a
bug or add a reusable feature, and then add a test for it. Never edit `addons/`.

## 2. Don't guess the API

Godot 4 changed many names from Godot 3 (`KinematicBody2D` → `CharacterBody2D`,
`yield` → `await`, `move_and_slide()` takes no arguments, `export` → `@export`).
Before using any engine, LimboAI, addon or kit class or member you have not
checked in this session, look it up. The reference is built from the installed
Godot binary plus the official docs at the exact commit it was built from, so it
always matches this project's versions (it rebuilds itself when Godot, an addon or
a kit script changes):

```bash
scripts/api.sh CharacterBody2D                 # inheritance, properties, method signatures, signals
scripts/api.sh CharacterBody2D move_and_slide  # one member, full description (searches base classes)
scripts/api.sh --search floor_snap             # which classes have a member matching this
scripts/api.sh --inherited Area2D              # include inherited members
```

It covers the engine, LimboAI, Phantom Camera, Dialogue Manager, GLoot and `kit/`.
If the Godot AI MCP server is connected, `api_manage(op="get_class")` gives the same
data live from the running editor's ClassDB. Do not rely on memory or web results
for signatures: they are often Godot 3 or a different 4.x minor version.

## 3. Content is data

Prefer data the human can read and edit over code:
- Movement feel → `PlatformerProfile` `.tres` resources (heights in px, times in s).
- Items → protoset JSON (`example/items.json`): `{ "id": { "name": ..., "max_stack_size": ... } }`.
- Dialogue → `.dialogue` files (`~ cue`, `Name: line`, `- choice`, `do Game.flags["x"] = true`, `=> END`).
- Levels → a text layout read by `AsciiTileMapLayer` (one char per tile; legend on the
  `Tiles` node: `solids`, `rows`, `tiles`, `entities`, `markers`) inside a `.tscn` that holds
  the camera, HUD and unique actors. Entity and marker scenes have their origin at their
  feet so they stand on the tile below. Avoid building levels in code.

## 3b. Editing project settings while the editor is open

The Godot editor reads `project.godot` once at startup. If you add an autoload, input
action or other project setting by editing the file while the editor is open, the editor
won't see it: it shows false "Identifier ... not declared" parse errors, and if it saves
project settings later it can overwrite your change. After such an edit, ask the human to
use **Project → Reload Current Project** (don't change settings in the editor first), then
check `git diff project.godot` to confirm the change survived. Headless runs
(`scripts/check.sh`) always read the file fresh, so they are the source of truth.

## 4. Physics layers

| Layer | Bit value | Who is on it |
|---|---|---|
| 1 `world` | 1 | static level geometry |
| 2 `player` | 2 | player body |
| 3 `enemies` | 4 | enemy bodies |
| 4 `hurts_player` | 8 | enemy and hazard `Hitbox`es |

Player body mask 1. Player `Hurtbox` mask 8. Pickups / interactables / checkpoints mask 2.
`KillZone` mask 6. Enemy `Hitbox` layer 8, mask 0.

## 4b. Assets

Follow `assets/README.md`. In short:
- Use what exists: `assets/kenney/` (CC0, in git), more packs via
  `scripts/assets/kenney.py` (catalog in `assets/kenney/CATALOG.md`), Synty packs via
  `scripts/assets/synty.py` into `assets/local/synty/`.
- **Synty files are licensed for use, not redistribution: they live only in the
  git-ignored `assets/local/`. Never copy them elsewhere, commit, upload or attach them.**
- Look before using: `scripts/assets/preview.sh res://<folder>` for 3D (one PNG per page of
  models), the `create-game-assets` skill's preview/report scripts for 2D.
- New 3D models: build them in Blender through the Blender MCP server (project
  `.mcp.json`; Blender must be open with the "MCP for Blender" add-on, which starts its
  server automatically). Save the `.blend` before running code in Blender, and export
  `.glb` to `assets/models/`. Never call its `set_telemetry_consent` tool. Poly Haven
  downloads are off unless the human asks.
- New 2D art or sound: follow the `create-game-assets` skill and record the source in
  the provenance table in `assets/README.md`. Ask before using any paid service.

## 5. Definition of done

A change is done only when all of these are true:

1. `scripts/check.sh` prints `ALL CHECKS PASSED` (import, every level smoke-run, all gdUnit4 tests, 0 orphans).
2. New mechanics have a test. Movement/feel logic is tested through pure classes
   (like `PlatformerMotor`); scene behaviour through `scene_runner` with simulated
   actions. In scene tests, wait with `await get_tree().physics_frame`, never by
   counting process frames (headless draws frames faster than physics ticks).
3. Look at the running game. Anything visual (layout, camera, animation, UI) is not
   verified until you have seen it:
   - `scripts/record.sh res://path/to/scene.tscn 6 15 --inputs res://path/to/run.json`
     plays the scene with a scripted input timeline and saves frames plus a
     `contact.png` sheet in `.godot/recordings/<scene>-<timeline>/`. Each frame shows
     `t=<seconds>` and the held actions, so you can match frames to the timeline. Open
     the contact sheet and say what you see: did the jump land, did HP drop, was the
     coin collected? (Needs a display; it briefly opens a game window.)
   - Timelines are JSON: `{"events": [{"at": 0.3, "action": "move_right", "hold": 2.0},
     {"at": 1.4, "action": "jump", "hold": 0.35}]}` (`hold` defaults to a 0.1 s tap).
     See `example/demo_run.json`. Keep one per level that plays through its key
     moments, and back it with a test like `tests/test_input_playback.gd` that plays the
     same timeline and asserts the outcome (it prints the trajectory when it fails, which
     is how you retime jumps).
   - If the Godot AI MCP server is connected: run the game (`project_run`), drive it
     with input, take a `game` screenshot (`editor_screenshot`), and read
     `logs_read(source="game")` and `logs_read(source="editor")` for errors.
4. Report to the human what you could not verify (usually: how it *feels* to play).

Never claim something works because the code "looks right".

## 6. Skills

Installed in `.agents/skills/` (Codex) and linked as `.claude/skills/` (Claude Code),
pinned per `.agents/skills/SOURCE.md`. Each loads only when a task needs it:

- `godot-gdscript`: typed GDScript 2.0, `await`, porting Godot 3 code.
- `godot-nodes-scenes`: scene structure, instancing, autoloads, broken `res://`/uid checker.
- `godot-tilemap`: `TileMapLayer`/`TileSet` (the `TileMap` node is deprecated).
- `godot-animation`: `AnimatedSprite2D`, `AnimationPlayer`/`AnimationTree`, tweens.
- `godot-audio`: audio players and buses (the kit's `Audio` autoload sits on top).
- `godot-3d-essentials`: 3D scenes, lights, environment, materials (for Kenney/Synty 3D).
- `create-game-assets`: art direction, consistent asset families, QA and provenance.
- `game-feel`: screen shake, hit-stop, squash and stretch on top of working mechanics.
- `level-design`: layouts measured against the real controller, gating, pacing.

When a skill's advice conflicts with this file (for example writing your own
movement, camera or test runner), this file wins: the kit's components stay.

Load at most 2–3 skills for any one task. Large or many simultaneous skills help less
(SkillsBench), and skills an agent writes for itself made results worse than none. Do
not generate new skills from your own notes unless the human asks and reviews them.

## 7. Ask the human about

Game feel, art direction, difficulty, and anything that changes the design. Do not
ask about implementation details the kit already decides.
