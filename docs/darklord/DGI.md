# DGI initial extraction
Private VPS database: /home/gamedev/darklord-dgi/catalog.sqlite.
Rebuild: python3 tools/dgi/extract.py /home/gamedev/darklord-dgi && python3 tools/dgi/augment.py /home/gamedev/darklord-dgi
Query: python3 tools/dgi/query.py PlayerinfoConfig.lua --id 1
Client example: python3 tools/dgi/query.py t_skill.lua.txt --side client --id 1000001
Tables: sources (hash, encoding, parse status), records (side, filename, ID, JSON), links (candidate relations), assets (path, size, GUID, clip name), xml_sources (tree or parse error), code_refs (candidate formula locations).
All 1560 target Lua files parsed; literal parser does not execute Lua. NaN preserved as tagged object. Parser is not a complete Lua interpreter; duplicate keys, escape semantics, trailing code and source variants require independent verification. XML one failure. Links are preliminary, not exhaustive. C++ references are search hits, not extracted executable formulas. Asset inventory is metadata, not converted GLB. Godot runtime export and source parity tests remain pending. Do not mark D01/D02 done. Full database remains on VPS; only tools and aggregate report committed.

## DGI-002
Run mechanics.py after extract/augment. Adds mechanics and link_review tables. Class skill graphs use explicit profession roots, initial skills and next_lv edges, not faction_limit or guessed ID ranges. Candidate effects are not confirmed dispatch. All 705 original unresolved links classified and alternative exact-ID table matches retained, not automatically repaired. See FORMULAS.md and dgi002-report.json. Runtime parity and exhaustive mechanic dispatch remain pending.

DGI-003: see VISUAL.md and dgi003-report.json. Run visual.py to rebuild visual reference index, convert_model.py for conservative base mesh export.
