# CAP03

Исправить родительские трансформации, активность и ориентацию мешей столицы

## Acceptance
Сравнение координат с Unity; повторный рендер без геометрических дефектов

## Evidence
311 экземпляров в группах со смещениями; исправления ещё не внесены

## Latest evidence
82cc4b4: v3, 320 экземпляров; 321 применение родительской трансформации включая кандидатов без меша; ширина bounds 1145.6 -> 602.2; рендер сохраняет дефекты ориентации и материалов.

## CAP03 orientation diagnostics
a326765: 145 exact bindings: 71 identity, 64 X -90 degrees, 10 other rotations. v4 no correction and v5 imported local transform both render but bounds height 587.9/823.9; neither accepted. v3 retained. Next inspect source mesh vertices and Unity local basis per asset, active state, terrain.

## Terrain prototype
b3cfd65: v6 terrain shader uses original RGB control and 3 splat textures, tiling 20/40/20; Godot build and render pass, visual parity and orientation remain unverified. Next isolate terrain and outlier meshes.
