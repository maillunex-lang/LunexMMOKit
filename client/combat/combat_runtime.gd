extends Node
## FIX-008: single combat pipeline for play scenes.
## Wraps skill_timeline + preview_attack + hero_combat. LOCAL PROTOTYPE until server C01.
## Syncs: anim → hit/projectile event → damage apply → VFX/SFX → death.

const TimelineAttack = preload("res://combat/preview_attack.gd")
const SkillFxScript = preload("res://content/vfx/skill_fx.gd")

signal attack_started(kind: String)
signal attack_impact(kind: String, target: Node, damage: int)
signal attack_finished(kind: String)
signal prototype_warning

@export var prototype_banner := true

var hero_combat: Node
var skill_fx: Node
var attack: Node
var animator: AnimationPlayer
var actor_id: String = "10001"
var _busy := false

func setup(combat: Node, anim: AnimationPlayer, fx: Node = null) -> void:
	hero_combat = combat
	animator = anim
	if fx:
		skill_fx = fx
	elif skill_fx == null:
		skill_fx = SkillFxScript.new()
		skill_fx.name = "SkillFx"
		add_child(skill_fx)
	if attack == null:
		attack = TimelineAttack.new()
		attack.name = "PreviewAttack"
		add_child(attack)
		attack.impact.connect(_on_impact)
		attack.projectile.connect(_on_projectile)
	if prototype_banner:
		prototype_warning.emit()

var _pending: Dictionary = {}

func try_basic(origin: Vector3, yaw: float, tree: SceneTree, clip: String = "attack") -> Dictionary:
	if _busy or hero_combat == null:
		return {"ok": false, "reason": "busy"}
	var res: Dictionary = hero_combat.try_basic(origin, yaw, tree)
	if not res.get("ok", false):
		return res
	_begin("basic", res, clip, [{"time": 0.35, "kind": "hit"}])
	return res

func try_skill(slot: int, origin: Vector3, tree: SceneTree) -> Dictionary:
	if _busy or hero_combat == null:
		return {"ok": false, "reason": "busy"}
	var res: Dictionary = hero_combat.try_skill(slot, origin, tree)
	if not res.get("ok", false):
		return res
	# Damage already applied in hero_combat prototype — schedule VFX on timeline; undo premature? 
	# For unify: hero_combat still applies at call; timeline drives anim/VFX. Marked prototype.
	var anim := String(res.get("anim", "skill001"))
	var events: Array = [{"time": 0.4, "kind": "hit"}]
	if String(res.get("label", "")).to_lower().contains("стрел") or actor_id == "20001" or actor_id == "30001":
		events = [{"time": 0.25, "kind": "projectile"}, {"time": 0.55, "kind": "hit"}]
	_begin("skill%d" % slot, res, anim, events)
	return res

func cancel() -> void:
	_busy = false
	_pending = {}
	if attack and attack.has_method("cancel"):
		attack.cancel()

func _begin(kind: String, res: Dictionary, clip: String, events: Array) -> void:
	_pending = res.duplicate(true)
	_pending["kind"] = kind
	_busy = true
	attack_started.emit(kind)
	if skill_fx and is_instance_valid(get_parent()):
		var col: Color = skill_fx.color_for_actor(actor_id) if skill_fx.has_method("color_for_actor") else Color.WHITE
		var origin: Vector3 = Vector3.ZERO
		if get_tree():
			var hero := get_tree().get_first_node_in_group("player_hero")
			if hero is Node3D:
				origin = (hero as Node3D).global_position
		skill_fx.spawn_cast(origin, col)
	if animator and attack and attack.has_method("begin"):
		if not attack.begin(animator, clip, events, 1.0):
			# No clip — finish immediately with VFX only
			_finish_visual()
	else:
		_finish_visual()

func _on_impact(_kind: String = "hit") -> void:
	if _pending.is_empty():
		return
	var hit = _pending.get("hit")
	var dmg := int(_pending.get("damage", 0))
	if hit is Node3D and skill_fx:
		var col: Color = skill_fx.color_for_actor(actor_id) if skill_fx.has_method("color_for_actor") else Color.WHITE
		skill_fx.spawn_hit((hit as Node3D).global_position, col, 1.2)
	attack_impact.emit(String(_pending.get("kind", "")), hit if hit is Node else null, dmg)

func _on_projectile(_kind: String = "projectile") -> void:
	# Placeholder projectile cue; full projectile system wires in preview_projectile later.
	pass

func _process(_delta: float) -> void:
	if _busy and attack and not bool(attack.get("active")):
		_finish_visual()

func _finish_visual() -> void:
	var kind := String(_pending.get("kind", ""))
	_pending = {}
	_busy = false
	attack_finished.emit(kind)
