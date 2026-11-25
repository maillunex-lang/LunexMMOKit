extends Node
## Client-side skill bar for vertical slice. CDs/ranges/damage from Darklord-extracted baseline.
## Server authority comes later (N02/C01); this is presentation + local dummy combat.

signal hp_changed(hp: int, max_hp: int)
signal mp_changed(mp: int, max_mp: int)
signal skill_used(slot: int, skill_id: int)
signal died

var actor_id: String = "10001"
var kit
var max_hp: int = 500
var hp: int = 500
var max_mp: int = 100
var mp: int = 100
var atk: int = 35
var _cd_left: Array[float] = [0.0, 0.0, 0.0]
var _gcd: float = 0.0
var _basic_cd: float = 0.0

func setup(hero_kit, new_actor_id: String) -> void:
	kit = hero_kit
	actor_id = new_actor_id
	var c: Dictionary = kit.class_of(actor_id)
	max_hp = int(c.get("slice_hp", 500))
	hp = max_hp
	max_mp = int(c.get("slice_mp", 100))
	mp = max_mp
	atk = int(c.get("slice_atk", 35))
	_cd_left = [0.0, 0.0, 0.0]
	_gcd = 0.0
	_basic_cd = 0.0
	hp_changed.emit(hp, max_hp)
	mp_changed.emit(mp, max_mp)

func _process(delta: float) -> void:
	_gcd = maxf(0.0, _gcd - delta)
	_basic_cd = maxf(0.0, _basic_cd - delta)
	for i in _cd_left.size():
		_cd_left[i] = maxf(0.0, _cd_left[i] - delta)

func cd_left(slot: int) -> float:
	if slot < 0 or slot >= _cd_left.size():
		return 0.0
	return _cd_left[slot]

func apply_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp = maxi(0, hp - amount)
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		died.emit()

func heal_full() -> void:
	hp = max_hp
	mp = max_mp
	hp_changed.emit(hp, max_hp)
	mp_changed.emit(mp, max_mp)

func try_basic(origin: Vector3, facing_yaw: float, tree: SceneTree, apply_now: bool = false) -> Dictionary:
	if _gcd > 0.0 or _basic_cd > 0.0 or kit == null:
		return {"ok": false, "reason": "cd"}
	var sk: Dictionary = kit.basic(actor_id)
	if sk.is_empty():
		return {"ok": false, "reason": "no_skill"}
	var dmg := int(sk.get("slice_damage", atk))
	var rng := float(sk.get("slice_range", 3.0))
	var hit := find_nearest_target(origin, rng, tree)
	if apply_now and hit:
		apply_hit(hit, dmg)
	_basic_cd = maxf(0.35, float(sk.get("cd_ms", 0)) / 1000.0)
	_gcd = 0.35
	return {"ok": true, "skill": sk, "hit": hit, "damage": dmg, "anim": "attack", "applied": apply_now}

func try_skill(slot: int, origin: Vector3, tree: SceneTree, apply_now: bool = false) -> Dictionary:
	if kit == null or slot < 0 or slot > 2:
		return {"ok": false, "reason": "bad_slot"}
	if _gcd > 0.0 or _cd_left[slot] > 0.0:
		return {"ok": false, "reason": "cd"}
	var bar: Array = kit.hotbar(actor_id)
	if slot >= bar.size():
		return {"ok": false, "reason": "empty"}
	var sk: Dictionary = bar[slot]
	var cost := int(sk.get("consum_num", 0) or 0)
	# consume_type: often MP; slice treats any cost as MP
	if cost > 0 and mp < cost:
		return {"ok": false, "reason": "mp"}
	var dmg := int(sk.get("slice_damage", atk))
	var rng := float(sk.get("slice_range", sk.get("min_dis", 3.0)))
	var hit := find_nearest_target(origin, rng, tree)
	if cost > 0:
		mp = maxi(0, mp - cost)
		mp_changed.emit(mp, max_mp)
	_cd_left[slot] = float(sk.get("cd_ms", 6000)) / 1000.0
	_gcd = 0.45
	skill_used.emit(slot, int(sk.get("id", 0)))
	if apply_now and hit:
		apply_hit(hit, dmg)
	var anim := "skill00%d" % (slot + 1)
	return {"ok": true, "skill": sk, "hit": hit, "damage": dmg, "anim": anim, "label": String(sk.get("label", "")), "applied": apply_now}

func apply_hit(target: Node, dmg: int) -> bool:
	## Called on timeline hit / projectile arrive (FIX-008). LOCAL PROTOTYPE until C01.
	if target == null or not is_instance_valid(target):
		return false
	if target.has_method("apply_damage"):
		target.apply_damage(dmg)
		return true
	return false

func find_nearest_target(origin: Vector3, rng: float, tree: SceneTree) -> Node:
	var best: Node = null
	var best_d := rng
	for n in tree.get_nodes_in_group("hostile"):
		if n is Node3D and n.has_method("apply_damage"):
			var d: float = origin.distance_to((n as Node3D).global_position)
			if d <= best_d:
				best_d = d
				best = n
	if best == null:
		var root := tree.current_scene
		if root:
			for c in root.get_children():
				if c.has_method("apply_damage") and c is Node3D:
					var d2: float = origin.distance_to(c.global_position)
					if d2 <= best_d:
						best_d = d2
						best = c
	return best
