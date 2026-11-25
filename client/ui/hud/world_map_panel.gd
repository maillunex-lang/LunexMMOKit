extends Control
## W02: simple full-map overlay listing unlocked locations + player UV marker.

const Registry = preload("res://world/location_registry.gd")

signal travel_requested(location_id: String)

var location_id := "eternity_capital"
var _hero_pos := Vector3.ZERO
var _list: VBoxContainer
var _marker: Label

func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			hide_map())
	add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(80, 60)
	panel.custom_minimum_size = Vector2(360, 320)
	add_child(panel)
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	var title := Label.new()
	title.text = "Карта мира"
	vb.add_child(title)
	_marker = Label.new()
	vb.add_child(_marker)
	_list = VBoxContainer.new()
	vb.add_child(_list)
	var close := Button.new()
	close.text = "Закрыть"
	close.pressed.connect(hide_map)
	vb.add_child(close)
	rebuild()

func show_map(loc: String, hero: Vector3, unlocked: Array) -> void:
	location_id = loc
	_hero_pos = hero
	visible = true
	rebuild(unlocked)

func hide_map() -> void:
	visible = false

func rebuild(unlocked: Array = []) -> void:
	if _list == null:
		return
	for c in _list.get_children():
		c.queue_free()
	var uv := Registry.world_to_map_uv(location_id, _hero_pos)
	_marker.text = "%s · UV (%.2f, %.2f)%s" % [
		String(Registry.entry(location_id).get("name", location_id)),
		uv.x, uv.y,
		" · безопасная зона" if Registry.in_safe_zone(location_id, _hero_pos) else "",
	]
	for id in Registry.ids():
		var row := HBoxContainer.new()
		var lab := Label.new()
		lab.text = String(Registry.entry(String(id)).get("name", id))
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lab)
		var known := unlocked.is_empty() or unlocked.has(String(id)) or String(id) == location_id
		var btn := Button.new()
		btn.text = "Здесь" if String(id) == location_id else ("Открыто" if known else "???")
		btn.disabled = String(id) == location_id or not known
		var lid := String(id)
		btn.pressed.connect(func(): travel_requested.emit(lid))
		row.add_child(btn)
		_list.add_child(row)
