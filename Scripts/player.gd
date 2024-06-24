extends CharacterBody3D

## CONSTANTS AND VARIABLES

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

##ONREADY VARIABLES
@onready var neck = $Neck
@onready var camera = $Neck/HeadXRotation/Camera
@onready var head_x_rotation = $Neck/HeadXRotation

## CAMERA MOVEMENT
func _input(event):
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		neck.rotation_degrees.y += -event.relative.x * SENSITIVITY
		camera.rotation_degrees.x += -event.relative.y * SENSITIVITY
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-45), deg_to_rad(60))
	elif event.is_action_pressed("quit"):
		get_tree().quit()

## HANDLE MOVEMENT
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

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

	move_and_slide()