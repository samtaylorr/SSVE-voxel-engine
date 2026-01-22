extends CharacterBody3D
class_name Player

@export_group("Movement")
# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75
@export var jump_impulse = 20

@export_group("Camera")
@export var mouse_sensitivity = 0.002

var target_velocity = Vector3.ZERO

func _physics_process(delta):
	if ChunkManager.initial_load:
		var input_dir := Vector3(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			0.0,
			Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
		)

		if input_dir.length() > 0.0:
			input_dir = input_dir.normalized()

		var world_dir := global_transform.basis * input_dir

		velocity.x = world_dir.x * speed
		velocity.z = world_dir.z * speed

		if not is_on_floor():
			velocity.y -= fall_acceleration * delta
		else:
			velocity.y = 0.0
		
		if is_on_floor() and Input.is_action_just_pressed("jump"):
			print("jump in")
			velocity.y = jump_impulse

		move_and_slide()

func _input(event):
	if ChunkManager.initial_load:
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * mouse_sensitivity)
			$Camera3D.rotate_x(-event.relative.y * mouse_sensitivity)
			$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(70), deg_to_rad(70))

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
