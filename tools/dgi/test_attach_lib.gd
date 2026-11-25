extends SceneTree
const Library = preload("res://actors/attachment_library.gd")
const Equipment = preload("res://actors/equipment.gd")
func _initialize():
	call_deferred("run")
func run():
	var single = Library.load_offset("weapon", "100011000")
	var right = Library.load_offset("weapon", "400011000", "", "body2")
	var left = Library.load_offset("weapon", "400011000", "", "body1")
	print("SINGLE ", single != null, " socket=", single.socket if single else null)
	print("RIGHT ", right != null, " rot=", right.rotation_degrees if right else null)
	print("LEFT ", left != null, " scale=", left.scale if left else null)
	var spec = Equipment.darklord_base_weapon_spec("400011000")
	print("SPEC_MODE ", spec.get("mode"))
	var wing = Library.load_offset("wing", "wing_L_01")
	var seat = Library.load_offset("mount_seat", "mount_001")
	print("WING ", wing != null, " SEAT ", seat != null)
	quit(0 if single and right and left and spec.get("mode")=="dual" and wing and seat else 1)
