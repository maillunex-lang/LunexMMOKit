extends Control
class_name LunexJoystick
## Darklord-skinned virtual joystick (original UIMain joystick sprites).

signal direction_changed(direction: Vector2)

@export_range(16.0, 200.0) var radius := 72.0
@export_range(0.0, 0.9) var deadzone := 0.15

var direction := Vector2.ZERO
var finger := -1
var _back: Texture2D
var _thumb: Texture2D

func _ready() -> void:
	_back = _load_tex("res://ui/darklord/sprites/UIMain/joystick_back.png")
	_thumb = _load_tex("res://ui/darklord/sprites/UIMain/joystick_thumb.png")

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var t = load(path)
		if t is Texture2D:
			return t
	var abs := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs):
		var img := Image.new()
		if img.load(abs) == OK:
			return ImageTexture.create_from_image(img)
	return null

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1:
			finger = event.index
			update_direction(event.position)
			accept_event()
		elif not event.pressed and event.index == finger:
			reset()
			accept_event()
	elif event is InputEventScreenDrag and event.index == finger:
		update_direction(event.position)
		accept_event()

func update_direction(point: Vector2) -> void:
	var raw := ((point - size * 0.5) / radius).limit_length()
	direction = Vector2.ZERO if raw.length() < deadzone else raw
	direction_changed.emit(direction)
	queue_redraw()

func reset() -> void:
	finger = -1
	direction = Vector2.ZERO
	direction_changed.emit(direction)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		reset()

func _draw() -> void:
	var c := size * 0.5
	if _back:
		var s := Vector2(radius * 2.2, radius * 2.2)
		draw_texture_rect(_back, Rect2(c - s * 0.5, s), false)
	else:
		draw_circle(c, radius, Color(0.15, 0.19, 0.25, 0.55))
	var thumb_pos := c + direction * radius
	if _thumb:
		var ts := Vector2(radius * 0.95, radius * 0.95)
		draw_texture_rect(_thumb, Rect2(thumb_pos - ts * 0.5, ts), false)
	else:
		draw_circle(thumb_pos, radius * 0.36, Color(0.85, 0.8, 0.65, 0.85))
