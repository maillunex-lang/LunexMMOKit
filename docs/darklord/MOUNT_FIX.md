# MOUNT-FIX-001
Observed smartphone regression v0.1.1: hero stood on saddle even with the UI showing mount_stand.
Verified original GLB mount_stand clips contain thigh/calf rotations for all four classes. Actual regression was in _select_accessory: _preview_animation did not reliably select active mount_stand, with stand remaining active. Fix: after registering the mount in accessories, explicitly call AnimationPlayer.play("mount_stand") and advance(0). On all four classes, runtime test asserts current_animation mount_stand after attachment and after advance. Reposition initial mount camera orbit to 0.65 rad for visible side-seat posture. Visual Xvfb capture confirms mage seated with knees bent, but exact saddle fit and Android device remain to be validated.
Reproduction: godot --headless --path client --script ../tools/dgi/test_mount_inspect.gd
Screenshot: /home/gamedev/darklord-dgi/screens/mount-fix-2.png (private VPS only).
