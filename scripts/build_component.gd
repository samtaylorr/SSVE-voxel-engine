extends Node3D
class_name BuildComponent

var highlighted_position : Vector3i
var highlighted_face : ChunkHelper.Faces

var can_build := true

var selected_block : ChunkHelper.BlockType = ChunkHelper.BlockType.Planks

func update_selected_block(block:ChunkHelper.BlockType):
	selected_block = block

func snap_update_position(pos:Vector3, n:Vector3):
	highlighted_position = Vector3i(floor(pos.x), floor(pos.y), floor(pos.z))
	can_build = true
	update_face_direction(n)

func update_face_direction(n:Vector3):
	for f in ChunkHelper.FACE_DATA:
		if f["n"] == n:
			highlighted_face = round(log(f["bit"]) / log(2))

func destroy():
	if can_build and get_block_at_position(highlighted_position)!=ChunkHelper.BlockType.Bedrock:
		set_block_at_position(highlighted_position, ChunkHelper.BlockType.Air)
		pass

func build(player_pos:Vector3i):
	if can_build:
		var new_pos := highlighted_position
		if highlighted_face == ChunkHelper.Faces.TOP:
			new_pos += Vector3i(0, 1, 0)
		elif highlighted_face == ChunkHelper.Faces.BOTTOM:
			new_pos += Vector3i(0, -1, 0)
		elif highlighted_face == ChunkHelper.Faces.LEFT:
			new_pos += Vector3i(-1, 0, 0)
		elif highlighted_face == ChunkHelper.Faces.RIGHT:
			new_pos += Vector3i(1, 0, 0)
		elif highlighted_face == ChunkHelper.Faces.FRONT:
			new_pos += Vector3i(0, 0, 1)
		elif highlighted_face == ChunkHelper.Faces.BACK:
			new_pos += Vector3i(0, 0, -1)
		
		var new_pos_at_player = ChunkHelper.world_to_local(new_pos) == ChunkHelper.world_to_local(player_pos)
		
		if get_block_at_position(new_pos)==ChunkHelper.BlockType.Air and !new_pos_at_player:
			set_block_at_position(new_pos, selected_block)

func get_block_at_position(pos:Vector3i) -> ChunkHelper.BlockType:
	var chunk_coord = ChunkHelper.world_to_chunk(pos)
	var chunk = ChunkManager.chunks[chunk_coord]
	var local = ChunkHelper.world_to_local(pos)
	var idx = local.x + (local.y * Chunk.CHUNK_SIZE) + (local.z * Chunk.XY)
	return chunk.blocks[idx]

func set_block_at_position(pos:Vector3i, block:ChunkHelper.BlockType):
		var chunk_coord = ChunkHelper.world_to_chunk(pos)
		var chunk = ChunkManager.chunks[chunk_coord]
		var local = ChunkHelper.world_to_local(pos)
		var idx = local.x + (local.y * Chunk.CHUNK_SIZE) + (local.z * Chunk.XY)
		chunk.blocks[idx] = block
		WorkerThreadPool.add_task(chunk.generate_on_thread, true)

func disable_position():
	can_build = false
