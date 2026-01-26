extends MeshInstance3D
class_name Chunk

var blocks: PackedByteArray = PackedByteArray()
var chunk_coordinates
const CHUNK_SIZE := 16
const CHUNK_HEIGHT := 64
const XY := CHUNK_SIZE * CHUNK_HEIGHT
const MIN_HEIGHT := 8
const HEIGHT_VARIANCE := 24

var atlas_width := 96.0
var tile_size := 16.0

var is_ready := false
var is_disposed := false

@onready var body := StaticBody3D.new()
@onready var col  := CollisionShape3D.new()
@export var texture := preload("res://textures/textureatlas.png")

var noise_gen := FastNoiseLite.new()

func _notification(what):
	# This runs when queue_free() is called
	if what == NOTIFICATION_PREDELETE:
		is_disposed = true

func create_cube(st: SurfaceTool, x:int, y:int, z:int, culling_mask:int, block_type: int) -> void:
	var base := Vector3(x,y,z)
	var atlas_columns : float = 6.0
	var atlas_rows : float = 2.0
	var uv_scale := Vector2(1.0 / atlas_columns, 1.0 / atlas_rows)

	for f in ChunkHelper.FACE_DATA:
		# If bit is 1 (2^0), this returns 0. If bit is 16 (2^4), this returns 4.
		var face_index = round(log(f["bit"]) / log(2))
		var atlas_index = ChunkHelper.BLOCK_TEXTURES[block_type][face_index]

		var column := int(atlas_index % int(atlas_columns))
		var row := int(atlas_index / int(atlas_columns))

		var uv_offset := Vector2(
			column * uv_scale.x,
			row * uv_scale.y
		)

		if (culling_mask & f["bit"]) != 0:
			emit_face(st, base, f["n"], f["v"], f["uv"], uv_offset, uv_scale)

func emit_face(st: SurfaceTool, base: Vector3, normal: Vector3, verts: PackedVector3Array, uvs: PackedVector2Array, uv_offset: Vector2, uv_scale: Vector2) -> void:
	st.set_normal(normal)
	for i in range(verts.size()):
		# Multiply only the X of the UV by 0.25 to 'squash' it into one tile
		var scaled_uv = Vector2(uvs[i].x * uv_scale.x, uvs[i].y * uv_scale.y)
		var final_uv = scaled_uv + uv_offset
		
		st.set_uv(final_uv)
		st.add_vertex(base + verts[i])

func generate_chunk() -> void:
	blocks.resize(CHUNK_SIZE * CHUNK_HEIGHT * CHUNK_SIZE)
	var world_origin = ChunkHelper.chunk_to_world_space(chunk_coordinates)
	for x in range (CHUNK_SIZE):
		for z in range(CHUNK_SIZE):
			var raw_noise := noise_gen.get_noise_2d(world_origin.x+x,world_origin.z+z)
			var normalized := (raw_noise + 1.0)/2.0
			var height = MIN_HEIGHT + (normalized * HEIGHT_VARIANCE)
			for y in range(CHUNK_HEIGHT):
				var idx := x + (y * CHUNK_SIZE) + (z * XY)
				if y+world_origin.y <= height:
					if y+world_origin.y < MIN_HEIGHT:
						if y+world_origin.y == 0:
							blocks[idx] = ChunkHelper.BlockType.Bedrock
						else:
							blocks[idx] = ChunkHelper.BlockType.Stone
					else:
						blocks[idx] = ChunkHelper.BlockType.Grass
				else:
					blocks[idx] = ChunkHelper.BlockType.Air

func _finalize_chunk(_mesh: Mesh, shape: Shape3D) -> void:
	self.mesh = _mesh
	_setup_collision(shape)
	apply_material()
	WorldManager.save_chunk()
	is_ready = true

func generate_on_thread(override:bool=false):
	var shape
	
	ChunkHelper.chunk_lock.lock()
	var saved_blocks = ChunkHelper.generated_chunks.get(chunk_coordinates)
	ChunkHelper.chunk_lock.unlock()
	
	if saved_blocks != null and !override:
		self.blocks = saved_blocks
	else:
		if !is_disposed and blocks.is_empty():
			generate_chunk()
			ChunkHelper.chunk_lock.lock()
			ChunkHelper.generated_chunks[chunk_coordinates] = self.blocks
			ChunkHelper.chunk_lock.unlock()
	
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var blocks_local := blocks # local reference = faster
	for z in range(CHUNK_SIZE):
		for y in range(CHUNK_HEIGHT):
			for x in range(CHUNK_SIZE):
				var i := x + (y * CHUNK_SIZE) + (z * XY)
				if blocks_local[i] == ChunkHelper.BlockType.Air:
					continue
				var mask := 0
				# Back (-Z)
				if z == 0 or blocks_local[i - XY] == ChunkHelper.BlockType.Air:
					mask |= ChunkHelper.FACE_BACK
				# Front (+Z)
				if z == CHUNK_SIZE - 1 or blocks_local[i + XY] == ChunkHelper.BlockType.Air:
					mask |= ChunkHelper.FACE_FRONT
				# Bottom (-Y)
				if y == 0 or blocks_local[i - CHUNK_SIZE] == ChunkHelper.BlockType.Air:
					mask |= ChunkHelper.FACE_BOTTOM
				# Top (+Y)
				if y == CHUNK_HEIGHT - 1 or blocks_local[i + CHUNK_SIZE] == ChunkHelper.BlockType.Air:
					mask |= ChunkHelper.FACE_TOP
				# Left (-X)
				if x == 0 or blocks_local[i - 1] == ChunkHelper.BlockType.Air:
					mask |= ChunkHelper.FACE_LEFT
				# Right (+X)
				if x == CHUNK_SIZE - 1 or blocks_local[i + 1] == ChunkHelper.BlockType.Air:
					mask |= ChunkHelper.FACE_RIGHT
				if mask != 0:
					if !is_disposed:
						create_cube(st, x, y, z, mask, blocks_local[i])
	var final_mesh = st.commit()
	shape = final_mesh.create_trimesh_shape()
	
	if !is_disposed:
		call_deferred("_finalize_chunk", final_mesh, shape)

func apply_material():
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	self.material_override = mat

func _setup_collision(shape: Shape3D) -> void:
	if mesh == null:
		return
	
	if body.get_parent() == null:
		add_child(body)
	if col.get_parent() == null:
		body.add_child(col)
		
	col.shape = shape

func _ready() -> void:
	noise_gen.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_gen.frequency = 0.02
	noise_gen.fractal_octaves = 4
	noise_gen.seed = ChunkHelper.Seed

func _init(cc: Vector2i): 
	chunk_coordinates = cc
