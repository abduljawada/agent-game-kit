# Agent Game Kit

A Godot 4.7 starter project for games written mostly by a coding agent
(Claude Code, Codex). It gives the agent tested building blocks, rules that stop
it from rewriting them, and a way to check its own work.

## What's inside

- `kit/`: player controllers (platformer, top-down), health, hitboxes, pickups,
  interactables, dialogue triggers, checkpoints, kill zones, a patrol/chase enemy,
  menus, pause, options, HUD, save slots. See `docs/KIT.md`.
- `addons/`: Phantom Camera, Dialogue Manager, GLoot, LimboAI, gdUnit4, Godot AI (MCP).
- `assets/`: Kenney CC0 starter packs (pixel platformer tiles and characters, UI, fonts,
  sound effects, jingles, a 3D platformer kit), a catalog of ~250 more, and import scripts
  for Kenney and Synty packs. See `assets/README.md`.
- `example/`: a small level built from a text layout with Kenney art and sound.
- `tests/`: 26 gdUnit4 tests, including play tests of the example level with simulated input.
- `AGENTS.md` / `CLAUDE.md`: the rules the agent follows.
- `scripts/check.sh`: the single "is it done?" command.
- `scripts/record.sh`: records a scene, optionally driven by a scripted input timeline (`--inputs`), to frames + a contact sheet so the agent can watch real play.
- `scripts/api.sh`: version-exact API lookup for Godot, LimboAI, the addons and `kit/` (built from the installed binary + official docs at its exact commit).

## First-time setup

1. Open the project in the Godot 4.7 editor once (it imports assets and enables plugins).
2. Connect the MCP server so the agent can run and see the game:
   - Needs [uv](https://docs.astral.sh/uv/) installed.
   - In the editor: **Editor → Editor Settings → Plugins → `godot_ai/mcp_client_scope`** → `project`.
   - In the **Godot AI** dock, press **Configure** next to Claude Code (and/or Codex).
     This writes `.mcp.json` in the project. Then run `claude` in this folder once and approve the server.
   - Telemetry: Godot AI sends anonymous usage events by default. Turn it off in the dock,
     or launch Godot with `GODOT_AI_DISABLE_TELEMETRY=true`, then press **Configure** again.
3. Blender MCP (for agent-made 3D models): Blender plus the "MCP for Blender" add-on, with
   the server declared in `.mcp.json` (pinned version, telemetry off, safe mode on). Open
   Blender before asking the agent to model something. For Codex, run
   `codex mcp add blender --env DISABLE_TELEMETRY=true -- uvx mcp-for-blender==2.3.0`.
4. Local asset sources: create `assets/local/sources.cfg` with
   `[sources]` `kenney_zip = <path to the Kenney All-in-1 zip>` and
   `synty_dir = <folder with your Synty packs>`, then use `scripts/assets/kenney.py` and
   `scripts/assets/synty.py`. Synty files stay in the git-ignored `assets/local/`.
5. Run `scripts/check.sh`. It should end with `ALL CHECKS PASSED`.

## Working with an agent

Open the agent in this folder and describe the game. Good first prompts:

- "Read AGENTS.md and docs/KIT.md, then propose how to build a <genre> game about <idea> from these parts. List anything the kit lacks."
- "Make level 2: <description>. Copy test_example_level.gd for it."
- "The jump feels floaty. Make a new profile with faster falls and show me the numbers you changed."

Without the MCP server the agent can still build and test headless; it just can't see the game.

## Starting a new game

```bash
scripts/new_game.sh "My Game"            # -> ~/Work/my-game, private GitHub repo
scripts/new_game.sh "My Game" ~/code/x --github none --synty PolygonStarter --check
```

It clones the kit (with its history), names the project, adds `GAME.md` for the game's
design and agent rules, copies your local asset sources, makes the first commit and
creates the game's own GitHub repo. The kit stays linked as the `kit` remote:

```bash
git fetch kit && git merge kit/main      # pull kit improvements into the game
```

Keep game code out of `kit/`, `addons/` and `scripts/`, and game rules in `GAME.md`
rather than `AGENTS.md`, so those merges stay conflict-free. Point `Game.first_level`
at your first level and delete `example/` (and its tests) once you no longer need it.

## Licences

Kit code is MIT licensed (see `LICENSE`; third-party details in `THIRD_PARTY_NOTICES.md`). Addons keep their own MIT licences in
`addons/*/`, and the vendored skills in `.agents/skills/` are Apache-2.0.
