extends CharacterBody3D
class_name Player

@export_group("Movement")
# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75
@export var jump_impulse = 20

var highlight_cube : HighlightCube

@export_group("Camera")
@export var mouse_sensitivity = 0.002

var target_velocity = Vector3.ZERO
const RAY_LENGTH = 10

var last_position : Vector3i
var last_blocktype : ChunkHelper.BlockType
var last_idx : int
var last_chunk : Chunk

const OUTLINE_SHADER = preload("res://shaders/wireframe.gdshader")

func _raycast_block_detection():
	var space_state = get_world_3d().direct_space_state
	var cam = $Camera3D
	var mousepos = get_viewport().get_mouse_position()

	var origin = cam.project_ray_origin(mousepos)
	var end = origin + cam.project_ray_normal(mousepos) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	query.exclude = [self]

	var result = space_state.intersect_ray(query)
	if result:
		# Shift position by half a voxel inward to ensure we are 'inside' the block hit
		var hit_pos = result.position - (result.normal * 0.1)
		highlight_cube.snap_to_highlight(hit_pos)
	else:
		highlight_cube.remove_highlight()
	
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
		
		if is_on_floor() and Input.is_action_pressed("jump"):
			velocity.y = jump_impulse

		move_and_slide()
		_raycast_block_detection()

func _input(event):
	if ChunkManager.initial_load:
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * mouse_sensitivity)
			$Camera3D.rotate_x(-event.relative.y * mouse_sensitivity)
			$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(70), deg_to_rad(70))

func _create_selection_box():
	pass

func _ready() -> void:
	highlight_cube = HighlightCube.new()
	get_parent().add_child(highlight_cube)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
