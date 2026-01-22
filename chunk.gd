extends MeshInstance3D
class_name Chunk

enum BlockType {
	Air,
	Grass,
	Dirt,
	Water,
	Stone,
	Wood,
	Sand,
	NumTypes
}

var blocks: PackedByteArray = PackedByteArray()
var chunk_coordinates
const CHUNK_SIZE := 16
const XY := CHUNK_SIZE * CHUNK_SIZE
const BASE_HEIGHT := 8

@onready var body := StaticBody3D.new()
@onready var col  := CollisionShape3D.new()

var noise_gen := FastNoiseLite.new()

func emit_face(st: SurfaceTool, base: Vector3, normal: Vector3, verts: PackedVector3Array, uvs: PackedVector2Array) -> void:
	st.set_normal(normal)
	for i in range(verts.size()):
		st.set_uv(uvs[i])
		st.add_vertex(base + verts[i])

func create_cube(st: SurfaceTool, x:int, y:int, z:int, culling_mask:int) -> void:
	var base := Vector3(x,y,z)
	for f in ChunkHelper.FACE_DATA:
		if (culling_mask & f["bit"]) != 0:
			emit_face(st, base, f["n"], f["v"], f["uv"])

func create_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var blocks_local := blocks # local reference = faster

	for z in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			for x in range(CHUNK_SIZE):
				var i := x + (y * CHUNK_SIZE) + (z * XY)
				if blocks_local[i] == BlockType.Air:
					continue
				var mask := 0
				# Back (-Z)
				if z == 0 or blocks_local[i - XY] == BlockType.Air:
					mask |= ChunkHelper.FACE_BACK
				# Front (+Z)
				if z == CHUNK_SIZE - 1 or blocks_local[i + XY] == BlockType.Air:
					mask |= ChunkHelper.FACE_FRONT
				# Bottom (-Y)
				if y == 0 or blocks_local[i - CHUNK_SIZE] == BlockType.Air:
					mask |= ChunkHelper.FACE_BOTTOM
				# Top (+Y)
				if y == CHUNK_SIZE - 1 or blocks_local[i + CHUNK_SIZE] == BlockType.Air:
					mask |= ChunkHelper.FACE_TOP
				# Left (-X)
				if x == 0 or blocks_local[i - 1] == BlockType.Air:
					mask |= ChunkHelper.FACE_LEFT
				# Right (+X)
				if x == CHUNK_SIZE - 1 or blocks_local[i + 1] == BlockType.Air:
					mask |= ChunkHelper.FACE_RIGHT
				if mask != 0:
					create_cube(st, x, y, z, mask)
	
	mesh = st.commit()

func generate_chunk() -> void:
	blocks.resize(CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE)
	var world_origin = ChunkHelper.chunk_to_world_space(chunk_coordinates)
	for x in range (CHUNK_SIZE):
		for z in range(CHUNK_SIZE):
			var height := BASE_HEIGHT*noise_gen.get_noise_2d(world_origin.x+x,world_origin.z+z)*BASE_HEIGHT
			for y in range(CHUNK_SIZE):
				if y+world_origin.y <= height:
					blocks[x + (y * CHUNK_SIZE) + (z * XY)] = BlockType.Grass
				else:
					blocks[x + (y * CHUNK_SIZE) + (z * XY)] = BlockType.Air

func _setup_collision() -> void:
	if mesh == null:
		return
	
	if body.get_parent() == null:
		add_child(body)
	if col.get_parent() == null:
		body.add_child(col)
		
	col.shape = mesh.create_trimesh_shape()

func _ready() -> void:
	noise_gen.noise_type = FastNoiseLite.TYPE_PERLIN
	generate_chunk()
	create_mesh()
	_setup_collision()

func _init(cc: Vector2i): 
	chunk_coordinates = cc
