# Kit reference

Everything in `kit/` is reusable across games. `example/` is a demo level that
uses all of it; copy its patterns, then delete it when your game no longer needs it.

## Autoloads

| Name | File | What it does |
|---|---|---|
| `KitInput` | `kit/core/kit_input.gd` | Registers default actions: `move_left/right/up/down`, `jump`, `interact`, `attack`, `pause`. Edit `DEFAULT_ACTIONS`. |
| `Settings` | `kit/core/settings.gd` | `master_volume`, `fullscreen`; `save_settings()` writes `user://settings.cfg`. |
| `Game` | `kit/core/game.gd` | `change_scene(path)`, `start_new_game()`, `to_main_menu()`, `set_paused()`, `toggle_pause()`, `flags` dict, `set_respawn_point()`. Set `first_level`. |
| `SaveSystem` | `kit/core/save_system.gd` | `save_slot(i)`, `load_slot(i)`, `has_slot(i)`, `delete_slot(i)`. Saves `Game.flags` and every node in group `persist` that has `save_state()`/`load_state()`; id = `persist_id` property or meta, else node path. |
| `InputPlayback` | `kit/core/input_playback.gd` | Replays an input timeline (`play(events)`, `load_timeline(path)`, `stop()`, `playing`, `time`, signal `finished`). Starts itself when launched with `-- --input-timeline=res://x.json` (what `scripts/record.sh --inputs` does). Shows a `t=… actions` overlay while playing. |
| `Audio` | `kit/core/audio.gd` | `play(stream, volume_db, pitch_jitter)` one-shots on the SFX bus, `play_music(stream, fade)` crossfading loops on the Music bus, `set_bus_volume(bus, linear)`. Creates the buses if missing. |
| `DialogueManager` | addon | `show_dialogue_balloon(resource, cue)`, signals `dialogue_started/ended`. |
| `PhantomCameraManager` | addon | Tracks Phantom Cameras. |

## Player

- **`PlatformerController2D`** (`CharacterBody2D`): `profile`, `input_enabled`, action names,
  `facing`, signals `jumped`, `landed`, `interacted(target)`, `respawn(fallback)`.
  Disables input automatically while dialogue is open. Extend it for game logic.
- **`PlatformerProfile`** (Resource): `max_speed`, ground/air accel and decel,
  `jump_height` (px), `time_to_apex`, `time_to_land` (s), `jump_cut`, `max_fall_speed`,
  `coyote_time`, `jump_buffer`, `air_jumps`. Duplicate `default_platformer_profile.tres` per character.
- **`PlatformerMotor`** (RefCounted): the pure movement maths. `step(delta, axis, pressed, held, on_floor) -> velocity`.
  All feel changes go here, with tests in `tests/test_platformer_motor.gd`.
- **`TopDownController2D`**: `max_speed`, `acceleration`, `friction`, `facing`, `step_velocity()`.

## Mechanics (`kit/mechanics/`)

| Class | Base | Use |
|---|---|---|
| `Health` | Node | `max_health`, `invulnerability_time`, `damage(n, source)`, `heal(n)`, `revive()`, signals `changed`, `damaged`, `healed`, `died`. |
| `Hitbox` | Area2D | `damage`, `knockback`, `active`. Put on hazards, enemies, attacks. |
| `Hurtbox` | Area2D | `health` (NodePath to a Health). Applies damage + knockback. |
| `Pickup` | Area2D | `item_id` (protoset id), `amount`, `heal_amount`. Static `find_inventory(node)`, `count(inventory, id)`. |
| `Interactable` | Area2D | `prompt`, `enabled`, signal `interacted(by)`; override `_on_interact(by)`. |
| `DialogueTrigger` | Interactable | `dialogue` (.dialogue resource), `cue`, `one_shot`, `close()`. |
| `Checkpoint` | Area2D | Sets `Game` respawn point on touch. |
| `KillZone` | Area2D | `damage`, `fallback_spawn` (Marker2D). Respawns the player, frees other bodies. |

## Levels (`kit/level/`)

- **`AsciiTileMapLayer`** (`TileMapLayer`): builds tiles and entities from a text layout
  (`layout_file`, one char per tile, `;` lines are comments). Legend dictionaries:
  `solids` (char → `top/top_left/top_right/single/fill*/bottom*` atlas coords, picked from
  neighbours), `rows` (char → `left/middle/right/single`, e.g. planks), `tiles` (char →
  atlas coords), `entities` (char → PackedScene, spawned as `<Scene><n>` under
  `entity_parent`), `markers` (char → NodePath of an existing node moved onto the cell).
  Helpers: `cells_of(char)`, `cell_floor_position(cell)`, signal `built`, and a
  "Rebuild from layout" button in the inspector. Example: `example/level_01.txt`.

## AI (`kit/ai/`)

- **`PatrolChaseEnemy2D`** (`CharacterBody2D`): `patrol_speed`, `chase_speed`, `sight_range`,
  `lose_range`, `target_group`. Builds a `LimboHSM` with `Patrol` and `Chase` states
  (`kit/ai/states/`). Optional `FloorProbe` RayCast2D turns it at ledges; `Health` child frees it on death.
  `current_state_name()` for tests. New behaviours: add a `LimboState` script and a transition in `_build_hsm()`.
- For complex AI use LimboAI behaviour trees: a `BTPlayer` node with a `BehaviorTree` resource,
  edited in the LimboAI editor or written as `.tres`.

## Tools and importers

- **`kit/tools/model_gallery.tscn`**: shows every 3D model in a folder as labelled pages;
  `scripts/assets/preview.sh res://folder` records one PNG per page.
- **`kit/importers/model_post_import.gd`**: project-wide 3D post-import step
  (`[importer_defaults]` in `project.godot`). Gives Synty FBX models their texture atlas;
  other models pass through.
- **`kit/ui/kit_theme.tres`**: project theme using the Kenney Pixel font.

## UI (`kit/ui/`)

`main_menu.tscn` (New Game, Continue, Options, Quit), `pause_menu.tscn` (drop into a level),
`options_menu.tscn`, `hud.tscn` (`player`, `counted_item`). All buttons have unique names
(`%PlayButton` etc.) so tests and MCP tools can find them.

## Addons (pinned versions)

| Addon | Version | Docs |
|---|---|---|
| Phantom Camera | v0.12 | https://phantom-camera.dev |
| Dialogue Manager | v4.2.0 | https://github.com/nathanhoad/godot_dialogue_manager/tree/main/docs |
| GLoot | v3.0.2 | https://github.com/peter-kish/gloot/tree/master/docs |
| LimboAI (GDExtension) | v1.8.1 | https://limboai.readthedocs.io |
| gdUnit4 | v6.2.3 | https://godot-gdunit-labs.github.io/gdUnit4 |
| Godot AI (MCP) | v4.4.2 | https://github.com/hi-godot/godot-ai/blob/main/docs/TOOLS.md |

Update Godot AI with the **Update** button in its dock, never by unzipping over it.
