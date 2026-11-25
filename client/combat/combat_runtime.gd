extends Node
## FIX-008: single combat pipeline. Damage applies on timeline hit / projectile arrive.
## LOCAL PROTOTYPE until authoritative server C01.

const TimelineAttack = preload("res://combat/preview_attack.gd")
const ProjectileScript = preload("res://combat/preview_projectile.gd")
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
var _pending: Dictionary = {}
var _damage_applied := false
var _awaiting_projectile := false

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
		if not attack.impact.is_connected(_on_impact):
			attack.impact.connect(_on_impact)
		if not attack.projectile.is_connected(_on_projectile):
			attack.projectile.connect(_on_projectile)
	if prototype_banner:
		prototype_warning.emit()

func try_basic(origin: Vector3, yaw: float, tree: SceneTree, clip: String = "attack") -> Dictionary:
	if _busy or hero_combat == null:
		return {"ok": false, "reason": "busy"}
	var res: Dictionary = hero_combat.try_basic(origin, yaw, tree, false)
	if not res.get("ok", false):
		return res
	_begin("basic", res, clip, [{"time": 0.35, "kind": "hit"}], false)
	return res

func try_skill(slot: int, origin: Vector3, tree: SceneTree) -> Dictionary:
	if _busy or hero_combat == null:
		return {"ok": false, "reason": "busy"}
	var res: Dictionary = hero_combat.try_skill(slot, origin, tree, false)
	if not res.get("ok", false):
		return res
	var anim := String(res.get("anim", "skill001"))
	var ranged := actor_id == "20001" or actor_id == "30001" \
		or String(res.get("label", "")).to_lower().contains("стрел") \
		or String(res.get("label", "")).to_lower().contains("шар")
	var events: Array
	if ranged and res.get("hit") != null:
		events = [{"time": 0.25, "kind": "projectile"}]
		_begin("skill%d" % slot, res, anim, events, true)
	else:
		events = [{"time": 0.4, "kind": "hit"}]
		_begin("skill%d" % slot, res, anim, events, false)
	return res

func cancel() -> void:
	_busy = false
	_pending = {}
	_damage_applied = false
	_awaiting_projectile = false
	if attack and attack.has_method("cancel"):
		attack.cancel()

func _begin(kind: String, res: Dictionary, clip: String, events: Array, wait_projectile: bool) -> void:
	_pending = res.duplicate(true)
	_pending["kind"] = kind
	_busy = true
	_damage_applied = false
	_awaiting_projectile = wait_projectile
	attack_started.emit(kind)
	if skill_fx:
		var col: Color = skill_fx.color_for_actor(actor_id) if skill_fx.has_method("color_for_actor") else Color.WHITE
		var origin := Vector3.ZERO
		var hero := get_tree().get_first_node_in_group("player_hero") if get_tree() else null
		if hero is Node3D:
			origin = (hero as Node3D).global_position
		skill_fx.spawn_cast(origin, col)
	if animator and attack and attack.has_method("begin"):
		if not attack.begin(animator, clip, events, 1.0):
			_resolve_without_anim()
	else:
		_resolve_without_anim()

func _resolve_without_anim() -> void:
	if _awaiting_projectile:
		_on_projectile()
	else:
		_on_impact()
		_finish_visual()

func _apply_pending_damage() -> void:
	if _damage_applied or _pending.is_empty():
		return
	var hit = _pending.get("hit")
	var dmg := int(_pending.get("damage", 0))
	if hit != null and hero_combat and hero_combat.has_method("apply_hit"):
		hero_combat.apply_hit(hit, dmg)
		_damage_applied = true
	if hit is Node3D and skill_fx:
		var col: Color = skill_fx.color_for_actor(actor_id) if skill_fx.has_method("color_for_actor") else Color.WHITE
		skill_fx.spawn_hit((hit as Node3D).global_position, col, 1.2)
	attack_impact.emit(String(_pending.get("kind", "")), hit if hit is Node else null, dmg)

func _on_impact(_kind: String = "hit") -> void:
	if _awaiting_projectile:
		return
	_apply_pending_damage()

func _on_projectile(_kind: String = "projectile") -> void:
	var hit = _pending.get("hit")
	if not (hit is Node3D):
		_awaiting_projectile = false
		_apply_pending_damage()
		_finish_visual()
		return
	var hero := get_tree().get_first_node_in_group("player_hero") if get_tree() else null
	var proj: Node3D = ProjectileScript.new()
	proj.name = "SkillProjectile"
	var parent: Node = get_parent() if get_parent() else self
	parent.add_child(proj)
	if hero is Node3D:
		proj.global_position = (hero as Node3D).global_position + Vector3(0, 1.2, 0)
	else:
		proj.global_position = (hit as Node3D).global_position + Vector3(0, 1.2, -2)
	proj.target = hit
	proj.speed = 14.0
	proj.lifetime = 1.2
	# Visual cue
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	mi.mesh = sphere
	proj.add_child(mi)
	proj.arrived.connect(func():
		_awaiting_projectile = false
		_apply_pending_damage()
		_finish_visual())
	proj.expired.connect(func():
		_awaiting_projectile = false
		_finish_visual())

func _process(_delta: float) -> void:
	if _busy and not _awaiting_projectile and attack and not bool(attack.get("active")):
		if not _damage_applied and not _pending.is_empty():
			_apply_pending_damage()
		_finish_visual()

func _finish_visual() -> void:
	if _awaiting_projectile:
		return
	var kind := String(_pending.get("kind", ""))
	_pending = {}
	_busy = false
	_damage_applied = false
	attack_finished.emit(kind)
