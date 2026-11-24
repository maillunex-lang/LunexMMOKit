extends Node
const Timeline = preload("skill_timeline.gd")
signal impact
signal projectile
var timeline := Timeline.new()
var player: AnimationPlayer
var active := false
func _ready():
	timeline.event_due.connect(func(kind,_stamp):
		if kind == "hit": impact.emit()
		elif kind == "projectile": projectile.emit())
func begin(p: AnimationPlayer, clip: String, events: Array, speed: float = 1.0) -> bool:
	if not p.has_animation(clip) or speed <= 0: return false
	player = p
	timeline.start(events)
	player.play(clip,-1,speed)
	player.seek(0,true)
	active = true
	return true
func _process(_delta):
	if not active or not is_instance_valid(player): return
	var position := player.current_animation_position
	timeline.advance(maxf(0.0,position-timeline.elapsed),1.0)
	if not player.is_playing(): active = false
func cancel():
	active = false
	timeline.cancel()
	if is_instance_valid(player): player.stop()
