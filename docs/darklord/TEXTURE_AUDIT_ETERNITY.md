# Texture audit — Eternity Capital (playercam)

## Что было «голубым»
1. **Главная причина полос вдоль улицы:** kit `water_01` брал FBX `cs_yw_zhucheng_water` с локальным AABB ≈400×400 м и solid `albedo_color` cyan. При размещении у пруда плоскость накрывала всю авеню → сплошные голубые поля.
2. **Вторично:** часть китов (gate/palace/crystal/fountain/…) упаковались без MeshInstance (только Collision) — дыры в геометрии, сквозь которые светился фон Environment (светло-голубой).
3. **Оставшийся cyan после фикса полос:** kit кристалла с эмиссионным материалом без диффузной текстуры (порталы/монумент).

## Исправления
- Вода: маленький `PlaneMesh` + текстуры Darklord `xx_yw_zhucheng_water` / `cs_senlin_water*`.
- Тротуары: `sidewalk_tile` из `cs_zhucheng_dm01`.
- Киты пересобраны с `own_tree` + embed ArrayMesh + surface materials.
- Кристалл: `crystal_fx.png` (bluestarflash из исходников) + сниженная emission.

## Что выглядит «странно», но это исходные атласы Darklord
- Зелёный брус + розовые панели на fangzi — атлас `cs_zhucheng_jianzhu0x`, не плейсхолдер.
- Серые крыши/детали — поверхности FBX без отдельной текстуры в конвертированном GLB; нужна дальнейшая per-surface привязка материалов Unity.

## Не считать done
Полный per-material restore всех поверхностей зданий; skybox; нормали воды.
