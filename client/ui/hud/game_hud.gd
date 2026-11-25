extends Control
## FIX-010: editable mobile HUD (.tscn). Keyboard remains optional shortcut, not required.

signal attack_pressed
signal skill_pressed(slot: int)
signal interact_pressed
signal portal_pressed
signal goto_pressed
signal graphics_pressed
signal joystick_moved(dir: Vector2)

@onready var hp_label: Label = %HpLabel
@onready var mp_label: Label = %MpLabel
@onready var quest_track: RichTextLabel = %QuestTrack
@onready var status: Label = %Status
@onready var joystick: Control = %Joystick
@onready var btn_attack: Button = %BtnAttack
@onready var btn_skill0: Button = %BtnSkill0
@onready var btn_skill1: Button = %BtnSkill1
@onready var btn_skill2: Button = %BtnSkill2
@onready var btn_interact: Button = %BtnInteract
@onready var btn_portal: Button = %BtnPortal
@onready var btn_goto: Button = %BtnGoto
@onready var settings_btn: Button = %SettingsBtn

var gfx_preset := 1 ## 0 Low 1 Med 2 High 3 Max

func _ready() -> void:
	if ResourceLoader.exists("res://ui/theme/lunex_theme.tres"):
		theme = load("res://ui/theme/lunex_theme.tres")
	btn_attack.pressed.connect(func(): attack_pressed.emit())
	btn_skill0.pressed.connect(func(): skill_pressed.emit(0))
	btn_skill1.pressed.connect(func(): skill_pressed.emit(1))
	btn_skill2.pressed.connect(func(): skill_pressed.emit(2))
	btn_interact.pressed.connect(func(): interact_pressed.emit())
	btn_portal.pressed.connect(func(): portal_pressed.emit())
	btn_goto.pressed.connect(func(): goto_pressed.emit())
	settings_btn.pressed.connect(_cycle_graphics)
	if joystick and joystick.has_signal("direction_changed"):
		joystick.direction_changed.connect(func(d): joystick_moved.emit(d))
	_apply_graphics(gfx_preset)

func _cycle_graphics() -> void:
	gfx_preset = (gfx_preset + 1) % 4
	_apply_graphics(gfx_preset)
	graphics_pressed.emit()

func _apply_graphics(preset: int) -> void:
	## FIX-010 / P01 stub — real LOD/particle caps land in P01. Xvfb FPS ≠ Android.
	var names: PackedStringArray = ["Low", "Med", "High", "Max"]
	var scales: Array[float] = [0.6, 0.8, 1.0, 1.0]
	var shadows_on: Array[bool] = [false, false, true, true]
	var scale: float = scales[preset]
	var shadows: bool = shadows_on[preset]
	if is_inside_tree():
		get_tree().root.content_scale_factor = scale
	settings_btn.text = "GFX " + names[preset]
	ProjectSettings.set_setting("lunex/graphics_preset", names[preset])
	ProjectSettings.set_setting("lunex/shadows_enabled", shadows)
	set_status("Графика: %s (stub; Android профили — P01)" % names[preset])

func set_vitals(hp: int, max_hp: int, mp: int, max_mp: int) -> void:
	hp_label.text = "HP %d/%d" % [hp, max_hp]
	mp_label.text = "MP %d/%d" % [mp, max_mp]

func set_quest(bbcode: String) -> void:
	quest_track.text = bbcode

func set_status(text: String) -> void:
	status.text = text

func set_skill_labels(labels: PackedStringArray) -> void:
	var buttons: Array[Button] = [btn_skill0, btn_skill1, btn_skill2]
	for i in buttons.size():
		if i < labels.size() and labels[i] != "":
			buttons[i].text = str(i + 1)
			buttons[i].tooltip_text = labels[i]
		else:
			buttons[i].text = str(i + 1)
