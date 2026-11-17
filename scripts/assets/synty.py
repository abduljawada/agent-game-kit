#!/usr/bin/env python3
"""Synty POLYGON packs (Unity-format folders) -> assets/local/synty/<Pack>/ for Godot.

  scripts/assets/synty.py list                 packs found in the Synty folder
  scripts/assets/synty.py add PolygonStarter [PolygonCity ...]   copy models + textures

LICENCE: Synty's licence allows using these assets in games you ship, but NOT
redistributing the source files. assets/local/ is git-ignored, so nothing copied here
is committed or pushed. Never move Synty files outside assets/local/.

Copies Models/**/*.fbx (collision meshes skipped) and Textures/*.png|tga, then writes
synty_materials.json mapping Unity material names to their albedo texture (read from the
Unity .mat/.meta files) plus a default atlas. kit/importers/synty_post_import.gd uses it
to give every imported mesh a textured material, since FBX files don't carry the link.

The Synty folder comes from $SYNTY_DIR or assets/local/sources.cfg ([sources] synty_dir=...).
"""
import configparser
import json
import os
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "local" / "synty"
CFG = ROOT / "assets" / "local" / "sources.cfg"


def source_dir() -> Path:
    if os.environ.get("SYNTY_DIR"):
        return Path(os.environ["SYNTY_DIR"]).expanduser()
    if CFG.exists():
        cp = configparser.ConfigParser()
        cp.read(CFG)
        if cp.has_option("sources", "synty_dir"):
            return Path(cp.get("sources", "synty_dir")).expanduser()
    sys.exit("Synty folder unknown. Set SYNTY_DIR or add synty_dir= to assets/local/sources.cfg [sources]")


def find_packs(src: Path) -> dict[str, Path]:
    packs = {}
    for models in sorted(src.glob("**/Models")):
        if models.is_dir() and any(models.rglob("*.fbx")):
            packs[models.parent.name] = models.parent
    return packs


def guid_of(meta: Path) -> str | None:
    m = re.search(r"^guid: ([0-9a-f]+)", meta.read_text(errors="ignore"), re.M)
    return m.group(1) if m else None


def material_map(pack: Path) -> dict[str, str]:
    tex_by_guid = {}
    for meta in (pack / "Textures").glob("*.meta"):
        g = guid_of(meta)
        if g:
            tex_by_guid[g] = meta.name[: -len(".meta")]
    out = {}
    for mat in pack.rglob("*.mat"):
        text = mat.read_text(errors="ignore")
        m = re.search(r"- _(?:MainTex|BaseMap|Albedo\w*):\s*\n\s*m_Texture: \{[^}]*guid: ([0-9a-f]+)", text)
        if m and m.group(1) in tex_by_guid:
            out[mat.stem.lower()] = "Textures/" + tex_by_guid[m.group(1)]
    return out


def default_texture(pack: Path, mats: dict[str, str]) -> str | None:
    for name, tex in sorted(mats.items()):
        if re.search(r"_mat_0?1$", name):
            return tex
    pngs = sorted(p.name for p in (pack / "Textures").glob("*.png"))
    for pattern in (r"texture_0?1(_a)?\.png$", r"texture_0?1", r"\.png$"):
        for p in pngs:
            if re.search(pattern, p, re.I) and not re.search(r"emiss|normal|_dark|snow", p, re.I):
                return "Textures/" + p
    return None


def add(name: str, packs: dict[str, Path]) -> None:
    match = [k for k in packs if k.lower() == name.lower()]
    if not match:
        sys.exit(f"No Synty pack '{name}'. Found: {', '.join(packs)}")
    pack = packs[match[0]]
    dest = OUT / match[0]
    if dest.exists():
        shutil.rmtree(dest)
    n = 0
    for fbx in (pack / "Models").rglob("*.fbx"):
        if re.search(r"collision", str(fbx.relative_to(pack)), re.I):
            continue
        target = dest / fbx.relative_to(pack)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(fbx, target)
        n += 1
    (dest / "Textures").mkdir(parents=True, exist_ok=True)
    for tex in list((pack / "Textures").glob("*.png")) + list((pack / "Textures").glob("*.tga")):
        shutil.copy2(tex, dest / "Textures" / tex.name)
    mats = material_map(pack)
    info = {"pack": match[0], "default": default_texture(pack, mats), "materials": mats,
            "characters": next((t for k, t in sorted(mats.items()) if "character" in k), None)}
    (dest / "synty_materials.json").write_text(json.dumps(info, indent=1))
    size = sum(f.stat().st_size for f in dest.rglob("*") if f.is_file())
    print(f"{match[0]} -> {dest.relative_to(ROOT)}  ({n} models, {size / 1e6:.1f} MB, default texture {info['default']})")


def main(argv: list[str]) -> None:
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return
    src = source_dir()
    packs = find_packs(src)
    if argv[0] == "list":
        for k, p in packs.items():
            mark = " (copied)" if (OUT / k).exists() else ""
            print(f"{k}: {len(list((p / 'Models').rglob('*.fbx')))} models{mark}")
    elif argv[0] == "add":
        for name in argv[1:]:
            add(name, packs)
    else:
        print(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
