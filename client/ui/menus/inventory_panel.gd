extends Control
## UI02: inventory window with original Darklord item frames / bag chrome.

signal closed

const DlSkin = preload("res://ui/theme/darklord_skin.gd")

@onready var panel: PanelContainer = %Panel
@onready var grid: GridContainer = %Grid
@onready var title: Label = %Title
@onready var btn_close: Button = %BtnClose

func _ready() -> void:
	DlSkin.apply_to_tree(self)
	panel.add_theme_stylebox_override("panel", DlSkin.style_tex("UICommon/frame1.png", 20))
	btn_close.add_theme_stylebox_override("normal", DlSkin.style_tex("Login/btn_close.png", 4))
	btn_close.pressed.connect(func(): closed.emit(); visible = false)
	_rebuild_slots(24)

func _rebuild_slots(count: int) -> void:
	for c in grid.get_children():
		c.queue_free()
	var slot_tex := DlSkin.tex("UICommon/back_coin_slot.png")
	var item_tex := DlSkin.tex("Item/back_ico.png")
	if item_tex == null:
		item_tex = DlSkin.tex("UIMain/back_ico.png")
	for i in count:
		var slot := TextureRect.new()
		slot.custom_minimum_size = Vector2(52, 52)
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.texture = slot_tex if slot_tex else item_tex
		grid.add_child(slot)

func set_items(paths: PackedStringArray) -> void:
	## Optional: fill first N slots with item icon textures.
	_rebuild_slots(maxi(24, paths.size()))
	for i in mini(paths.size(), grid.get_child_count()):
		var tr := grid.get_child(i) as TextureRect
		if tr and FileAccess.file_exists(paths[i]):
			tr.texture = load(paths[i])
