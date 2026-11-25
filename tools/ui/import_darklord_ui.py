#!/usr/bin/env python3
"""Import used Darklord UI atlases + extract sprites for Godot Theme/HUD.
Does NOT copy the full 143MiB Atlas tree — only the beta used set.
"""
from __future__ import annotations

import json
import re
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = Path("/home/gamedev/Darklord/Client/Assets/Atlas")
FONT_SRC = Path("/home/gamedev/Darklord/Client/Assets/Resources/UI/NewFont")
OUT = ROOT / "client/ui/darklord"
SPRITES = OUT / "sprites"
ATLAS_OUT = OUT / "atlases"

USED_ATLASES = [
    "UICommon.png",
    "UICommon2.png",
    "UIMain.png",
    "UIMain2.png",
    "UIMainTips.png",
    "Login.png",
    "FubenFight.png",
    "NewHP.png",
    "UISkill.png",
    "skillicon.png",
    "Item.png",
    "ItemIco.png",
    "HeadIcons.png",
    "HeroIco.png",
    "Chapter.png",
    "EquipIco.png",
]

# Sprites required for Theme / HUD / menus (names as in Unity meta)
WANTED = {
    "UICommon.png": [
        "frame1.png",
        "frame2.png",
        "frame3.png",
        "btn_green.png",
        "btn_red.png",
        "btn_black.png",
        "btn_circle.png",
        "btn_add.png",
        "back_page.png",
        "back_top.png",
        "back_name.png",
        "bar_exp.png",
        "bar_exp_slot.png",
        "title_back1.png",
        "title_back2.png",
        "tab1_normal.png",
        "tab1_select.png",
        "back_coin.png",
        "back_coin_slot.png",
        "line1.png",
        "ico_red_mark.png",
        "blank.png",
    ],
    "UIMain.png": [],  # take all if few; filled dynamically for hp/skill-ish names
    "UIMain2.png": [],
    "NewHP.png": [],
    "Login.png": [],
    "FubenFight.png": [],
    "UICommon2.png": [
        "btn_green.png",
        "btn_red.png",
        "frame1.png",
        "frame2.png",
        "back_page.png",
    ],
}

NAME_HINTS = re.compile(
    r"(hp|mp|exp|btn|button|frame|back_|bar_|slot|joy|skill|atk|attack|panel|window|close|tab|title|login|role|head|item|bag|coin)",
    re.I,
)


def parse_sprites(meta_path: Path) -> list[dict]:
    if not meta_path.exists():
        return []
    text = meta_path.read_text(errors="ignore")
    # Unity YAML sprite entries under spriteSheet.sprites
    sprites = []
    # Split on "    - " list items that have name+rect
    for m in re.finditer(
        r"name:\s*(.+?)\n\s*rect:\s*\n\s*serializedVersion:\s*\d+\n\s*x:\s*([-\d.]+)\n\s*y:\s*([-\d.]+)\n\s*width:\s*([-\d.]+)\n\s*height:\s*([-\d.]+)",
        text,
    ):
        name = m.group(1).strip().strip("'\"")
        sprites.append(
            {
                "name": name,
                "x": float(m.group(2)),
                "y": float(m.group(3)),
                "w": float(m.group(4)),
                "h": float(m.group(5)),
            }
        )
    return sprites


def extract(atlas_name: str, wanted: list[str] | None) -> list[str]:
    atlas_path = SRC / atlas_name
    meta_path = SRC / (atlas_name + ".meta")
    if not atlas_path.exists():
        print("SKIP missing", atlas_name)
        return []
    img = Image.open(atlas_path).convert("RGBA")
    W, H = img.size
    sprites = parse_sprites(meta_path)
    out_dir = SPRITES / atlas_name.replace(".png", "")
    out_dir.mkdir(parents=True, exist_ok=True)
    exported = []
    # wanted=None → all; wanted=[] → NAME_HINTS only; wanted=[...] → exact names
    want_set = set(wanted) if wanted else set()
    use_hints = wanted is not None and len(wanted) == 0
    use_exact = wanted is not None and len(wanted) > 0
    for sp in sprites:
        name = sp["name"]
        if use_exact and name not in want_set:
            continue
        if use_hints and not NAME_HINTS.search(name):
            continue
        x, y, w, h = int(sp["x"]), int(sp["y"]), int(sp["w"]), int(sp["h"])
        if w <= 0 or h <= 0:
            continue
        # Unity rect y is from bottom
        top = H - y - h
        left = x
        box = (left, top, left + w, top + h)
        if box[2] > W or box[3] > H or left < 0 or top < 0:
            continue
        crop = img.crop(box)
        safe = re.sub(r"[^\w.\-]+", "_", name)
        if not safe.endswith(".png"):
            safe += ".png"
        dest = out_dir / safe
        crop.save(dest)
        exported.append(str(dest.relative_to(OUT)))
    return exported


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    ATLAS_OUT.mkdir(parents=True, exist_ok=True)
    SPRITES.mkdir(parents=True, exist_ok=True)
    manifest = {"version": 1, "source": "Darklord/Client/Assets/Atlas", "atlases": [], "sprites": []}

    for name in USED_ATLASES:
        src = SRC / name
        if not src.exists():
            print("missing atlas", name)
            continue
        dst = ATLAS_OUT / name
        shutil.copy2(src, dst)
        # also copy .meta for provenance (optional small)
        meta = SRC / (name + ".meta")
        if meta.exists():
            shutil.copy2(meta, ATLAS_OUT / (name + ".meta"))
        manifest["atlases"].append(
            {"file": f"atlases/{name}", "bytes": dst.stat().st_size}
        )
        wanted = WANTED.get(name)
        if name in ("UIMain.png", "UIMain2.png", "NewHP.png", "Login.png", "FubenFight.png", "UISkill.png"):
            wanted = []  # hint filter
        exported = extract(name, wanted if wanted is not None else [])
        manifest["sprites"].extend(exported)
        print(f"{name}: atlas copied, sprites={len(exported)}")

    # Fonts: bitmap number fonts small; skip 4.5MB simhei — use bitmap Power/FBNumber
    font_out = OUT / "fonts"
    font_out.mkdir(exist_ok=True)
    for f in ["FBNumber.png", "Power.png", "FontEquip.png", "PowerCur.png"]:
        p = FONT_SRC / f
        if p.exists():
            shutil.copy2(p, font_out / f)
            manifest["sprites"].append(f"fonts/{f}")

    # Prefer a system-safe note: if simhei under 5MB and disk allows, copy for CJK HUD
    simhei = FONT_SRC / "simhei.ttf"
    if simhei.exists() and simhei.stat().st_size < 5_000_000:
        shutil.copy2(simhei, font_out / "simhei.ttf")
        manifest["sprites"].append("fonts/simhei.ttf")
        print("copied simhei.ttf")

    (OUT / "import_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("DONE atlases", len(manifest["atlases"]), "sprites", len(manifest["sprites"]))
    print("OUT", OUT)


if __name__ == "__main__":
    main()
