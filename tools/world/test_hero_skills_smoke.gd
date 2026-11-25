extends SceneTree
## Verify Darklord-extracted class baseline loads and skill CDs/damage exist.

func _initialize():
	call_deferred("run")

func fail(msg: String) -> void:
	print("HERO_SMOKE_FAIL ", msg)
	quit(1)

func run():
	var kit = load("res://content/heroes/hero_kit.gd").new()
	kit.load_data()
	if kit.by_actor.size() != 4:
		fail("expected 4 classes got %d" % kit.by_actor.size())
		return
	for aid in ["10001", "20001", "30001", "40001"]:
		var c: Dictionary = kit.class_of(aid)
		if c.is_empty():
			fail("missing " + aid)
			return
		if int(c.get("init_hp", 0)) < 1000:
			fail("init_hp " + aid)
			return
		var bar: Array = kit.hotbar(aid)
		if bar.size() < 3:
			fail("hotbar " + aid)
			return
		for s in bar:
			if int(s.get("cd_ms", 0)) <= 0:
				fail("cd " + aid + " " + str(s.get("id")))
				return
			if int(s.get("slice_damage", 0)) <= 0:
				fail("dmg " + aid)
				return
	var combat = load("res://actors/hero_combat.gd").new()
	root.add_child(combat)
	combat.setup(kit, "10001")
	if combat.hp != combat.max_hp or combat.max_hp <= 0:
		fail("hp setup")
		return
	print("HERO_SMOKE_OK classes=4 warrior_hp=", combat.max_hp, " skills=", kit.hotbar("10001").size())
	quit(0)
