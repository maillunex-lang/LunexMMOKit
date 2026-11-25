# World import checkpoint
Inventory: 96 scenes, 21720 transforms, zero parser errors.
GUID resolution: 3550 resolved, 156 missing, zero ambiguous (per-scene references; built-ins excluded).
Pilot mh_scene_07: native layout, partial geometry, original texture, camera, ambient and collision.
Visual test: original camera capture shows only background; diagnostic bounds camera shows dark partial geometry. NOT accepted.
Investigate FBX mesh-local basis versus Unity imported mesh, fileID-to-submesh mapping, original shader, missing prefab content and baked lighting before batch conversion.
Capture evidence on VPS: /home/gamedev/darklord-dgi/screens/world-original-camera.png and world-inspection-camera.png.
No navigation or gameplay validation yet. CI unverified.

Correction: pilot mesh-local X rotation PI restores arena visibility from original camera. Diagnostic directional light added (not original). Screenshot world-corrected-camera.png visually inspected: textured circular arena visible, sky/effects and lighting parity incomplete. Collision rotation follows navigation mesh; gameplay untested.

Navigation follow-up: see `docs/darklord/NAVIGATION_FIX.md`. World arena navigation path queries now pass after reversing winding and waiting for map synchronization. Character travel still untested.

## CAP03: итерация v3
82cc4b4: v3, 320 экземпляров; 321 применение родительской трансформации включая кандидатов без меша; ширина bounds 1145.6 -> 602.2; рендер сохраняет дефекты ориентации и материалов.
Следующее: проверить ориентацию каждого FBX и многослойный terrain, без универсального поворота PI.

## CAP03 orientation diagnostics
a326765: 145 exact bindings: 71 identity, 64 X -90 degrees, 10 other rotations. v4 no correction and v5 imported local transform both render but bounds height 587.9/823.9; neither accepted. v3 retained. Next inspect source mesh vertices and Unity local basis per asset, active state, terrain.

## Terrain prototype
b3cfd65: v6 terrain shader uses original RGB control and 3 splat textures, tiling 20/40/20; Godot build and render pass, visual parity and orientation remain unverified. Next isolate terrain and outlier meshes.

## Bounds diagnostics
7321bd6: audited 525 mesh instances; crystal effect height 587.86 dominates overview; shadow meshes also outliers. Diagnostic capture hides effects/shadows only in memory, no original or scene deletion. CAP03 visual acceptance pending.

## Isolated terrain
ed5799b: isolated main terrain 247.7 x 249.0, height 20.49; ShaderMaterial bound, screenshot shows separated textured patches rather than continuous ground. Need inspect missing geometry and original terrain topology; no visual acceptance.

## CAP03 v7
Per-mesh basis from Unity hierarchy axis vs GLB node rotation; no universal PI. dm04 rebound from dedicated FBX. jianzhu01/02_a/02_b absent from jz01.FBX binary (source_missing). Architecture diagnostic height 77 without effects; crystal still 587 full bounds. Visual acceptance not passed.

## CAP03 closed / CAP04 start
Coord compare v7: 320/320 placements within 1m of placement×parent expectation. Architecture close renders accepted for geometry orientation. CAP04: direct FBX water/crystal/walksurface in v8; water double -90 removed (now flat); 5 non-geometry placements excluded with reasons.
