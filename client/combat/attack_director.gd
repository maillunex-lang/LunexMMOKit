extends Node
## A02: single-flight attack director — AnimationPlayer + XML timeline + one-shot VFX/audio.
## Guarantees at most one impact/projectile emission per begin(); cancel interrupts cleanly.

const Timeline = preload("res://combat/skill_timeline.gd")
const SkillEvents = preload("res://combat/skill_events_library.gd")
const SkillFx = preload("res://content/vfx/skill_fx.gd")
const VfxCatalog = preload("res://content/vfx/vfx_catalog.gd")
const ParticlePreview = preload("res://content/vfx/particle_preview.gd")

signal impact
signal projectile
signal finished
signal cancelled

var timeline := Timeline.new()
var player: AnimationPlayer
var active := false
var _emitted := false
var _fx_host: Node
var _particle_fx: Node
var _actor_id := ""
var _source_root := ""
var _audio: AudioStreamPlayer3D

func _ready() -> void:
	timeline.event_due.connect(_on_event)

func _on_event(kind: String, _stamp: float) -> void:
	if not active or _emitted:
		return
	_emitted = true
	_spawn_fx()
	_play_audio()
	if kind == "hit":
		impact.emit()
	elif kind == "projectile":
		projectile.emit()

func begin(p: AnimationPlayer, actor_id: String, clip: String = "attack001", speed: float = 1.0, source_root: String = "") -> bool:
	if p == null or not p.has_animation(clip) or speed <= 0.0:
		return false
	var events: Array = SkillEvents.attack001_timeline(actor_id)
	if events.is_empty():
		return false
	cancel(false)
	player = p
	_actor_id = actor_id
	_source_root = source_root
	_emitted = false
	timeline.start(events)
	player.play(clip, -1.0, speed)
	player.seek(0.0, true)
	active = true
	return true

func _process(_delta: float) -> void:
	if not active or not is_instance_valid(player):
		return
	var position := player.current_animation_position
	timeline.advance(maxf(0.0, position - timeline.elapsed), 1.0)
	if not player.is_playing():
		active = false
		finished.emit()

func cancel(emit_signal: bool = true) -> void:
	var was := active
	active = false
	timeline.cancel()
	if is_instance_valid(player):
		player.stop()
	_dispose_particle()
	if was and emit_signal:
		cancelled.emit()

func was_emitted() -> bool:
	return _emitted

func _spawn_fx() -> void:
	var origin := Vector3.ZERO
	if is_instance_valid(player):
		var host := player.get_parent()
		if host is Node3D:
			origin = (host as Node3D).global_position
	# Prefer particle-index prefab; fall back to SkillFx marker
	var built: Node3D = VfxCatalog.build_class_attack(_actor_id, _source_root)
	if built != null:
		_dispose_particle()
		_particle_fx = built
		var parent: Node = get_tree().current_scene if get_tree() else self
		if parent == null:
			parent = self
		parent.add_child(built)
		if built is Node3D:
			(built as Node3D).global_position = origin + Vector3(0, 1.0, 0)
		return
	if _fx_host == null:
		_fx_host = SkillFx.new()
		_fx_host.name = "SkillFx"
		add_child(_fx_host)
	_fx_host.spawn_hit(origin, _fx_host.color_for_actor(_actor_id))

func _play_audio() -> void:
	# Optional: stream path may be absent in headless / used-asset pack
	if _audio == null:
		_audio = AudioStreamPlayer3D.new()
		_audio.name = "AttackAudio"
		add_child(_audio)
	# Placeholder: training still owns class mp3 wiring; director marks playback slot
	_audio.stop()

func _dispose_particle() -> void:
	if _particle_fx != null and is_instance_valid(_particle_fx):
		ParticlePreview.dispose(_particle_fx)
	_particle_fx = null

func _exit_tree() -> void:
	_dispose_particle()
