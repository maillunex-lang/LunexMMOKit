extends Control
## W02: corner minimap — world→UV from location_registry map_bounds.

const Registry = preload("res://world/location_registry.gd")

@export var location_id := "eternity_capital"
@export var map_size := Vector2(140, 140)

var _hero_pos := Vector3.ZERO
var _label: Label
var _dot: ColorRect
var _frame: ColorRect

func _ready() -> void:
	custom_minimum_size = map_size
	size = map_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame = ColorRect.new()
	_frame.color = Color(0.08, 0.1, 0.12, 0.72)
	_frame.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_frame)
	_dot = ColorRect.new()
	_dot.color = Color(0.95, 0.85, 0.35, 0.95)
	_dot.size = Vector2(8, 8)
	add_child(_dot)
	_label = Label.new()
	_label.position = Vector2(4, 4)
	_label.add_theme_font_size_override("font_size", 11)
	add_child(_label)
	_refresh_label()
	set_anchors_preset(PRESET_TOP_RIGHT)
	offset_left = -map_size.x - 12
	offset_top = 12
	offset_right = -12
	offset_bottom = 12 + map_size.y

func set_location(id: String) -> void:
	location_id = id
	_refresh_label()
	update_hero(_hero_pos)

func update_hero(pos: Vector3) -> void:
	_hero_pos = pos
	var uv := Registry.world_to_map_uv(location_id, pos)
	_dot.position = Vector2(uv.x * (map_size.x - 8), uv.y * (map_size.y - 8))

func _refresh_label() -> void:
	var e := Registry.entry(location_id)
	_label.text = String(e.get("name", location_id))

func is_safe(pos: Vector3 = _hero_pos) -> bool:
	return Registry.in_safe_zone(location_id, pos)
