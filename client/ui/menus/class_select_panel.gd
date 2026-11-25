extends Control
## UI02: four Darklord classes with original role fonts / frames.

signal class_chosen(actor_id: String, class_index: int)
signal closed

const DlSkin = preload("res://ui/theme/darklord_skin.gd")

const CLASSES := [
	{"actor_id": "10001", "name": "Воин", "font": "Login/font_role1.png", "key": "zhanshi"},
	{"actor_id": "20001", "name": "Лучник", "font": "Login/font_role2.png", "key": "gongjian"},
	{"actor_id": "30001", "name": "Маг", "font": "Login/font_role3.png", "key": "fashi"},
	{"actor_id": "40001", "name": "Ассасин", "font": "Login/font_role4.png", "key": "cike"},
]

@onready var panel: PanelContainer = %Panel
@onready var row: HBoxContainer = %Row
@onready var status: Label = %Status

func _ready() -> void:
	DlSkin.apply_to_tree(self)
	panel.add_theme_stylebox_override("panel", DlSkin.style_tex("UICommon/frame2.png", 18))
	for i in CLASSES.size():
		var c: Dictionary = CLASSES[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(110, 140)
		b.text = String(c.name)
		var ic := DlSkin.tex(String(c.font))
		if ic:
			b.icon = ic
			b.expand_icon = true
		b.add_theme_stylebox_override("normal", DlSkin.style_tex("Login/back_type.png", 10))
		b.add_theme_stylebox_override("hover", DlSkin.style_tex("Login/back_chosen.png", 10))
		var idx := i
		var actor := String(c.actor_id)
		b.pressed.connect(func():
			class_chosen.emit(actor, idx)
			status.text = "Выбран: " + String(c.name)
		)
		row.add_child(b)

func _on_close() -> void:
	closed.emit()
	visible = false
