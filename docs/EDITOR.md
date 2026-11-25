# EDITOR-001 — editable native Godot project
Approved: full available Darklord content transfer first, custom redesign and expansion afterwards.
Native editable scenes (.tscn) and resources (.tres) are required deliverables, not merely runtime-generated previews.
UI: Control nodes, containers, anchors, offsets, reusable Theme, textures and individual scene instances; editable in Godot 2D editor. Responsive layouts remain supported.
World: Node3D scene hierarchy, reusable PackedScenes, editable transforms, materials, lighting, collision, navigation, spawn markers, NPCs and portals. Preserve original placements and source IDs.
Actors: editable wrapper scenes around imported meshes, AnimationPlayer/AnimationTree, equipment sockets, per-model offsets, materials and effects. Imported GLB remains replaceable; edits live outside generated imports.
Data: typed Resources and inspector fields for items, quests, dialogues, skills, stats and spawn definitions; custom editor plugins where necessary. Export validated data to authoritative server; never trust client-edited stats in multiplayer.
Import pipeline: deterministic generated base scenes separated from user-owned overrides; no silent overwrite of manual edits. Preserve provenance, unresolved references and conversion reports. Do not commit original Darklord project or secrets. Adapted runtime assets follow existing portability policy.
Acceptance per content batch: open native scenes in Godot editor, inspect/edit/save/reopen representative nodes and resources, verify runtime behavior and clean-clone build. Report unsupported Unity features rather than silently dropping them.
Existing Character Studio is a preview tool, not proof of EDITOR-001 completion.
