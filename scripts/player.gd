extends CharacterBody3D
class_name Player

@onready var speed = 7
@onready var fall_acceleration = 75
@onready var jump_impulse = 15

var target_velocity = Vector3.ZERO
const RAY_LENGTH = 5

var last_position : Vector3i
var paused := false

var slot = 0

# Tree nodes
var highlight_cube : HighlightCube
var build_component : BuildComponent
var cam : Camera3D
var chunk_manager : ChunkManager
var sub_menu : MenuHandler

# UI Tree nodes
var ui_selector : SlotHandler

const OUTLINE_SHADER = preload("res://shaders/wireframe.gdshader")

func _raycast_block_detection():
	var space_state = get_world_3d().direct_space_state
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
		build_component.snap_update_position(hit_pos, result.normal)
	else:
		highlight_cube.remove_highlight()
		build_component.disable_position()
	
func _physics_process(delta):
	if sub_menu.hidden_menu:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.is_action_just_pressed("menu"):
		if sub_menu.hidden_menu:
			sub_menu.show_menu()
		else:
			sub_menu.hide_menu()
	
	if sub_menu.hidden_menu:
		paused = false
	else:
		paused = true
	
	if not chunk_manager or not chunk_manager.initial_load or paused:
		return
	
	var input_dir := Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0.0,
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)

	if input_dir.length() > 0.0:
		input_dir = input_dir.normalized()

	var world_dir := global_transform.basis * input_dir
	
	if speed == null:
		print("CRITICAL: world_dir is Nil!")
		return

	velocity.x = world_dir.x * speed
	velocity.z = world_dir.z * speed

	if not is_on_floor():
		velocity.y -= fall_acceleration * delta
	else:
		velocity.y = 0.0
	
	if is_on_floor() and Input.is_action_pressed("jump"):
		velocity.y = jump_impulse

	if Input.is_action_just_pressed("build"):
		build_component.build(ChunkHelper.Vector3_to_3i(position))
	
	if Input.is_action_just_pressed("destroy"):
		build_component.destroy()
		
	if Input.is_action_just_pressed("toggle_selected_block_up"):
		slot = clamp(slot+1, 0, ui_selector.slots.size()-1)
		change_slot()
		
	if Input.is_action_just_pressed("toggle_selected_block_down"):
		slot = clamp(slot-1, 0, ui_selector.slots.size()-1)
		change_slot()
	
	for i in range(5):
		if Input.is_action_just_pressed("slot"+str(i)):
			slot = i 
			change_slot()
	
	var _pos := ChunkHelper.Vector3_to_3i(position)
	_pos = Vector3(_pos.x, 0, _pos.z)
	if _pos.distance_to(last_position) >= 1.5:
		AudioManager.play_sfx("step")
		last_position = _pos

	move_and_slide()
	_raycast_block_detection()

func _input(event):
	if chunk_manager and chunk_manager.initial_load:
		if event is InputEventMouseMotion and !paused:
			rotate_y(-event.relative.x * SettingsHandler.mouse_sensitivity)
			cam.rotate_x(-event.relative.y * SettingsHandler.mouse_sensitivity)
			cam.rotation.x = clampf(cam.rotation.x, -deg_to_rad(90), deg_to_rad(90))

func _create_selection_box():
	pass

func change_slot():
	build_component.update_selected_block(ui_selector.blocks_in_slots[slot])
	ui_selector.change_highlighted_slot(slot)

func get_references() -> void:
	chunk_manager = get_parent() as ChunkManager
	highlight_cube = HighlightCube.new()
	build_component = $BuildComponent
	cam = $Camera3D
	sub_menu = get_node("/root/Main/Sub Menu")
	ui_selector = get_node("UI/Selector")
	last_position = ChunkHelper.Vector3_to_3i(position)

func _ready() -> void:
	get_references()
	sub_menu.hide_menu()
	get_parent().add_child(highlight_cube)
