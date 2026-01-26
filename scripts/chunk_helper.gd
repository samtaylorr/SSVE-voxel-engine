extends Node

func chunk_to_world_space(chunk: Vector2i) -> Vector3:
	return Vector3(chunk.x*Chunk.CHUNK_SIZE, 0, chunk.y*Chunk.CHUNK_SIZE)

func world_to_chunk(p: Vector3) -> Vector2i:
	var cx := int(floor(p.x / float(Chunk.CHUNK_SIZE)))
	var cz := int(floor(p.z / float(Chunk.CHUNK_SIZE)))
	return Vector2i(cx, cz)

func Vector3_to_3i(p: Vector3) -> Vector3i:
	var x := int(floor(p.x))
	var y := int(floor(p.y))
	var z := int(floor(p.z))
	return Vector3i(x, y, z)

func world_to_local(world_pos: Vector3) -> Vector3i:
	# Use floor to handle negative world coordinates correctly
	var x = int(floor(world_pos.x)) % Chunk.CHUNK_SIZE
	var y = int(floor(world_pos.y)) % Chunk.CHUNK_HEIGHT
	var z = int(floor(world_pos.z)) % Chunk.CHUNK_SIZE
	
	# Correct for GDScript's modulo behavior on negatives (e.g. if the coordinate is between 0 and -1.0, go up one floor)
	if x < 0: x += Chunk.CHUNK_SIZE
	if y < 0: y += Chunk.CHUNK_HEIGHT
	if z < 0: z += Chunk.CHUNK_SIZE
	
	return Vector3i(x, y, z)

func create_selection_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array([
		# Bottom square
		Vector3(0,0,0), Vector3(1,0,0), Vector3(1,0,0), Vector3(1,0,1),
		Vector3(1,0,1), Vector3(0,0,1), Vector3(0,0,1), Vector3(0,0,0),
		# Top square
		Vector3(0,1,0), Vector3(1,1,0), Vector3(1,1,0), Vector3(1,1,1),
		Vector3(1,1,1), Vector3(0,1,1), Vector3(0,1,1), Vector3(0,1,0),
		# Vertical pillars
		Vector3(0,0,0), Vector3(0,1,0), Vector3(1,0,0), Vector3(1,1,0),
		Vector3(1,0,1), Vector3(1,1,1), Vector3(0,0,1), Vector3(0,1,1)
	])
	
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return arr_mesh

enum Faces { BACK,FRONT,LEFT,RIGHT,TOP,BOTTOM }
const FACE_BACK   := 1 << Faces.BACK
const FACE_FRONT  := 1 << Faces.FRONT
const FACE_LEFT   := 1 << Faces.LEFT
const FACE_RIGHT  := 1 << Faces.RIGHT
const FACE_TOP    := 1 << Faces.TOP
const FACE_BOTTOM := 1 << Faces.BOTTOM

var Seed := 0
var chunk_lock := Mutex.new()
var generated_chunks = {}
var dirty_chunks = []

enum BlockType {
	Air,
	Dirt,
	Grass,
	Stone,
	Planks,
	Bedrock,
	Cobblestone
}

enum AtlasTextures {
	Dirt,
	Grass_Side,
	Grass_Top,
	Stone,
	Planks,
	Bedrock,
	Cobblestone
}

# Key: BlockType, Value: Array of atlas positions
const BLOCK_TEXTURES = {
	BlockType.Air: [],
	BlockType.Dirt: [
		AtlasTextures.Dirt, # FACE_BACK
		AtlasTextures.Dirt, # FACE_FRONT
		AtlasTextures.Dirt, # FACE_LEFT
		AtlasTextures.Dirt, # FACE_RIGHT
		AtlasTextures.Dirt, # FACE_TOP
		AtlasTextures.Dirt  # FACE_BOTTOM
	],
	BlockType.Grass: [
		AtlasTextures.Grass_Side,
		AtlasTextures.Grass_Side,
		AtlasTextures.Grass_Side,
		AtlasTextures.Grass_Side,
		AtlasTextures.Grass_Top,
		AtlasTextures.Dirt
	],
	BlockType.Stone: [
		AtlasTextures.Stone,
		AtlasTextures.Stone,
		AtlasTextures.Stone,
		AtlasTextures.Stone,
		AtlasTextures.Stone,
		AtlasTextures.Stone
	],
	BlockType.Planks: [
		AtlasTextures.Planks,
		AtlasTextures.Planks,
		AtlasTextures.Planks,
		AtlasTextures.Planks,
		AtlasTextures.Planks,
		AtlasTextures.Planks
	],
	BlockType.Bedrock: [
		AtlasTextures.Bedrock,
		AtlasTextures.Bedrock,
		AtlasTextures.Bedrock,
		AtlasTextures.Bedrock,
		AtlasTextures.Bedrock,
		AtlasTextures.Bedrock
	],
	BlockType.Cobblestone: [
		AtlasTextures.Cobblestone,
		AtlasTextures.Cobblestone,
		AtlasTextures.Cobblestone,
		AtlasTextures.Cobblestone,
		AtlasTextures.Cobblestone,
		AtlasTextures.Cobblestone
	]
}

var FACE_DATA := [
	{ 
		"bit": FACE_BACK, # Looking at Z=0 from behind
		"n": Vector3(0, 0, -1), 
		"v": PackedVector3Array([
			Vector3(0,0,0), Vector3(1,1,0), Vector3(0,1,0),
			Vector3(0,0,0), Vector3(1,0,0), Vector3(1,1,0)
		]),
		"uv": PackedVector2Array([
			Vector2(0,1), Vector2(1,0), Vector2(0,0),
			Vector2(0,1), Vector2(1,1), Vector2(1,0)
		])
	},
	{ 
		"bit": FACE_FRONT, # Looking at Z=1 from front
		"n": Vector3(0, 0, 1),
		"v": PackedVector3Array([
			Vector3(0,1,1), Vector3(1,1,1), Vector3(0,0,1),
			Vector3(1,1,1), Vector3(1,0,1), Vector3(0,0,1)
		]),
		"uv": PackedVector2Array([
			Vector2(0,0), Vector2(1,0), Vector2(0,1),
			Vector2(1,0), Vector2(1,1), Vector2(0,1)
		])
	},
	{ 
		"bit": FACE_LEFT, # Looking at X=0 from side
		"n": Vector3(-1,0, 0),  
		"v": PackedVector3Array([
			Vector3(0,1,1), Vector3(0,0,1), Vector3(0,1,0),
			Vector3(0,1,0), Vector3(0,0,1), Vector3(0,0,0)
		]),
		"uv": PackedVector2Array([
			Vector2(1,0), Vector2(1,1), Vector2(0,0),
			Vector2(0,0), Vector2(1,1), Vector2(0,1)
		]),
	},
	{ 
		"bit": FACE_RIGHT, # Looking at X=1 from side
		"n": Vector3( 1,0, 0),
		"v": PackedVector3Array([
			Vector3(1,1,0), Vector3(1,0,0), Vector3(1,1,1),
			Vector3(1,1,1), Vector3(1,0,0), Vector3(1,0,1)
		]),
		"uv": PackedVector2Array([
			Vector2(0,0), Vector2(0,1), Vector2(1,0),
			Vector2(1,0), Vector2(0,1), Vector2(1,1)
		])
	},
	{ 
		"bit": FACE_TOP, # +Y (The Grass Top)
		"n": Vector3(0, 1, 0),
		"v": PackedVector3Array([
			Vector3(0,1,0), Vector3(1,1,0), Vector3(1,1,1),
			Vector3(0,1,0), Vector3(1,1,1), Vector3(0,1,1)
		]),
		"uv": PackedVector2Array([
			Vector2(0,0), Vector2(1,0), Vector2(1,1),
			Vector2(0,0), Vector2(1,1), Vector2(0,1)
		])
	},
	{
		"bit": FACE_BOTTOM, # -Y (The Dirt/Bottom)
		"n": Vector3(0,-1, 0),  
		"v": PackedVector3Array([
			Vector3(0,0,0), Vector3(1,0,1), Vector3(1,0,0),
			Vector3(0,0,0), Vector3(0,0,1), Vector3(1,0,1)
		]),
		"uv": PackedVector2Array([
			Vector2(0,0), Vector2(1,1), Vector2(1,0),
			Vector2(0,0), Vector2(0,1), Vector2(1,1)
		]),
	},
]
