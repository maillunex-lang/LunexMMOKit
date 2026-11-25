extends SceneTree
func _initialize(): call_deferred("run")
func fail(msg: String) -> void:
	print("QUEST_SMOKE_FAIL ", msg)
	quit(1)
func run():
	var log = load("res://content/quests/quest_log.gd").new()
	root.add_child(log)
	log.load_catalog()
	if log.catalog.size() < 4: fail("catalog"); return
	if log.offer_from_npc("npc_plazaguard_l") != "q_ch1_01_audience": fail("start q01"); return
	log.notify_talk("npc_plazaelder")
	if not ("q_ch1_01_audience" in log.completed): fail("complete q01"); return
	# notify_talk may already auto-offer q02 from elder
	if not log.active.has("q_ch1_02_market_rumors"):
		if log.offer_from_npc("npc_plazaelder") != "q_ch1_02_market_rumors":
			fail("start q02 active="+str(log.active.keys())); return
	log.notify_talk("npc_questgiver_0")
	if not ("q_ch1_02_market_rumors" in log.completed): fail("complete q02"); return
	if not log.active.has("q_ch1_03_first_shardlings"):
		if log.offer_from_npc("npc_questgiver_0") != "q_ch1_03_first_shardlings":
			fail("start q03"); return
	log.notify_kill("mob_shardling", 3)
	if not ("q_ch1_03_first_shardlings" in log.completed): fail("complete q03"); return
	if not log.active.has("q_ch1_04_ashen_gate"):
		if log.offer_from_npc("npc_questgiver_0") != "q_ch1_04_ashen_gate":
			fail("start q04"); return
	log.notify_goto("portal_ashen_gate")
	log.notify_talk("npc_ashen_warden")
	if not ("q_ch1_04_ashen_gate" in log.completed): fail("complete q04 active="+str(log.active)); return
	print("QUEST_SMOKE_OK xp=", log.xp, " completed=", log.completed.size())
	quit(0)
