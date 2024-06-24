extends CharacterBody3D

const SPEED = 3.0
const SPRINT_MULTIPLIER = 1.5
const NORMAL_FOV = 70.0
const SPRINT_FOV = 85.0
const ZOOM_SPEED = 10.0
const FLASH_FOLLOW_SPEED = 15.0
const SENSITIVITY = 0.5

const BOB_FREQ = 3.5
const BOB_AMP = 0.075
const THRESHOLD = -50
var t_bob = 0.0
var flashlight_on: bool = false
var gravity = 20

@onready var neck = $Neck
@onready var camera = $Neck/HeadXRotation/Camera
@onready var head_x_rotation = $Neck/HeadXRotation
@onready var subviewport_camera = %Subviewport_Camera
@onready var flashlight = $Flashlight
@onready var spot_light_3d = $Flashlight/Sketchfab_Scene/SpotLight3D
@onready var timer = $Sounds/Timer
@onready var breathing = $Sounds/Breathing
@onready var heavy_breathing = $Sounds/HeavyBreathing


func _ready():
	$Flashlight/Sketchfab_Scene/SpotLight3D.visible = false
	PlayerAutoload.player = self
	
func _input(event):
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		neck.rotation_degrees.y += -event.relative.x * SENSITIVITY
		camera.rotation_degrees.x += -event.relative.y * SENSITIVITY
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-45), deg_to_rad(60))
	elif event.is_action_pressed("quit"):
		get_tree().quit()
	elif event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("flashlight"):
		flashlight_on = !flashlight_on
		$Flashlight/Sketchfab_Scene/SpotLight3D.visible = flashlight_on
		$Sounds/Flashlight.play_sfx()

func _process(delta):
	subviewport_camera.set_global_transform(camera.get_global_transform())
	make_flashlight_follow(delta)
	
func make_flashlight_follow(delta):
	flashlight.rotation.y = lerp(flashlight.rotation.y, neck.rotation.y, delta * FLASH_FOLLOW_SPEED)
	flashlight.rotation.x = lerp(flashlight.rotation.x, camera.rotation.x, delta * FLASH_FOLLOW_SPEED)
	
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var is_moving = input_dir != Vector2.ZERO
	var is_sprinting = Input.is_action_pressed("sprint") and is_moving
	var current_speed = SPEED * (SPRINT_MULTIPLIER if is_sprinting else 1.0)

	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	move_and_slide()
	
	if direction != Vector3.ZERO and is_on_floor():
		var timer_interval = 0.35 if is_sprinting else 0.55
		if $Sounds/Timer.time_left <= 0:
			$Sounds/Walk.pitch_scale = randf_range(1.3, 1.0)
			$Sounds/Walk.play_sfx()
			$Sounds/Timer.start(timer_interval)
	camera.fov = lerp(camera.fov, SPRINT_FOV if is_sprinting else NORMAL_FOV, ZOOM_SPEED * delta)
	
	_check_fall_off_map()
	_handle_breathing(is_moving, is_sprinting)

func _check_fall_off_map():
	if global_transform.origin.y < THRESHOLD:
		_restart_scene()

func _restart_scene():
	get_tree().reload_current_scene()

func _headbob(time) -> Vector3:
	return Vector3(cos(time * BOB_FREQ / 2) * BOB_AMP, sin(time * BOB_FREQ) * BOB_AMP, 0.0)

func _handle_breathing(is_moving: bool, is_sprinting: bool) -> void:
	if is_sprinting:
		if not heavy_breathing.playing:
			heavy_breathing.play_sfx()
		if breathing.playing:
			breathing.stop()
	elif is_moving:
		if not breathing.playing:
			breathing.play_sfx()
		if heavy_breathing.playing:
			heavy_breathing.stop()
		else:
			if not breathing.playing:
				breathing.play_sfx()
			if heavy_breathing.playing:
				heavy_breathing.stop()
