extends RefCounted
class_name DarklordUISkin
## Applies original Darklord atlas sprites to Theme / HUD / menu controls.

const ROOT := "res://ui/darklord/sprites/"
const FONT := "res://ui/darklord/fonts/simhei.ttf"

static var _cache: Dictionary = {}

static func tex(rel: String) -> Texture2D:
	if _cache.has(rel):
		return _cache[rel]
	var path := ROOT + rel
	var abs := ProjectSettings.globalize_path(path)
	var tex_out: Texture2D = null
	if ResourceLoader.exists(path):
		var t = load(path)
		if t is Texture2D:
			tex_out = t
	if tex_out == null and FileAccess.file_exists(abs):
		var img := Image.new()
		var err := img.load(abs)
		if err == OK:
			tex_out = ImageTexture.create_from_image(img)
	_cache[rel] = tex_out
	return tex_out

static func style_tex(rel: String, margins: int = 12) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	var t := tex(rel)
	if t:
		sb.texture = t
	sb.texture_margin_left = margins
	sb.texture_margin_top = margins
	sb.texture_margin_right = margins
	sb.texture_margin_bottom = margins
	return sb

static func build_theme() -> Theme:
	var th := Theme.new()
	var font_abs := ProjectSettings.globalize_path(FONT)
	if FileAccess.file_exists(font_abs):
		var ff := FontFile.new()
		# Godot 4: load_dynamic_font reads TTF from absolute/res path
		if ff.has_method("load_dynamic_font"):
			ff.load_dynamic_font(font_abs)
			th.default_font = ff
		th.default_font_size = 18
	th.set_stylebox("panel", "PanelContainer", style_tex("UICommon/frame1.png", 18))
	th.set_stylebox("normal", "Button", style_tex("UICommon/btn_green.png", 10))
	th.set_stylebox("hover", "Button", style_tex("UICommon/btn_green.png", 10))
	th.set_stylebox("pressed", "Button", style_tex("UICommon/btn_black.png", 10))
	th.set_stylebox("disabled", "Button", style_tex("UICommon/btn_black.png", 10))
	th.set_color("font_color", "Button", Color(1, 0.95, 0.75))
	th.set_color("font_hover_color", "Button", Color(1, 1, 0.9))
	th.set_color("font_pressed_color", "Button", Color(0.9, 0.85, 0.6))
	th.set_color("font_color", "Label", Color(1, 0.96, 0.85))
	th.set_color("default_color", "RichTextLabel", Color(1, 0.96, 0.85))
	th.set_stylebox("normal", "LineEdit", style_tex("UICommon/back_name.png", 8))
	th.set_stylebox("focus", "LineEdit", style_tex("UICommon/back_name.png", 8))
	return th

static func apply_to_tree(root: Control) -> void:
	root.theme = build_theme()

static func skill_icon_for_slot(slot: int, class_key: String = "zhanshi") -> Texture2D:
	var rels: PackedStringArray = [
		"UIMain/Skill_%s_%d.png" % [class_key, slot + 1],
		"skillicon/mcskill_jianren%d.png" % (slot + 1),
		"skillicon/mcskill_cisha%d.png" % (slot + 1),
	]
	for rel in rels:
		var t := tex(rel)
		if t:
			return t
	return tex("UIMain/back_skill.png")
