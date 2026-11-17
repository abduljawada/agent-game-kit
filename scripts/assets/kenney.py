#!/usr/bin/env python3
"""Kenney asset packs (CC0) from the "Kenney Game Assets All-in-1" archive.

  scripts/assets/kenney.py catalog              write assets/kenney/CATALOG.md (every pack in the archive)
  scripts/assets/kenney.py list [filter]        print pack names, e.g. `list platformer`
  scripts/assets/kenney.py add "2D assets/Pixel Platformer" [...]   extract packs into assets/kenney/<slug>/

Only engine-useful files are extracted: PNG/SVG for 2D, GLB/glTF (+ textures) for 3D,
OGG/WAV for audio, TTF/OTF for fonts, plus License.txt and Preview.png. Tool-specific
folders (Construct, Tiled, Unity, FBX/OBJ duplicates, ...) are skipped.
Kenney assets are CC0: they may be committed and shipped freely.

The archive path comes from $KENNEY_ZIP, else assets/local/sources.cfg (key kenney_zip),
else the newest ~/Downloads/Kenney*All-in-1*.zip.
"""
import configparser
import fnmatch
import glob
import os
import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "kenney"
CATEGORIES = ("2D assets", "3D assets", "Audio", "UI assets", "Icons", "Other")
SKIP_DIRS = re.compile(r"/(Construct ?\d*|Tiled|Unity|GameMaker|Scratch|Godot|Defold|FBX format|OBJ format|"
                       r"Vector|Spritesheet|Spritesheets|Previews|Isometric \(vector\))/", re.I)
KEEP_EXT = {".png", ".svg", ".glb", ".gltf", ".bin", ".ogg", ".wav", ".ttf", ".otf"}
ALWAYS = {"license.txt", "preview.png"}


def archive() -> Path:
    if os.environ.get("KENNEY_ZIP"):
        return Path(os.environ["KENNEY_ZIP"]).expanduser()
    cfg = ROOT / "assets" / "local" / "sources.cfg"
    if cfg.exists():
        cp = configparser.ConfigParser()
        cp.read(cfg)
        if cp.has_option("sources", "kenney_zip"):
            return Path(cp.get("sources", "kenney_zip")).expanduser()
    found = sorted(glob.glob(os.path.expanduser("~/Downloads/Kenney*All-in-1*.zip")), key=os.path.getmtime)
    if not found:
        sys.exit("Kenney archive not found. Set KENNEY_ZIP or assets/local/sources.cfg [sources] kenney_zip=...")
    return Path(found[-1])


def packs(z: zipfile.ZipFile) -> dict[str, list[str]]:
    out: dict[str, list[str]] = {}
    for name in z.namelist():
        parts = name.split("/")
        if len(parts) >= 3 and parts[0] in CATEGORIES and parts[1]:
            out.setdefault(f"{parts[0]}/{parts[1]}", []).append(name)
    return out


def slug(pack: str) -> str:
    cat, name = pack.split("/", 1)
    prefix = {"2D assets": "2d", "3D assets": "3d", "Audio": "audio", "UI assets": "ui", "Icons": "icons", "Other": "other"}[cat]
    return prefix + "-" + re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def wanted(member: str) -> bool:
    base = member.rsplit("/", 1)[-1]
    if not base:
        return False
    if base.lower() in ALWAYS:
        return True
    if SKIP_DIRS.search("/" + member):
        return False
    return Path(base).suffix.lower() in KEEP_EXT


def cmd_catalog(z: zipfile.ZipFile) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    lines = ["# Kenney catalog", "",
             f"Every pack in `{archive().name}` (CC0). Extract one with",
             "`scripts/assets/kenney.py add \"<Category>/<Pack>\"`. Extracted packs are marked ✓.", ""]
    by_cat: dict[str, list[str]] = {}
    for p, members in packs(z).items():
        by_cat.setdefault(p.split("/")[0], []).append(p)
    for cat in CATEGORIES:
        if cat not in by_cat:
            continue
        lines.append(f"## {cat}\n")
        for p in sorted(by_cat[cat]):
            mark = " ✓" if (OUT / slug(p)).exists() else ""
            lines.append(f"- {p.split('/', 1)[1]}{mark}")
        lines.append("")
    (OUT / "CATALOG.md").write_text("\n".join(lines))
    print(f"wrote {OUT / 'CATALOG.md'} ({sum(len(v) for v in by_cat.values())} packs)")


def cmd_add(z: zipfile.ZipFile, names: list[str]) -> None:
    all_packs = packs(z)
    for want in names:
        match = [p for p in all_packs if p.lower() == want.lower()] or \
                [p for p in all_packs if p.lower().endswith("/" + want.lower())]
        if not match:
            sys.exit(f"No pack '{want}'. Try: scripts/assets/kenney.py list {want.split('/')[-1].split()[0]}")
        pack = match[0]
        dest = OUT / slug(pack)
        n = size = 0
        for member in all_packs[pack]:
            if not wanted(member):
                continue
            rel = member.split("/", 2)[2]
            target = dest / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            data = z.read(member)
            target.write_bytes(data)
            n += 1
            size += len(data)
        print(f"{pack} -> {dest.relative_to(ROOT)}  ({n} files, {size / 1e6:.1f} MB)")
    cmd_catalog(z)


def main(argv: list[str]) -> None:
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return
    with zipfile.ZipFile(archive()) as z:
        if argv[0] == "catalog":
            cmd_catalog(z)
        elif argv[0] == "list":
            f = " ".join(argv[1:]).lower()
            for p in sorted(packs(z)):
                if f in p.lower():
                    print(p)
        elif argv[0] == "add" and len(argv) > 1:
            cmd_add(z, argv[1:])
        else:
            print(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
