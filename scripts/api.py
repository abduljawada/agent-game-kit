#!/usr/bin/env python3
"""Look up the exact Godot API for the installed engine and this project.

  scripts/api.sh CharacterBody2D              class summary: inheritance, members, signatures
  scripts/api.sh CharacterBody2D move_and_slide   one member with its full description
  scripts/api.sh --search floor_snap          find members by name across all classes
  scripts/api.sh --inherited CharacterBody2D  also list members inherited from base classes

Data comes from .godot/api (built by scripts/api_docs.sh from the Godot binary itself),
so it always matches the engine version and addon versions in this project.
"""
import re
import textwrap
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / ".godot" / "api"


def index() -> dict[str, Path]:
    files: dict[str, Path] = {}
    for sub in ("engine", "project"):
        for p in (ROOT / sub).rglob("*.xml"):
            name = (ET.parse(p).getroot().get("name") if sub == "project" else p.stem) or p.stem
            # Same class can appear twice (doctool dump + upstream docs); keep the richer file.
            if name not in files or p.stat().st_size > files[name].stat().st_size:
                files[name] = p
    return files


def text(el) -> str:
    if el is None or el.text is None:
        return ""
    t = re.sub(r"\[/?(code|b|i|codeblock|codeblocks|gdscript|csharp)\]", "`", el.text)
    t = re.sub(r"\[(method|member|signal|constant|enum|param|annotation|theme_item) ([^\]]+)\]", r"\2", t)
    t = re.sub(r"\[([A-Z][A-Za-z0-9_]*)\]", r"\1", t)
    return textwrap.dedent(t.strip("\n")).strip()


def sig(m) -> str:
    ret = m.find("return")
    params = []
    for p in m.findall("param"):
        s = f"{p.get('name')}: {p.get('type')}"
        if p.get("default") is not None:
            s += f" = {p.get('default')}"
        params.append(s)
    q = f" ({m.get('qualifiers')})" if m.get("qualifiers") else ""
    rtype = ret.get("type") if ret is not None else "void"
    return f"{m.get('name')}({', '.join(params)}) -> {rtype}{q}"


def chain(name: str, files: dict[str, Path]) -> list[str]:
    out = []
    while name and name in files:
        out.append(name)
        name = ET.parse(files[name]).getroot().get("inherits")
    return out


def summary(name: str, files: dict[str, Path], inherited: bool) -> None:
    classes = chain(name, files) if inherited else [name]
    root = ET.parse(files[name]).getroot()
    origin = "engine" if "engine" in files[name].parts[-5:] else "project/addon"
    print(f"{name}  ({' < '.join(chain(name, files)[1:]) or 'no base'})  [{origin}]")
    print(text(root.find("brief_description")))
    for cname in classes:
        r = ET.parse(files[cname]).getroot()
        head = "" if cname == name else f"  -- from {cname}"
        members = [m for m in r.findall("members/member") if not m.get("name", "").startswith("_")]
        if members:
            print(f"\nProperties{head}:")
            for m in members:
                d = f" = {m.get('default')}" if m.get("default") is not None else ""
                print(f"  {m.get('name')}: {m.get('type')}{d}")
        methods = [m for m in r.findall("methods/method")
                   if not m.get("name", "").startswith("_") or "virtual" in (m.get("qualifiers") or "")]
        if methods:
            print(f"\nMethods{head}:")
            for m in methods:
                print(f"  {sig(m)}")
        signals = r.findall("signals/signal")
        if signals:
            print(f"\nSignals{head}:")
            for s in signals:
                print(f"  {sig(s).replace(' -> void', '')}")
        consts = r.findall("constants/constant")
        if consts and cname == name:
            enums: dict[str, list[str]] = {}
            for c in consts:
                enums.setdefault(c.get("enum") or "constants", []).append(f"{c.get('name')}={c.get('value')}")
            print("\nEnums/constants:")
            for e, vals in enums.items():
                print(f"  {e}: {', '.join(vals[:12])}{' ...' if len(vals) > 12 else ''}")
    if not inherited and len(chain(name, files)) > 1:
        print(f"\n(add --inherited to include members from {', '.join(chain(name, files)[1:4])}...)")


def member(name: str, member_name: str, files: dict[str, Path]) -> bool:
    for cname in chain(name, files):
        r = ET.parse(files[cname]).getroot()
        for tag in ("methods/method", "members/member", "signals/signal", "constants/constant", "annotations/annotation"):
            for m in r.findall(tag):
                if m.get("name") == member_name:
                    kind = tag.split("/")[1]
                    where = "" if cname == name else f" (inherited from {cname})"
                    if kind in ("method", "signal", "annotation"):
                        print(f"{cname}.{sig(m)}  [{kind}]{where}")
                    else:
                        print(f"{cname}.{member_name}: {m.get('type') or m.get('enum') or ''} = {m.get('default') or m.get('value')}  [{kind}]{where}")
                        if m.get("setter"):
                            print(f"  setter {m.get('setter')}(), getter {m.get('getter')}()")
                    desc = text(m.find("description")) if m.find("description") is not None else text(m)
                    print(desc or "(no description)")
                    return True
    return False


def search(term: str, files: dict[str, Path]) -> None:
    pat = re.compile(term, re.I)
    hits = 0
    for cname, path in sorted(files.items()):
        r = ET.parse(path).getroot()
        for tag in ("methods/method", "members/member", "signals/signal", "constants/constant"):
            for m in r.findall(tag):
                if pat.search(m.get("name", "")):
                    print(f"{cname}.{m.get('name')}  [{tag.split('/')[1]}]")
                    hits += 1
                    if hits >= 60:
                        print("... (more; narrow the search)")
                        return
    if pat.pattern and hits == 0:
        print("no matches")


def main(argv: list[str]) -> int:
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    files = index()
    if not files:
        print("No API data. Run scripts/api_docs.sh first.", file=sys.stderr)
        return 2
    if argv[0] == "--search":
        search(" ".join(argv[1:]), files)
        return 0
    inherited = "--inherited" in argv
    argv = [a for a in argv if a != "--inherited"]
    cls = argv[0]
    if cls not in files:
        close = [c for c in files if c.lower() == cls.lower()] or [c for c in files if cls.lower() in c.lower()][:15]
        print(f"No class '{cls}' in Godot {open(ROOT / 'STAMP').readline().strip()}. Did you mean: {', '.join(close) or 'nothing similar'}")
        print("Godot 3 names are gone in 4.x (e.g. KinematicBody2D -> CharacterBody2D, Spatial -> Node3D).")
        return 1
    if len(argv) > 1:
        if not member(cls, argv[1], files):
            print(f"{cls} has no member '{argv[1]}' (checked base classes too). Try: scripts/api.sh --search {argv[1]}")
            return 1
        return 0
    summary(cls, files, inherited)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
