# World import checkpoint
Inventory: 96 scenes, 21720 transforms, zero parser errors.
GUID resolution: 3550 resolved, 156 missing, zero ambiguous (per-scene references; built-ins excluded).
Pilot mh_scene_07: native layout, partial geometry, original texture, camera, ambient and collision.
Visual test: original camera capture shows only background; diagnostic bounds camera shows dark partial geometry. NOT accepted.
Investigate FBX mesh-local basis versus Unity imported mesh, fileID-to-submesh mapping, original shader, missing prefab content and baked lighting before batch conversion.
Capture evidence on VPS: /home/gamedev/darklord-dgi/screens/world-original-camera.png and world-inspection-camera.png.
No navigation or gameplay validation yet. CI unverified.
