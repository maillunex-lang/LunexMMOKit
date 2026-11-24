extends RefCounted
signal event_due(kind: String, source_time: float)
var elapsed := 0.0
var cursor := 0
var events: Array = []
func start(sequence: Array) -> void:
	events = sequence.duplicate(true)
	events.sort_custom(func(a,b): return a.time < b.time)
	elapsed = 0.0
	cursor = 0
func advance(delta: float, speed: float) -> void:
	elapsed += maxf(delta,0.0) * maxf(speed,0.0)
	while cursor < events.size() and float(events[cursor].time) <= elapsed + 0.000001:
		var event: Dictionary = events[cursor]
		cursor += 1
		event_due.emit(event.kind,float(event.time))
func cancel() -> void:
	events.clear()
	cursor = 0
