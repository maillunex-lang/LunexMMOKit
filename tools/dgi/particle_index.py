import json
import os
import pathlib
import re
import sqlite3
import sys

ROOT = pathlib.Path("/home/gamedev/Darklord")
DB = sqlite3.connect("file:/home/gamedev/darklord-dgi/catalog.sqlite?mode=ro", uri=True)
OUT = pathlib.Path("/home/gamedev/darklord-dgi/particle-index.json")
MESH_EXPORT_ROOT = pathlib.Path("/home/gamedev/darklord-dgi/exports/meshes")


def resolve(guid):
    return [row[0] for row in DB.execute("select path from assets where guid=?", (guid,))]


def blocks(text):
    pattern = r"^--- !u!(\d+) &(\d+)\n(.*?)(?=^--- !u!|\Z)"
    return {int(i): (int(t), b) for t, i, b in re.findall(pattern, text, re.M | re.S)}


def field(block, key, indent=2):
    match = re.search(r"^" + " " * indent + re.escape(key) + r": (.*)$", block, re.M)
    return match.group(1).strip() if match else None


def number(value, default=0.0):
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def integer(value, default=0):
    try:
        return int(float(value))
    except (TypeError, ValueError):
        return default


def vec_block(text, key, indent=2):
    pattern = r"^" + " " * indent + re.escape(key) + r": \{x: ([^,]+), y: ([^,]+), z: ([^,]+?)(?:,\s*w: ([^}]+?))?\}"
    match = re.search(pattern, text, re.M | re.S)
    if not match:
        return None
    values = [number(match.group(i)) for i in range(1, 4)]
    if match.group(4) is not None:
        values.append(number(match.group(4)))
    return values


def color_block(text, key, indent=2):
    pattern = r"^" + " " * indent + re.escape(key) + r": \{r: ([^,]+), g: ([^,]+), b: ([^,]+), a: ([^}]+)\}"
    match = re.search(pattern, text, re.M)
    if not match:
        return None
    return [number(match.group(i)) for i in range(1, 5)]


def module_block(system_block, name):
    pattern = r"^  " + re.escape(name) + r":\n(.*?)(?=^  \w+Module:|^--- !u!|\Z)"
    match = re.search(pattern, system_block, re.M | re.S)
    return match.group(1) if match else ""


def sub_block(text, key, indent):
    pattern = r"^" + " " * indent + re.escape(key) + r":\n(.*?)(?=^" + " " * indent + r"\w|^" + " " * max(0, indent - 2) + r"\w|\Z)"
    match = re.search(pattern, text, re.M | re.S)
    return match.group(1) if match else ""


def curve_group(text, name, indent=6):
    block = sub_block(text, name, indent)
    if not block:
        return None
    keys = []
    for match in re.finditer(r"time: ([0-9.eE+-]+)\s+value: ([0-9.eE+-]+)\s+inSlope: ([0-9.eE+-]+)\s+outSlope: ([0-9.eE+-]+)", block):
        keys.append({"time": number(match.group(1)), "value": number(match.group(2)), "inSlope": number(match.group(3)), "outSlope": number(match.group(4))})
    return {"keys": keys}


def minmax_curve(system_block, module_name, key):
    mod = module_block(system_block, module_name)
    if not mod:
        return None
    block = sub_block(mod, key, 4)
    if not block:
        return None
    state = integer(field(block, "minMaxState", 6), 0)
    scalar = number(field(block, "scalar", 6), 0.0)
    min_scalar = number(field(block, "minScalar", 6), scalar)
    return {
        "state": state,
        "scalar": scalar,
        "minScalar": min_scalar,
        "maxCurve": curve_group(block, "maxCurve", 6),
        "minCurve": curve_group(block, "minCurve", 6),
    }


def gradient_group(text, name, indent=6):
    block = sub_block(text, name, indent)
    if not block:
        return None
    color_keys = []
    alpha_keys = []
    num_color = integer(field(block, "m_NumColorKeys", 8), 2)
    num_alpha = integer(field(block, "m_NumAlphaKeys", 8), 2)
    for index in range(min(8, num_color)):
        color = color_block(block, "key" + str(index), 8)
        time = number(field(block, "ctime" + str(index), 8), 0.0) / 65535.0
        if color:
            color_keys.append({"time": time, "color": color})
    for index in range(min(8, num_alpha)):
        color = color_block(block, "key" + str(index), 8)
        time = number(field(block, "atime" + str(index), 8), 0.0) / 65535.0
        if color:
            alpha_keys.append({"time": time, "alpha": color[3]})
    return {"colorKeys": color_keys, "alphaKeys": alpha_keys}


def minmax_gradient(system_block, module_name, key):
    mod = module_block(system_block, module_name)
    if not mod:
        return None
    block = sub_block(mod, key, 4)
    if not block:
        return None
    return {
        "state": integer(field(block, "minMaxState", 6), 0),
        "minColor": color_block(block, "minColor", 6),
        "maxColor": color_block(block, "maxColor", 6),
        "maxGradient": gradient_group(block, "maxGradient", 6),
        "minGradient": gradient_group(block, "minGradient", 6),
    }


def parse_material(path):
    source = (ROOT / path).read_text(errors="ignore")
    shader_match = re.search(r"m_Shader: \{fileID: ([^,]+)(?:, guid: ([a-f0-9]{32}))?", source)
    shader_file = shader_match.group(1) if shader_match else ""
    shader_guid = shader_match.group(2) if shader_match and shader_match.group(2) else ""
    if shader_guid and shader_guid != "0000000000000000f000000000000000":
        shader_paths = resolve(shader_guid)
    else:
        shader_paths = ["builtin:" + shader_file] if shader_file else []
    textures = {}
    for match in re.finditer(r"name: (_\w+)\s+second:\s+m_Texture: \{[^}]*guid: ([a-f0-9]{32})", source):
        textures[match.group(1)] = resolve(match.group(2))
    for match in re.finditer(r"- (_\w+):\s+m_Texture: \{[^}]*guid: ([a-f0-9]{32})", source):
        textures[match.group(1)] = resolve(match.group(2))
    floats = {}
    for match in re.finditer(r"name: (_\w+)\s+second: ([0-9.eE+-]+)", source):
        floats[match.group(1)] = number(match.group(2))
    for match in re.finditer(r"- (_\w+): ([0-9.eE+-]+)\s*$", source, re.M):
        floats[match.group(1)] = number(match.group(2))
    colors = {}
    color_pattern = r"name: (_\w+)\s+second: \{r: ([^,]+), g: ([^,]+), b: ([^,]+), a: ([^}]+)\}"
    for match in re.finditer(color_pattern, source):
        colors[match.group(1)] = [number(match.group(i)) for i in range(2, 6)]
    for match in re.finditer(r"- (_\w+): \{r: ([^,]+), g: ([^,]+), b: ([^,]+), a: ([^}]+)\}", source):
        colors[match.group(1)] = [number(match.group(i)) for i in range(2, 6)]
    shader_name = ""
    shader_source = ""
    for shader_path in shader_paths:
        if shader_path.startswith("Client/") and (ROOT / shader_path).exists():
            shader_source = (ROOT / shader_path).read_text(errors="ignore")
            name_match = re.search(r"Shader\s+\"([^\"]+)\"", shader_source)
            shader_name = name_match.group(1) if name_match else pathlib.Path(shader_path).stem
    lower_name = (shader_name + " " + path).lower()
    blend = "alpha"
    if shader_file in ["200", "201"] or "blend one one" in shader_source.lower() or "blend srcalpha one" in shader_source.lower() or "add" in lower_name:
        blend = "additive"
    if shader_file == "203" or "blend srcalpha oneminussrcalpha" in shader_source.lower() or "alpha" in lower_name or "smoke" in lower_name:
        blend = "alpha"
    if "multiply" in lower_name or "blend dstcolor" in shader_source.lower():
        blend = "multiply"
    if floats.get("_SrcBlend") == 1.0 and floats.get("_DstBlend") == 1.0:
        blend = "additive"
    if floats.get("_SrcBlend") == 5.0 and floats.get("_DstBlend") == 10.0:
        blend = "alpha"
    return {
        "path": path,
        "shader": shader_paths,
        "shader_name": shader_name,
        "blend": blend,
        "soft_particles": floats.get("_InvFade", 0.0) > 0.0,
        "textures": textures,
        "floats": floats,
        "colors": colors,
    }


def transform_table(blocks_map):
    names = {}
    transforms = {}
    for object_id, data in blocks_map.items():
        kind, body = data
        if kind == 1:
            names[object_id] = field(body, "m_Name", 2) or str(object_id)
    for object_id, data in blocks_map.items():
        kind, body = data
        if kind != 4:
            continue
        game_object = integer(re.search(r"m_GameObject: \{fileID: (\d+)\}", body).group(1), 0)
        father = integer(re.search(r"m_Father: \{fileID: (\d+)\}", body).group(1), 0)
        transforms[object_id] = {
            "id": object_id,
            "game_object": game_object,
            "name": names.get(game_object, str(game_object)),
            "parent": father,
            "position": vec_block(body, "m_LocalPosition", 2),
            "rotation": vec_block(body, "m_LocalRotation", 2),
            "scale": vec_block(body, "m_LocalScale", 2),
        }
    hierarchy = []
    for transform in transforms.values():
        hierarchy.append(transform)
    return hierarchy, transforms


def path_for(transform_id, transforms):
    parts = []
    current = transform_id
    seen = set()
    while current in transforms and current not in seen:
        seen.add(current)
        node = transforms[current]
        parts.append(node["name"])
        current = node.get("parent", 0)
    parts.reverse()
    return "/".join(parts)


def inspect(path):
    text = (ROOT / path).read_text(errors="ignore")
    block_map = blocks(text)
    hierarchy, transforms = transform_table(block_map)
    renderers = {}
    for object_id, data in block_map.items():
        kind, body = data
        if kind == 199:
            game_object = integer(re.search(r"m_GameObject: \{fileID: (\d+)\}", body).group(1), 0)
            renderers[game_object] = body
    go_to_transform = {}
    for transform_id, node in transforms.items():
        go_to_transform[node["game_object"]] = transform_id
    rows = []
    for object_id, data in block_map.items():
        kind, body = data
        if kind != 198:
            continue
        game_object = integer(re.search(r"m_GameObject: \{fileID: (\d+)\}", body).group(1), 0)
        game_block = block_map.get(game_object, (0, ""))[1]
        name = field(game_block, "m_Name", 2) or str(game_object)
        renderer = renderers.get(game_object, "")
        material_paths = []
        if renderer:
            for guid in re.findall(r"guid: ([a-f0-9]{32})", renderer):
                for material_path in resolve(guid):
                    if material_path.endswith(".mat"):
                        material_paths.append(material_path)
        materials = [parse_material(material_path) for material_path in sorted(set(material_paths))]
        mesh_source = ""
        mesh_match = re.search(r"m_Mesh: \{fileID: [^,]+, guid: ([a-f0-9]{32})", renderer)
        if mesh_match:
            resolved = resolve(mesh_match.group(1))
            mesh_source = resolved[0] if resolved else ""
        mesh_glb = ""
        if mesh_source:
            candidate = MESH_EXPORT_ROOT / (pathlib.Path(mesh_source).stem + ".glb")
            if candidate.exists():
                mesh_glb = str(candidate)
        transform_id = go_to_transform.get(game_object, 0)
        initial = module_block(body, "InitialModule")
        emission = module_block(body, "EmissionModule")
        bursts = []
        emission_block = sub_block(emission, "m_Bursts", 4)
        for burst in re.findall(r"- serializedVersion: \d+\n(.*?)(?=\n    - serializedVersion:|\Z)", emission_block, re.S):
            item = {}
            for key in ["time", "minCount", "maxCount", "cycleCount", "repeatInterval", "probability"]:
                match = re.search(r"^      " + key + r": ([0-9.eE+-]+)", burst, re.M)
                if match:
                    item[key] = number(match.group(1))
            if item:
                bursts.append(item)
        row = {
            "id": object_id,
            "name": name,
            "duration": number(field(body, "lengthInSec", 2), 5.0),
            "loop": field(body, "looping", 2) == "1",
            "prewarm": field(body, "prewarm", 2) == "1",
            "startDelay": minmax_curve(body, "InitialModule", "startDelay"),
            "local_coords": field(body, "moveWithTransform", 2) != "1",
            "maxNumParticles": integer(field(initial, "maxNumParticles", 4), 1000),
            "curves": {
                "startLifetime": minmax_curve(body, "InitialModule", "startLifetime"),
                "startSpeed": minmax_curve(body, "InitialModule", "startSpeed"),
                "startSize": minmax_curve(body, "InitialModule", "startSize"),
                "startRotation": minmax_curve(body, "InitialModule", "startRotation"),
                "startColor": minmax_gradient(body, "InitialModule", "startColor"),
                "gravityModifier": minmax_curve(body, "InitialModule", "gravityModifier"),
                "rateOverTime": minmax_curve(body, "EmissionModule", "rateOverTime"),
                "rateOverDistance": minmax_curve(body, "EmissionModule", "rateOverDistance"),
            },
            "emission": {"bursts": bursts, "burstCount": integer(field(emission, "m_BurstCount", 4), len(bursts))},
            "shape": {
                "enabled": field(module_block(body, "ShapeModule"), "enabled", 4) != "0",
                "type": integer(field(module_block(body, "ShapeModule"), "type", 4), 0),
                "angle": number(field(module_block(body, "ShapeModule"), "angle", 4), 0.0),
                "radius": number(field(sub_block(module_block(body, "ShapeModule"), "radius", 4) or "", "value", 6), number(field(module_block(body, "ShapeModule"), "radius", 4), 0.0)),
                "box": [number(field(module_block(body, "ShapeModule"), key, 4), 1.0) for key in ["boxX", "boxY", "boxZ"]],
                "randomDirection": number(field(module_block(body, "ShapeModule"), "randomDirection", 4), 0.0),
            },
            "overLifetime": {
                "size": minmax_curve(body, "SizeModule", "curve"),
                "rotation": minmax_curve(body, "RotationModule", "curve"),
                "color": minmax_gradient(body, "ColorModule", "gradient"),
                "velocity": {
                    "enabled": field(module_block(body, "VelocityModule"), "enabled", 4) == "1",
                    "x": minmax_curve(body, "VelocityModule", "x"),
                    "y": minmax_curve(body, "VelocityModule", "y"),
                    "z": minmax_curve(body, "VelocityModule", "z"),
                },
            },
            "uv": {
                "enabled": field(module_block(body, "UVModule"), "enabled", 4) == "1",
                "tilesX": integer(field(module_block(body, "UVModule"), "tilesX", 4), 1),
                "tilesY": integer(field(module_block(body, "UVModule"), "tilesY", 4), 1),
                "cycles": number(field(module_block(body, "UVModule"), "cycles", 4), 1.0),
                "frameOverTime": minmax_curve(body, "UVModule", "frameOverTime"),
            },
            "materials": materials,
            "render_mode": integer(field(renderer, "m_RenderMode", 2), 0) if renderer else 0,
            "lengthScale": number(field(renderer, "m_LengthScale", 2), 2.0),
            "velocityScale": number(field(renderer, "m_VelocityScale", 2), 0.0),
            "mesh_source": mesh_source,
            "mesh_glb": mesh_glb,
            "transform_id": transform_id,
            "parent_transform_id": transforms.get(transform_id, {}).get("parent", 0),
            "path": path_for(transform_id, transforms),
            "raw_modules": re.findall(r"^  (\w+Module):", body, re.M),
        }
        rows.append(row)
    return {"source": path, "hierarchy": hierarchy, "emitters": rows}


def main():
    paths = sys.argv[1:]
    if not paths:
        paths = ["Client/Assets/Resources/Effect/skill/player/FS_W/FS_W_attack001.prefab", "Client/Assets/Resources/Effect/skill/hurt/FS_hti.prefab"]
    output = {path: inspect(path) for path in paths}
    tmp_path = OUT.with_name(OUT.name + ".tmp")
    tmp_path.write_text(json.dumps(output, indent=2), encoding="utf-8")
    os.replace(tmp_path, OUT)
    for path, payload in output.items():
        print(path, len(payload["emitters"]))
        for row in payload["emitters"]:
            print(" ", row["name"], "render", row["render_mode"], "blend", [material.get("blend") for material in row["materials"]], "mesh", row["mesh_glb"] or "-")


if __name__ == "__main__":
    main()
