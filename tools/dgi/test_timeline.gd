extends SceneTree
const Timeline = preload("res://skill_timeline.gd")
func _initialize():
	var failures := 0
	for row in [["mage","projectile",0.5],["archer","hit",0.3],["warrior","hit",0.15],["assassin","hit",0.4]]:
		for speed in [0.5,1.0,2.0]:
			var t := Timeline.new()
			var received := []
			var hp := [100]
			t.event_due.connect(func(kind,stamp):
				received.append([kind,stamp])
				if kind=="hit": hp[0]-=10)
			t.start([{"kind":row[1],"time":row[2]}])
			t.advance(row[2]/speed-0.001,speed)
			if not received.is_empty(): failures+=1
			t.advance(0.002,speed)
			t.advance(1.0,speed)
			if received.size()!=1 or hp[0]!=(90 if row[1]=="hit" else 100): failures+=1
			print(row[0]," speed=",speed," events=",received," dummy_hp=",hp[0])
	var cancelled := Timeline.new()
	var count := [0]
	cancelled.event_due.connect(func(_k,_s): count[0]+=1)
	cancelled.start([{"kind":"hit","time":0.4}])
	cancelled.cancel()
	cancelled.advance(1.0,1.0)
	if count[0]!=0: failures+=1
	print("FAILURES=",failures)
	quit(failures)
