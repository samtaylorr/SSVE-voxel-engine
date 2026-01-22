extends Node

# - Calculate all chunks that needs rendering based on player position and add to a queue
# - Go through the queue and instantiate a Chunk based on it's iVec2 (chunk coordinate)
# - make sure each iVec2 is multiplied by the CHUNK_SIZE, e.g. if its on 0,2 then the position of the chunk is x = 0, y = 32

var chunks := {} # Dictionary<Vector2i, Chunk>
var enqueued_chunks : Dictionary = {} # Used as a set, Dictionary<Vector2i, null>
var queue : Array[Vector2i] = []
var wanted_chunks := {} # Dictionary[Vector2i, bool]
var player_prefab := preload("res://prefabs/player.tscn")
var loading_screen_prefab := preload("res://prefabs/loading_screen.tscn")
var player : Player
var player_chunk_coordinates : Vector2i
var loading_screen

var initial_load := false
var debug_line := false

@export var chunks_per_frame := 4
@export var render_distance = 8

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
	WorkerThreadPool.add_task(chunk.generate_on_thread)

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
		if !wanted_chunks.has(key):
			chunks[key].queue_free()
			chunks.erase(key)

func _ready():
	player = player_prefab.instantiate() as Player
	add_child(player)
	player.global_position = Vector3(Chunk.CHUNK_SIZE * 0.5, 18, Chunk.CHUNK_SIZE * 0.5)
	player_chunk_coordinates = ChunkHelper.world_to_chunk(player.global_position)
	load_chunks()

func _physics_process(_delta):
	var current_chunk_coordinates = ChunkHelper.world_to_chunk(player.global_position)
	if current_chunk_coordinates != player_chunk_coordinates:
		player_chunk_coordinates = current_chunk_coordinates
		load_chunks()
	
	for i in range(chunks_per_frame):
		gen_chunk()
	
	if !initial_load and queue.is_empty():
		if chunks.has(current_chunk_coordinates) and chunks[current_chunk_coordinates].is_ready:
			initial_load = true

func _process(_delta):
	if Engine.get_frames_drawn() % 1 == 30 and debug_line:
		print("Frame: ", Engine.get_frames_drawn(), ", Chunks loaded: ", \
			chunks.size(), ", Wanted chunks: ", wanted_chunks.size(), \
			", Chunks queued: ", queue.size(), ", Initial load: ", initial_load)
