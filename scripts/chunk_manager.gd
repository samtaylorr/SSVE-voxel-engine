extends Node
class_name ChunkManager

@export var chunks_per_frame := 4
@export var render_distance = 8

var chunks := {} # Dictionary<Vector2i, Chunk>
var enqueued_chunks : Dictionary = {} # Used as a set, Dictionary<Vector2i, null>
var queue : Array[Vector2i] = []
var wanted_chunks := {} # Dictionary[Vector2i, bool]
var pending_chunks := 0

var player_prefab := preload("res://prefabs/player.tscn")
var loading_screen_prefab := preload("res://prefabs/loading_screen.tscn")
var player : Player
var player_chunk_coordinates : Vector2i
var loading_screen

static var initial_load := false
static var instance: ChunkManager

func _enter_tree():
	instance = self

func gen_chunk() -> void:
	
	if queue.is_empty():
		return
		
	var queued_chunk = queue.pop_back()
	enqueued_chunks.erase(queued_chunk)
	
	if chunks.has(queued_chunk):
		return

	if !wanted_chunks.has(queued_chunk):
		return

	var chunk := Chunk.new(queued_chunk)
	chunk.position = ChunkHelper.chunk_to_world_space(queued_chunk)
	add_child(chunk)
	chunks[queued_chunk] = chunk
	pending_chunks += 1
	WorkerThreadPool.add_task(func():
		chunk.generate_on_thread()
		call_deferred("_on_chunk_ready", queued_chunk)
	)

func _on_chunk_ready(key: Vector2i) -> void:
	if !chunks.has(key):
		# Chunk was unloaded while generating
		pending_chunks -= 1
		return

	chunks[key].is_ready = true
	pending_chunks -= 1

func load_chunks() -> void:
	var pc := ChunkHelper.world_to_chunk(player.global_position)
	wanted_chunks.clear()
	
	for cx in range(pc.x - render_distance, pc.x + render_distance + 1):
		for cz in range(pc.y - render_distance, pc.y + render_distance + 1):
			var key = Vector2i(cx, cz)
			wanted_chunks[key] = true
			if !chunks.has(key) and !enqueued_chunks.has(key):
				enqueued_chunks[key] = true
				queue.append(key)

	# unwanted chunks get unloaded
	for key in chunks.keys():
		if !wanted_chunks.has(key) and chunks[key].is_ready:
			chunks[key].queue_free()
			chunks.erase(key)

func _ready():
	player = player_prefab.instantiate() as Player
	add_child(player)
	player.global_position = Vector3(Chunk.CHUNK_SIZE * 0.5, 16+Chunk.MIN_HEIGHT, Chunk.CHUNK_SIZE * 0.5)
	player_chunk_coordinates = ChunkHelper.world_to_chunk(player.global_position)
	load_chunks()

func _physics_process(_delta):
	var current_chunk_coordinates = ChunkHelper.world_to_chunk(player.global_position)
	if current_chunk_coordinates != player_chunk_coordinates:
		player_chunk_coordinates = current_chunk_coordinates
		load_chunks()
	
	for i in range(chunks_per_frame):
		gen_chunk()
	
	if !initial_load and queue.is_empty() and pending_chunks == 0:
		if chunks.has(current_chunk_coordinates) and chunks[current_chunk_coordinates].is_ready:
			initial_load = true
			player.change_slot()
