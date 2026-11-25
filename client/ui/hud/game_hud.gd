extends Control
## FIX-010 / UI02: Darklord-skinned mobile HUD (original frames, bars, skill icons).

signal attack_pressed
signal skill_pressed(slot: int)
signal interact_pressed
signal portal_pressed
signal goto_pressed
signal graphics_pressed
signal joystick_moved(dir: Vector2)
signal inventory_pressed
signal menu_pressed

const DlSkin = preload("res://ui/theme/darklord_skin.gd")

@onready var hp_label: Label = %HpLabel
@onready var mp_label: Label = %MpLabel
@onready var quest_track: RichTextLabel = %QuestTrack
@onready var status: Label = %Status
@onready var joystick: Control = %Joystick
@onready var btn_attack: BaseButton = %BtnAttack
@onready var btn_skill0: BaseButton = %BtnSkill0
@onready var btn_skill1: BaseButton = %BtnSkill1
@onready var btn_skill2: BaseButton = %BtnSkill2
@onready var btn_interact: BaseButton = %BtnInteract
@onready var btn_portal: BaseButton = %BtnPortal
@onready var btn_goto: BaseButton = %BtnGoto
@onready var settings_btn: BaseButton = %SettingsBtn
@onready var hp_bar: TextureProgressBar = %HpBar
@onready var mp_bar: TextureProgressBar = %MpBar
@onready var exp_bar: TextureProgressBar = %ExpBar
@onready var quest_panel: PanelContainer = %QuestPanel
@onready var top_frame: TextureRect = %TopFrame
@onready var btn_bag: BaseButton = %BtnBag

var gfx_preset := 1
var class_key := "zhanshi"

func _ready() -> void:
	DlSkin.apply_to_tree(self)
	_skin_chrome()
	btn_attack.pressed.connect(func(): attack_pressed.emit())
	btn_skill0.pressed.connect(func(): skill_pressed.emit(0))
	btn_skill1.pressed.connect(func(): skill_pressed.emit(1))
	btn_skill2.pressed.connect(func(): skill_pressed.emit(2))
	btn_interact.pressed.connect(func(): interact_pressed.emit())
	btn_portal.pressed.connect(func(): portal_pressed.emit())
	btn_goto.pressed.connect(func(): goto_pressed.emit())
	settings_btn.pressed.connect(_cycle_graphics)
	if btn_bag:
		btn_bag.pressed.connect(func(): inventory_pressed.emit())
	if joystick and joystick.has_signal("direction_changed"):
		joystick.direction_changed.connect(func(d): joystick_moved.emit(d))
	_apply_skill_icons()
	_apply_graphics(gfx_preset)

func _skin_chrome() -> void:
	var frame := DlSkin.tex("UICommon/frame1.png")
	var top := DlSkin.tex("UICommon/back_top.png")
	var hp_fill := DlSkin.tex("NewHP/hpbar_1.png")
	var hp_bg := DlSkin.tex("NewHP/hpbar_bg.png")
	var mp_fill := DlSkin.tex("NewHP/NewCommonHP_Green.png")
	var exp_fill := DlSkin.tex("UICommon/bar_exp.png")
	var exp_bg := DlSkin.tex("UICommon/bar_exp_slot.png")
	var atk_bg := DlSkin.tex("UIMain/back_attak_normal.png")
	var skill_bg := DlSkin.tex("UIMain/back_skill.png")
	if top_frame and top:
		top_frame.texture = top
	if quest_panel:
		quest_panel.add_theme_stylebox_override("panel", DlSkin.style_tex("UIMain/back_task.png", 14))
	if hp_bar:
		if hp_bg:
			hp_bar.texture_under = hp_bg
		if hp_fill:
			hp_bar.texture_progress = hp_fill
	if mp_bar:
		if hp_bg:
			mp_bar.texture_under = hp_bg
		if mp_fill:
			mp_bar.texture_progress = mp_fill
	if exp_bar:
		if exp_bg:
			exp_bar.texture_under = exp_bg
		if exp_fill:
			exp_bar.texture_progress = exp_fill
	_style_icon_button(btn_attack, atk_bg, "Атака")
	_style_icon_button(btn_interact, DlSkin.tex("UICommon/btn_green.png"), "Говорить")
	_style_icon_button(btn_portal, DlSkin.tex("UICommon/btn_black.png"), "Портал")
	_style_icon_button(btn_goto, DlSkin.tex("UICommon/btn_green.png"), "К цели")
	_style_icon_button(settings_btn, DlSkin.tex("UICommon/btn_circle.png"), "GFX")
	_style_icon_button(btn_bag, DlSkin.tex("UIMain/back_Equip.png"), "Сумка")
	for b in [btn_skill0, btn_skill1, btn_skill2]:
		if b and skill_bg:
			_style_icon_button(b, skill_bg, "")

func _style_icon_button(btn: BaseButton, tex: Texture2D, caption: String) -> void:
	if btn == null:
		return
	if btn is TextureButton and tex:
		(btn as TextureButton).texture_normal = tex
		(btn as TextureButton).ignore_texture_size = true
		(btn as TextureButton).stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	elif tex:
		var sb := StyleBoxTexture.new()
		sb.texture = tex
		sb.texture_margin_left = 8
		sb.texture_margin_top = 8
		sb.texture_margin_right = 8
		sb.texture_margin_bottom = 8
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
	if caption != "" and btn is Button:
		(btn as Button).text = caption

func _apply_skill_icons() -> void:
	var buttons: Array[BaseButton] = [btn_skill0, btn_skill1, btn_skill2]
	for i in buttons.size():
		var ic := DlSkin.skill_icon_for_slot(i, class_key)
		if ic == null:
			continue
		var b := buttons[i]
		if b is TextureButton:
			(b as TextureButton).texture_normal = ic
		elif b is Button:
			# overlay icon via theme icon
			(b as Button).icon = ic
			(b as Button).expand_icon = true
			(b as Button).text = ""

func set_class_key(key: String) -> void:
	class_key = key
	_apply_skill_icons()

func _cycle_graphics() -> void:
	gfx_preset = (gfx_preset + 1) % 4
	_apply_graphics(gfx_preset)
	graphics_pressed.emit()

func _apply_graphics(preset: int) -> void:
	var names: PackedStringArray = ["Low", "Med", "High", "Max"]
	var scales: Array[float] = [0.6, 0.8, 1.0, 1.0]
	var shadows_on: Array[bool] = [false, false, true, true]
	if is_inside_tree():
		get_tree().root.content_scale_factor = scales[preset]
	if settings_btn is Button:
		(settings_btn as Button).text = "GFX " + names[preset]
	ProjectSettings.set_setting("lunex/graphics_preset", names[preset])
	ProjectSettings.set_setting("lunex/shadows_enabled", shadows_on[preset])
	set_status("Графика: %s" % names[preset])

func set_vitals(hp: int, max_hp: int, mp: int, max_mp: int) -> void:
	hp_label.text = "HP %d/%d" % [hp, max_hp]
	mp_label.text = "MP %d/%d" % [mp, max_mp]
	if hp_bar:
		hp_bar.max_value = maxi(max_hp, 1)
		hp_bar.value = hp
	if mp_bar:
		mp_bar.max_value = maxi(max_mp, 1)
		mp_bar.value = mp

func set_exp(xp: int, xp_max: int = 100) -> void:
	if exp_bar:
		exp_bar.max_value = maxi(xp_max, 1)
		exp_bar.value = xp

func set_quest(bbcode: String) -> void:
	quest_track.text = bbcode

func set_status(text: String) -> void:
	status.text = text

func set_skill_labels(labels: PackedStringArray) -> void:
	var buttons: Array[BaseButton] = [btn_skill0, btn_skill1, btn_skill2]
	for i in buttons.size():
		if buttons[i] is Button and i < labels.size() and labels[i] != "":
			buttons[i].tooltip_text = labels[i]
	_apply_skill_icons()
