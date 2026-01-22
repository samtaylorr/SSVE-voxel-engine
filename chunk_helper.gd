extends Node
class_name ChunkHelper

static func chunk_to_world_space(chunk: Vector2i) -> Vector3:
	return Vector3(chunk.x*Chunk.CHUNK_SIZE, 0, chunk.y*Chunk.CHUNK_SIZE)

static func world_to_chunk(p: Vector3) -> Vector2i:
	var cx := int(floor(p.x / float(Chunk.CHUNK_SIZE)))
	var cz := int(floor(p.z / float(Chunk.CHUNK_SIZE)))
	return Vector2i(cx, cz)

enum Faces { BACK,FRONT,LEFT,RIGHT,TOP,BOTTOM }
const FACE_BACK   := 1 << Faces.BACK
const FACE_FRONT  := 1 << Faces.FRONT
const FACE_LEFT   := 1 << Faces.LEFT
const FACE_RIGHT  := 1 << Faces.RIGHT
const FACE_TOP    := 1 << Faces.TOP
const FACE_BOTTOM := 1 << Faces.BOTTOM

enum BlockType {
	Air,
	Dirt,
	Grass,
	Stone
}

enum AtlasTextures {
	Dirt,
	Grass_Side,
	Grass_Top,
	Stone
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
	]
}

static var FACE_DATA := [
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
