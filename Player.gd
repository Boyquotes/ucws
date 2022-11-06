extends KinematicBody

enum STATE {
	IDLE,
	CROUCH,
	WALK,
	RUN,
	FALL,
	SLIDE,
	MANTLE,
}

export var mantling: bool = false
export var climbing: bool = false
export var animated_offset: Vector3
export var animating: bool = false
export var sliding: bool = false
export var slide_mantle: bool = false

onready var ammo_count : RichTextLabel = $Control/Ammo
onready var head: Spatial = $Head
onready var camera: Camera = $Head/Camera
onready var debug_camera: Camera = $Head/SpringArm/CameraDebug
onready var rc: RayCast = $Head/Camera/RayCast
onready var gunroot: Spatial = $Head/Camera/RootGun
onready var third_person: Spatial = $izuru
onready var third_person_anim: AnimationPlayer = $izuru/AnimationPlayer
onready var anim = $AnimationPlayer
onready var mantle_area: Area = $MantleColliders/Area
onready var mantle_area2: Area = $MantleColliders/Area2
onready var climb_area: Area = $ClimbColliders/Area
onready var climb_area2: Area = $ClimbColliders/Area2
onready var crouch_anim: AnimationPlayer = $CrouchAnimation
onready var fps_label: Label = $Control/FPS
onready var status_label: Label = $Control/STATUS
onready var wall_ground: RayCast = $GroundCast
onready var wall_area: Area = $WallArea


var wish_jump: bool = true
var pause: bool = false
var Hit: bool = false

var debug_horizontal_velocity: Vector3 = Vector3.ZERO
var accelerate_return: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO
var wishdir: Vector3 = Vector3.ZERO

var vertical_velocity: float = 0
var koyori_timer: float = 0
var sprint_timer: float = 0
var wall_timer: float = 0
var slide_timer: float = 0
var crouching: float = 0

var forward_input: float
var strafe_input: float
var sprint_input: float
var crouch_input: float

var slide_direction: Basis

var gun_string: String

var State: int

var snap: Vector3

var nop



func _ready() -> void:
	crouch_anim.play("crouch")
	crouch_anim.stop(false)
	# nop = Console.connect("toggled", self, "_on_console_toggled")
	gun_string = ""

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseButton and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Camera rotation
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_x(event.relative.y * DVars.mouse_sensitivity * -1)
		self.rotate_y(event.relative.x * DVars.mouse_sensitivity * -1)

		head.rotation_degrees.x = clamp(head.rotation_degrees.x, -DVars.camera_max_angle, DVars.camera_max_angle)

func _process(delta: float) -> void:
	fps_label.set_text("FPS " + String(1/delta))
	gun_string = ""
	if gunroot.get_child(0).has_method("get_name"):
		gun_string = gun_string + String(gunroot.get_child(0).get_name()) + "\n"
	if gunroot.get_child(0).has_method("get_ammo"):
		gun_string = gun_string + String(gunroot.get_child(0).get_ammo()) + "\n"
	if gunroot.get_child(0).has_method("get_round"):
		gun_string = gun_string + "[color=yellow]" + String(gunroot.get_child(0).get_round()) + "[/color]"
	ammo_count.bbcode_text = gun_string
	$Control/Label.visible = can_mantle() or can_climb()
	camera.fov = camera_fov_think(camera.fov, DVars.fov, DVars.fov_scale_multiplier, debug_horizontal_velocity.length(), DVars.fov_scale_threshold, DVars.fov_scale_weight, DVars.fov_scale_max)
	if gunroot.get_child(0).aiming:
		camera.fov = gunroot.get_child(0).get_ads_fov(camera.fov)

func _physics_process(delta: float) -> void:
	forward_input = Input.get_action_strength("back") - Input.get_action_strength("forward")
	strafe_input = Input.get_action_strength("moveright") - Input.get_action_strength("moveleft")
	crouch_input = Input.get_action_strength("crouch")

	if Input.is_action_just_released("jump"):
		slide_mantle = false

	if Input.is_action_pressed("sprint"):
		sprint_timer = DVars.sprint_grace

	if Input.is_action_pressed("crouch"):
		sprint_timer = 0

	if sprint_timer > 0:
		sprint_input = 1
	else:
		sprint_input = 0

	if Input.get_action_strength("fire") + Input.get_action_strength("aim") > 0:
		sprint_input = 0
		sprint_timer = 0
	
	if gunroot.get_child(0).aiming:
		sprint_input = 0
		sprint_timer = 0

	sprint_timer += -delta
	slide_timer += -delta

	if pause: 
		forward_input = 0
		strafe_input = 0
	
	if abs(forward_input) < 0.85:
		sprint_timer = 0

	var input: Vector3 = Vector3(strafe_input, 0, forward_input)

	if Input.is_action_pressed("crouch") && can_slide():
		anim.play("slide")
		slide_mantle = true
		sliding = true
		animated_offset.z = 1
		slide_direction = global_transform.basis
		animating = true
		crouching = 0
		State = STATE.SLIDE
	elif !animating:
		crouching = lerp(crouching, crouch_input, DVars.crouch_weight)
		crouch_anim.seek(crouching, true)

	if Input.is_action_pressed("jump") && !animating && can_mantle():
		anim.play("mantle")
	elif Input.is_action_pressed("jump") && !animating && can_climb():
		anim.play("climb")

	if mantling:
		State = STATE.MANTLE
		vertical_velocity = 0
		velocity = animated_offset.rotated(Vector3.UP, self.global_transform.basis.get_euler().y) * 2.5
		move_animated(velocity, delta)

	wishdir = input.rotated(Vector3.UP, self.global_transform.basis.get_euler().y).normalized()

	if input == Vector3.ZERO && !animating:
		State = STATE.IDLE
	elif !animating:
		State = STATE.WALK
		if get_speed_multiplier() > 1.0:
			State = STATE.RUN
		if get_speed_multiplier() < 1.0:
			State = STATE.CROUCH	

	queue_jump()

	queue_wallrun()

	if sliding:
		status_label.text = "sliding"
		State = STATE.SLIDE
		input = Vector3.ZERO
		# velocity = animated_offset.rotated(Vector3.UP, slide_direction.get_euler().y) * 2.5
		velocity = velocity * animated_offset.z
		move_frictionless(velocity, delta)
		print("jumpa")
		if wish_jump && !pause:
			anim.play("unslide")
			perform_jump(delta, false)
	elif (is_on_floor() || koyori_timing()) && !animating:
		status_label.text = "on floor || koyori && !animating"
		print("jumpb")
		if wish_jump && !pause:
			perform_jump(delta, false)			
		else:
			vertical_velocity = max(vertical_velocity, 0)
			snap = -get_floor_normal()
			move_ground(velocity, delta)
	elif !animating && !sliding:
		status_label.text = "!animating && !sliding"
		snap = Vector3.DOWN
		State = STATE.FALL
		vertical_velocity -= DVars.gravity * delta * on_air()
		move_air(velocity, delta)
	elif !is_on_floor() && !koyori_timing() && !mantling && sliding:
		status_label.text = "!on floor && !koyori && !mantling && !sliding"
		# print(is_on_floor())
		# print(koyori_timing())
#		breakpoint
		anim.play("unslide")
		snap = Vector3.DOWN
		State = STATE.FALL
		vertical_velocity -= DVars.gravity * delta * on_air()
		move_air(velocity, delta)
	elif animating && koyori_timing():
		status_label.text = "animating && koyori"
		if wish_jump && !pause:
			perform_jump(delta, true)
		else:
			snap = Vector3.DOWN
			State = STATE.FALL
			vertical_velocity = lerp(vertical_velocity, 0, DVars.wall_lerp)
			move_ground(velocity, delta)

	if self.is_on_ceiling():
		vertical_velocity = 0

	if is_on_floor():
		koyori_timer = DVars.koyori_time
	else:
		koyori_timer -= delta

	if wall_timer < DVars.wall_time:
		wall_timer += delta

	#gunroot.translation = view_bob_loc(gunroot.translation, input, DVars.bob_multiplier, DVars.bob_weight)
	debug_horizontal_velocity = Vector3(velocity.x, 0, velocity.z)

func accelerate(lwishdir: Vector3, input_velocity: Vector3, accel: float, max_speed: float, delta: float)-> Vector3:
	var current_speed: float = input_velocity.dot(lwishdir)
	var add_speed: float = clamp(max_speed - current_speed, 0, max_speed * accel * delta)

	accelerate_return = input_velocity + lwishdir * add_speed
	return accelerate_return

func friction(input_velocity: Vector3, delta: float)-> Vector3:
	var speed: float = input_velocity.length()
	var scaled_velocity: Vector3 = Vector3.ZERO

	# if input_velocity != Vector3.ZERO:
	# 	print(input_velocity)

	if speed != 0:
		var drop = speed * DVars.friction * delta
		scaled_velocity = input_velocity * max(speed - drop, 0) / speed
	if speed < 0.01:
		return scaled_velocity * 0
	return scaled_velocity

func move_ground(input_velocity: Vector3, delta: float)-> void:
	var nextVelocity: Vector3 = Vector3.ZERO
	nextVelocity.x = input_velocity.x
	nextVelocity.z = input_velocity.z
	nextVelocity = friction(nextVelocity, delta)
	# nextVelocity = accelerate(wishdir, nextVelocity, DVars.accel, DVars.max_speed, delta)
	nextVelocity = accelerate(wishdir, nextVelocity, DVars.accel, DVars.max_speed * get_speed_multiplier(), delta)

	nextVelocity.y = vertical_velocity
	velocity = move_and_slide_with_snap(nextVelocity, snap, Vector3.UP, true, 1, 1.13446)

func move_air(input_velocity: Vector3, delta: float)-> void:
	var nextVelocity: Vector3 = Vector3.ZERO
	nextVelocity.x = input_velocity.x
	nextVelocity.z = input_velocity.z
	nextVelocity = accelerate(wishdir, nextVelocity, DVars.accel, DVars.max_air_speed, delta)

	nextVelocity.y = vertical_velocity
	velocity = move_and_slide(nextVelocity, Vector3.UP)

func move_frictionless(input_velocity: Vector3, delta: float)-> void:
	var nextVelocity: Vector3 = Vector3.ZERO
	nextVelocity.x = input_velocity.x
	nextVelocity.z = input_velocity.z
	nextVelocity = accelerate(wishdir, nextVelocity, DVars.slide_accel, DVars.max_slide_speed, delta)

	nextVelocity.y = vertical_velocity
	velocity = move_and_slide_with_snap(nextVelocity, snap, Vector3.UP, true, 1, 1.13446)

func move_animated(input_velocity: Vector3, _delta: float)-> void:
	var nextVelocity: Vector3 = Vector3.ZERO
	nextVelocity.x = input_velocity.x
	nextVelocity.z = input_velocity.z
	nextVelocity.y = input_velocity.y
	# nextVelocity = accelerate(wishdir, nextVelocity, DVars.accel, DVars.max_air_speed, delta)

	velocity = move_and_slide(nextVelocity, Vector3.UP)

func queue_jump()-> void:

	if DVars.auto_jump:
		wish_jump = true if Input.is_action_pressed("jump") else false
		return

	if Input.is_action_just_pressed("jump") and !wish_jump:
		wish_jump = true
	if Input.is_action_just_released("jump"):
		wish_jump = false
		
#func _on_console_toggled(is_console_shown: bool) -> void:
#	pause = is_console_shown

func view_bob_loc(origin: Vector3, bobbing: Vector3, multiplier: float, weight: float) -> Vector3:
	var transformed: Vector3 = Vector3.ZERO
	transformed.x = lerp(origin.x, bobbing.x*multiplier, weight)
	transformed.y = origin.y
	transformed.z = lerp(origin.z, bobbing.z*multiplier, weight)
	return transformed

func camera_fov_think(current: float, base: float, multiplier: float, speed: float, minspeed: float, weight: float, maxfov : float) -> float:
	var speedmul = max(speed, minspeed) - minspeed
	var target = base * (1.0 + speedmul * multiplier)
	var scaled = lerp(current, target, weight)
	scaled = min(scaled, maxfov)
	return scaled

func on_air() -> float:
	if vertical_velocity >= DVars.terminal_velocity:
		return 1.0
	return 0.0

func can_mantle() -> bool:
	var empty: bool = false
	if animating || slide_mantle:
		return false
	if mantle_area.get_overlapping_bodies() == []:
		empty = true
	if mantle_area2.get_overlapping_bodies() != []:
		return empty
	return false

func can_climb() -> bool:
	var empty: bool = false
	if animating || slide_mantle:
		return false
	if climb_area.get_overlapping_bodies() == []:
		empty = true
	if climb_area2.get_overlapping_bodies() != []:
		return empty
	return false

func koyori_timing() -> bool:
	if koyori_timer >= 0:
		return true
	return false

func get_speed_multiplier() -> float:
	if crouch_input == sprint_input:
		return 1.0
	elif crouch_input > sprint_input:
		return DVars.crouch_multiplier
	return DVars.sprint_multiplier

func perform_jump(delta, from_wall) -> void:
	vertical_velocity = DVars.jump_impulse
	koyori_timer = 0
	wish_jump = false
	if from_wall:
		wall_timer = 0.0
	move_air(velocity, delta)
	return

func can_slide() -> bool:
	if debug_horizontal_velocity.length() >= DVars.slide_speed && is_on_floor() && !animating && slide_timer < 0:
		return true
	return false

func slide_time(time: float) -> void:
	slide_timer = time

func debugcamera(set: bool) -> void:
	if set:
		debug_camera.make_current()
	camera.make_current()

func queue_wallrun() -> void:
	if (wall_area.get_overlapping_bodies() != []) && !wall_ground.is_colliding() && wall_timer >= DVars.wall_time:
		koyori_timer = DVars.koyori_time
		animating = true
		return
	animating = false
	return
