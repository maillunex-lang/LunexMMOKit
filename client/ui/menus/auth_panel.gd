extends Control
## UI02: login/register panel skinned with original Darklord Login atlas.

signal login_requested(login: String, password: String)
signal register_requested(login: String, password: String)
signal closed

const DlSkin = preload("res://ui/theme/darklord_skin.gd")

@onready var panel: PanelContainer = %Panel
@onready var title: TextureRect = %Title
@onready var bg: TextureRect = %Bg
@onready var login_edit: LineEdit = %LoginEdit
@onready var pass_edit: LineEdit = %PassEdit
@onready var btn_login: Button = %BtnLogin
@onready var btn_register: Button = %BtnRegister
@onready var btn_close: Button = %BtnClose
@onready var status: Label = %Status

func _ready() -> void:
	DlSkin.apply_to_tree(self)
	if bg:
		bg.texture = DlSkin.tex("Login/back_login.png")
	if title:
		title.texture = DlSkin.tex("Login/title1.png")
	panel.add_theme_stylebox_override("panel", DlSkin.style_tex("UICommon/frame1.png", 20))
	btn_login.add_theme_stylebox_override("normal", DlSkin.style_tex("Login/Login_kaishi.png", 8))
	btn_close.add_theme_stylebox_override("normal", DlSkin.style_tex("Login/btn_close.png", 4))
	btn_login.pressed.connect(func(): login_requested.emit(login_edit.text.strip_edges(), pass_edit.text))
	btn_register.pressed.connect(func(): register_requested.emit(login_edit.text.strip_edges(), pass_edit.text))
	btn_close.pressed.connect(func(): closed.emit(); visible = false)

func set_status(text: String) -> void:
	status.text = text
