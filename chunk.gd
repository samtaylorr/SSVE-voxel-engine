extends MeshInstance3D
class_name Chunk

var blocks: PackedByteArray = PackedByteArray()
var chunk_coordinates
const CHUNK_SIZE := 16
const XY := CHUNK_SIZE * CHUNK_SIZE
const BASE_HEIGHT := 8

var atlas_width := 64.0
var tile_size := 16.0

@onready var body := StaticBody3D.new()
@onready var col  := CollisionShape3D.new()
@export var texture := preload("res://textures/textureatlas.png")

var noise_gen := FastNoiseLite.new()

func create_cube(st: SurfaceTool, x:int, y:int, z:int, culling_mask:int, block_type: int) -> void:
	var base := Vector3(x,y,z)
	var atlas_columns : float = 4.0
	var atlas_rows : float = 1.0
	var uv_scale := Vector2(1.0 / atlas_columns, 1.0 / atlas_rows)

	for f in ChunkHelper.FACE_DATA:
		# If bit is 1 (2^0), this returns 0. If bit is 16 (2^4), this returns 4.
		var face_index = round(log(f["bit"]) / log(2))
		var atlas_index = ChunkHelper.BLOCK_TEXTURES[block_type][face_index]
		var uv_offset = Vector2(atlas_index * uv_scale.x, 0)
		if (culling_mask & f["bit"]) != 0:
			emit_face(st, base, f["n"], f["v"], f["uv"], uv_offset, uv_scale)

func emit_face(st: SurfaceTool, base: Vector3, normal: Vector3, verts: PackedVector3Array, uvs: PackedVector2Array, uv_offset: Vector2, uv_scale: Vector2) -> void:
	st.set_normal(normal)
	for i in range(verts.size()):
		# Multiply only the X of the UV by 0.25 to 'squash' it into one tile
		var scaled_uv = Vector2(uvs[i].x * uv_scale.x, uvs[i].y)
		var final_uv = scaled_uv + uv_offset
		
		st.set_uv(final_uv)
		st.add_vertex(base + verts[i])

func generate_chunk() -> void:
	blocks.resize(CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE)
	var world_origin = ChunkHelper.chunk_to_world_space(chunk_coordinates)
	for x in range (CHUNK_SIZE):
		for z in range(CHUNK_SIZE):
			var height := BASE_HEIGHT*noise_gen.get_noise_2d(world_origin.x+x,world_origin.z+z)*BASE_HEIGHT
			for y in range(CHUNK_SIZE):
				if y+world_origin.y <= height:
					blocks[x + (y * CHUNK_SIZE) + (z * XY)] = ChunkHelper.BlockType.Grass
				else:
					blocks[x + (y * CHUNK_SIZE) + (z * XY)] = ChunkHelper.BlockType.Air

func _finalize_chunk(mesh: Mesh, shape: Shape3D) -> void:
	self.mesh = mesh
	_setup_collision(shape)
	apply_material()

func generate_on_thread():
	generate_chunk()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var blocks_local := blocks # local reference = faster
	for z in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
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
				if y == CHUNK_SIZE - 1 or blocks_local[i + CHUNK_SIZE] == ChunkHelper.BlockType.Air:
					mask |= ChunkHelper.FACE_TOP
				# Left (-X)
				if x == 0 or blocks_local[i - 1] == ChunkHelper.BlockType.Air:
					mask |= ChunkHelper.FACE_LEFT
				# Right (+X)
				if x == CHUNK_SIZE - 1 or blocks_local[i + 1] == ChunkHelper.BlockType.Air:
					mask |= ChunkHelper.FACE_RIGHT
				if mask != 0:
					create_cube(st, x, y, z, mask, blocks_local[i])
	var final_mesh = st.commit()
	var shape := final_mesh.create_trimesh_shape()
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

func _init(cc: Vector2i): 
	chunk_coordinates = cc
