# Navigation validation: mh_scene_07

Pilot source: `res://world/imported/mh_scene_07_corrected.tscn`.
The Unity FBX walksurface initially baked 109 polygons with negative-Y normals. Godot's NavigationServer rejected these navigable polygons. Rebuilding the `NavigationMesh` with reversed triangle winding yields 109 upward-facing polygons; save geometry relative to the region's transform rather than preserving the source's absolute world coordinates.
Navigation map queries also require full synchronization after the region mesh is assigned. In the headless test, `map_get_iteration_id` initially reached 1 while closest point remained invalid. After six physics frames and `map_force_update`, iteration 2 returned a four-point path from `(129.5, 52.66808, -121.8)` to `(134.5, 52.66808, -121.8)`.

## Tests
- `godot --headless --path client --script ../tools/world/test_navigation.gd`: 109 polygons, 4 path points, exit 0. Creates `mh_scene_07_navigation.tscn` only when absent. To regenerate, use a new filename rather than overwriting manual editor changes.
- `godot --headless --path client --script ../tools/world/test_navigation_scene.gd`: reopen saved scene, 109 polygons, 5 path points for alternate control positions, exit 0.
- `godot --headless --path client --script ../tools/world/nav_minimal.gd`: isolated 2-polygon navigation passes, exit 0.

## Limitations
- Path calculation checked; agent locomotion, obstacles and Android profiling are not yet validated.
- Navmesh baked with static imported FBX geometry at build/test time, not during Android runtime.
- Area has a diagnostic light. Lighting and scene-content parity are pending.
