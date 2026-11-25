"""Derive per-binding mesh-local basis corrections for capital import.

Prefab hierarchy already carries Unity FBX axis conversion on ancestors.
Apply GLB node rotation only when no ancestor provides ~±90° X and the
imported GLB node itself has a non-identity rotation. Never copy GLB
translation (it duplicates prefab local positions).
Also resolve review bindings whose Unity meta names are absent from the
source FBX by falling back to same-named meshes in other city GLBs when
unambiguous.
"""
from __future__ import annotations

import json
import math
import re
import struct
import sys
from collections import Counter
from pathlib import Path

ASSETS = Path("/home/gamedev/Darklord/Client/Assets")
BASE = Path(sys.argv[1] if len(sys.argv) > 1 else "/home/gamedev/darklord-dgi")


def euler_x(qx: float, qy: float, qz: float, qw: float) -> float:
    sinr_cosp = 2 * (qw * qx + qy * qz)
    cosr_cosp = 1 - 2 * (qx * qx + qy * qy)
    return math.degrees(math.atan2(sinr_cosp, cosr_cosp))


def near_axis(deg: float) -> bool:
    return abs(abs(deg) - 90.0) < 1.0


def parse_prefab(path: Path):
    text = path.read_text(encoding="utf-8-sig")
    gos = {}
    for m in re.finditer(r"^--- !u!1 &(\d+)\n(.*?)(?=^--- !u!|\Z)", text, re.M | re.S):
        oid = int(m.group(1))
        block = m.group(2)
        name = re.search(r"m_Name: (.*)", block)
        gos[oid] = name.group(1).strip() if name else "?"
    transforms = {}
    t_by_go = {}
    for m in re.finditer(r"^--- !u!4 &(\d+)\n(.*?)(?=^--- !u!|\Z)", text, re.M | re.S):
        tid = int(m.group(1))
        block = m.group(2)
        go_m = re.search(r"m_GameObject: \{fileID: (\d+)\}", block)
        father_m = re.search(r"m_Father: \{fileID: (\d+)\}", block)
        if not go_m or not father_m:
            continue
        go = int(go_m.group(1))
        father = int(father_m.group(1))
        rot = re.search(
            r"m_LocalRotation: \{x: ([-\d.eE+]+), y: ([-\d.eE+]+), z: ([-\d.eE+]+), w: ([-\d.eE+]+)\}",
            block,
        )
        if rot:
            qx, qy, qz, qw = map(float, rot.groups())
        else:
            qx, qy, qz, qw = 0.0, 0.0, 0.0, 1.0
        transforms[tid] = {
            "go": go,
            "father": father,
            "ex": euler_x(qx, qy, qz, qw),
            "quat": (qx, qy, qz, qw),
        }
        t_by_go[go] = tid
    return transforms, t_by_go


def ancestor_axis(transforms, tid) -> bool:
    while tid and tid in transforms:
        if near_axis(transforms[tid]["ex"]):
            return True
        tid = transforms[tid]["father"]
    return False


def load_glb(path: Path):
    raw = path.read_bytes()
    n = struct.unpack_from("<I", raw, 12)[0]
    return json.loads(raw[20 : 20 + n])


def glb_node(gltf: dict, name: str):
    for node in gltf.get("nodes", []):
        if node.get("name") == name and "mesh" in node:
            return node
    return None


def glb_basis(node: dict):
    if not node or "rotation" not in node:
        return {"euler_x": 0.0, "quat": [0.0, 0.0, 0.0, 1.0], "has_rotation": False}
    qx, qy, qz, qw = node["rotation"]
    return {
        "euler_x": euler_x(qx, qy, qz, qw),
        "quat": [qx, qy, qz, qw],
        "has_rotation": True,
    }


def index_glb_meshes():
    """Map mesh node name -> list of {glb, source} for fallback resolution."""
    manifest = json.loads((BASE / "city-glb/manifest.json").read_text())
    index: dict[str, list] = {}
    for entry in manifest:
        if "file" not in entry:
            continue
        gltf = load_glb(BASE / "city-glb" / entry["file"])
        for node in gltf.get("nodes", []):
            if "mesh" not in node:
                continue
            index.setdefault(node.get("name", ""), []).append(
                {"glb": entry["file"], "source": entry.get("source")}
            )
    return index


def main():
    bindings = json.loads((BASE / "city-mesh-bindings.json").read_text())
    mesh_index = index_glb_meshes()
    prefab_cache = {}
    glb_cache = {}
    basis_rows = []
    updated = []
    stats = Counter()

    for row in bindings:
        out = dict(row)
        if out.get("status") == "review" and out.get("name"):
            dedicated = [
                c
                for c in mesh_index.get(out["name"], [])
                if c.get("source") and Path(c["source"]).stem == out["name"]
            ]
            if len(dedicated) == 1:
                choice = dedicated[0]
                out["glb"] = choice["glb"]
                out["fallback_source"] = choice["source"]
                out["matches"] = [0]
                out["status"] = "exact"
                out["basis_note"] = "fallback_same_name_glb"
                stats["fallback_exact"] += 1
            else:
                out["status"] = "source_missing"
                out["basis_note"] = "geometry_absent_from_fbx"
                stats["source_missing"] += 1

        if out.get("status") == "unresolved":
            out["basis_note"] = "unresolved_mesh_ref"
            stats["unresolved"] += 1
            updated.append(out)
            continue

        if out.get("status") != "exact":
            updated.append(out)
            continue

        prefab = out["prefab"]
        if prefab not in prefab_cache:
            path = ASSETS / prefab
            prefab_cache[prefab] = parse_prefab(path) if path.exists() else ({}, {})
        transforms, t_by_go = prefab_cache[prefab]
        oid = out["object"]["fileID"] if isinstance(out["object"], dict) else out["object"]
        tid = t_by_go.get(oid)
        axis_in_hierarchy = ancestor_axis(transforms, tid) if tid else False

        glb = out["glb"]
        if glb not in glb_cache:
            glb_cache[glb] = load_glb(BASE / "city-glb" / glb)
        node = glb_node(glb_cache[glb], out["name"])
        gb = glb_basis(node)
        if axis_in_hierarchy:
            mode = "identity"
            quat = [0.0, 0.0, 0.0, 1.0]
            stats["identity_hierarchy_axis"] += 1
        elif near_axis(gb["euler_x"]) or gb["has_rotation"]:
            mode = "glb_basis"
            quat = gb["quat"]
            stats["glb_basis"] += 1
        else:
            mode = "identity"
            quat = [0.0, 0.0, 0.0, 1.0]
            stats["identity_default"] += 1

        basis_rows.append(
            {
                "prefab": prefab,
                "component": out["component"],
                "name": out["name"],
                "glb": glb,
                "mode": mode,
                "quat": quat,
                "glb_euler_x": gb["euler_x"],
                "hierarchy_axis": axis_in_hierarchy,
            }
        )
        out["basis_mode"] = mode
        updated.append(out)

    (BASE / "city-mesh-basis.json").write_text(json.dumps(basis_rows, indent=2))
    (BASE / "city-mesh-bindings.json").write_text(json.dumps(updated, indent=2))
    print(dict(stats))
    print("basis_rows", len(basis_rows))
    print(Counter(r["status"] for r in updated))


if __name__ == "__main__":
    main()
