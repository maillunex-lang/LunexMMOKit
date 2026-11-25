extends VBoxContainer

## Shared Attachment System editor panel (Studio + future Asset Library).
## Edits AttachmentOffset resources; save writes user:// overrides consumed by runtime.

const Library = preload("res://actors/attachment_library.gd")
const OffsetScript = preload("res://actors/attachment_offset.gd")

signal saved(offset: Resource)
signal reset_done(kind: String, equipment_id: String)

var current: Resource
var target_node: Node3D
var kind_edit: LineEdit
var equipment_edit: LineEdit
var class_edit: LineEdit
var child_edit: LineEdit
var socket_edit: LineEdit
var pos_x: SpinBox
var pos_y: SpinBox
var pos_z: SpinBox
var rot_x: SpinBox
var rot_y: SpinBox
var rot_z: SpinBox
var scl_x: SpinBox
var scl_y: SpinBox
var scl_z: SpinBox
var status: Label
var _busy := false

func _ready() -> void:
	_build()

func _spin(min_v: float, max_v: float, step: float, val: float) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.value = val
	s.custom_minimum_size.x = 96
	s.value_changed.connect(_on_value_changed)
	return s

func _row(label: String, a: Control, b: Control = null, c: Control = null) -> void:
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.custom_minimum_size.x = 72
	h.add_child(l)
	h.add_child(a)
	if b: h.add_child(b)
	if c: h.add_child(c)
	add_child(h)

func _build() -> void:
	var title := Label.new()
	title.text = "Крепления (Attachment System)"
	add_child(title)
	kind_edit = LineEdit.new(); kind_edit.placeholder_text = "kind"
	equipment_edit = LineEdit.new(); equipment_edit.placeholder_text = "equipment_id"
	class_edit = LineEdit.new(); class_edit.placeholder_text = "class_id"
	child_edit = LineEdit.new(); child_edit.placeholder_text = "child_name"
	socket_edit = LineEdit.new(); socket_edit.placeholder_text = "socket"
	_row("kind/eq", kind_edit, equipment_edit)
	_row("class/child", class_edit, child_edit)
	_row("socket", socket_edit)
	pos_x = _spin(-5, 5, 0.001, 0); pos_y = _spin(-5, 5, 0.001, 0); pos_z = _spin(-5, 5, 0.001, 0)
	rot_x = _spin(-180, 180, 0.1, 0); rot_y = _spin(-180, 180, 0.1, 0); rot_z = _spin(-180, 180, 0.1, 0)
	scl_x = _spin(-5, 5, 0.01, 1); scl_y = _spin(-5, 5, 0.01, 1); scl_z = _spin(-5, 5, 0.01, 1)
	_row("pos", pos_x, pos_y, pos_z)
	_row("rot°", rot_x, rot_y, rot_z)
	_row("scale", scl_x, scl_y, scl_z)
	var buttons := HBoxContainer.new()
	var load_btn := Button.new(); load_btn.text = "Загрузить"; load_btn.pressed.connect(load_current)
	var save_btn := Button.new(); save_btn.text = "Сохранить"; save_btn.pressed.connect(save_current)
	var reset_btn := Button.new(); reset_btn.text = "Сброс"; reset_btn.pressed.connect(reset_current)
	buttons.add_child(load_btn); buttons.add_child(save_btn); buttons.add_child(reset_btn)
	add_child(buttons)
	status = Label.new(); status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status)

func bind_node(node: Node3D) -> void:
	target_node = node

func set_context(kind: String, equipment_id: String, class_id: String = "", child_name: String = "") -> void:
	kind_edit.text = kind
	equipment_edit.text = equipment_id
	class_edit.text = class_id
	child_edit.text = child_name
	load_current()

func load_current() -> void:
	_busy = true
	current = Library.load_offset(kind_edit.text, equipment_edit.text, class_edit.text, child_edit.text)
	if current == null:
		current = OffsetScript.new()
		current.kind = kind_edit.text
		current.equipment_id = equipment_edit.text
		current.class_id = class_edit.text
		current.child_name = child_edit.text
		status.text = "Новый offset (нет default)"
	else:
		status.text = "Загружено: " + str(current.attachment_id)
	socket_edit.text = str(current.socket)
	pos_x.value = current.position.x; pos_y.value = current.position.y; pos_z.value = current.position.z
	rot_x.value = current.rotation_degrees.x; rot_y.value = current.rotation_degrees.y; rot_z.value = current.rotation_degrees.z
	scl_x.value = current.scale.x; scl_y.value = current.scale.y; scl_z.value = current.scale.z
	_busy = false
	_apply_to_node()

func _on_value_changed(_v: float = 0.0) -> void:
	if _busy or current == null:
		return
	current.position = Vector3(pos_x.value, pos_y.value, pos_z.value)
	current.rotation_degrees = Vector3(rot_x.value, rot_y.value, rot_z.value)
	current.scale = Vector3(scl_x.value, scl_y.value, scl_z.value)
	current.socket = socket_edit.text
	current.kind = kind_edit.text
	current.equipment_id = equipment_edit.text
	current.class_id = class_edit.text
	current.child_name = child_edit.text
	_apply_to_node()

func _apply_to_node() -> void:
	if target_node != null and is_instance_valid(target_node) and current != null:
		target_node.transform = current.to_transform()

func save_current() -> void:
	_on_value_changed()
	if current == null:
		return
	var err := Library.save_override(current)
	status.text = "Сохранено override" if err == OK else "Ошибка сохранения "+str(err)
	if err == OK:
		saved.emit(current)

func reset_current() -> void:
	Library.reset_override(kind_edit.text, equipment_edit.text, class_edit.text, child_edit.text)
	load_current()
	reset_done.emit(kind_edit.text, equipment_edit.text)
	status.text = "Сброс к default ресурсу"
