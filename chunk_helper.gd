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

static var FACE_DATA := [
	{ 
		"bit": FACE_BACK,
		"n": Vector3(0, 0, -1), 
		"v": PackedVector3Array([
			Vector3(0,0,0),
			Vector3(1,1,0),
			Vector3(0,1,0),
			Vector3(0,0,0),
			Vector3(1,0,0),
			Vector3(1,1,0)
			]),
		"uv": PackedVector2Array([
			Vector2(0,0),
			Vector2(1,1),
			Vector2(0,1),
			Vector2(0,0),
			Vector2(1,0),
			Vector2(1,1)
		])
	},
	{ 
		"bit": FACE_FRONT, 
		"n": Vector3(0, 0,  1),
		"v": PackedVector3Array([
			Vector3(0,1,1), 
			Vector3(1,1,1), 
			Vector3(0,0,1), 
			Vector3(1,1,1), 
			Vector3(1,0,1), 
			Vector3(0,0,1)
		]),
		"uv": PackedVector2Array([
			Vector2(0,1), 
			Vector2(1,1), 
			Vector2(0,0), 
			Vector2(1,1), 
			Vector2(1,0), 
			Vector2(0,0)
		])
	},
	{ 
		"bit": FACE_LEFT,   
		"n": Vector3(-1,0, 0),  
		"v": PackedVector3Array([
			Vector3(0,1,1), 
			Vector3(0,0,1), 
			Vector3(0,1,0), 
			Vector3(0,1,0), 
			Vector3(0,0,1), 
			Vector3(0,0,0)
		]),
		"uv": PackedVector2Array([
			Vector2(1,1),
			Vector2(0,1),
			Vector2(1,0),
			Vector2(1,0),
			Vector2(0,1),
			Vector2(0,0)
		]),
	},
	{ 
		"bit": FACE_RIGHT,
		"n": Vector3( 1,0, 0),
		"v": PackedVector3Array([
			Vector3(1,1,0), 
			Vector3(1,0,0), 
			Vector3(1,1,1), 
			Vector3(1,1,1), 
			Vector3(1,0,0), 
			Vector3(1,0,1)
		]),
		"uv": PackedVector2Array([
			Vector2(1,0), 
			Vector2(0,0), 
			Vector2(1,1), 
			Vector2(1,1), 
			Vector2(0,0), 
			Vector2(0,1)
		])
	},
	{ 
		"bit": FACE_TOP,
		"n": Vector3(0, 1, 0),
		"v": PackedVector3Array([
			Vector3(0,1,0),
			Vector3(1,1,0),
			Vector3(1,1,1),
			Vector3(0,1,0),
			Vector3(1,1,1),
			Vector3(0,1,1)
		]),
		"uv": PackedVector2Array([
			Vector2(0,0),
			Vector2(1,0),
			Vector2(1,1),
			Vector2(0,0),
			Vector2(1,1),
			Vector2(0,1)
		])
	},
	{
		"bit": FACE_BOTTOM, 
		"n": Vector3(0,-1, 0),  
		"v": PackedVector3Array([
			Vector3(0,0,0), 
			Vector3(1,0,1), 
			Vector3(1,0,0), 
			Vector3(0,0,0), 
			Vector3(0,0,1), 
			Vector3(1,0,1)
		]),
		"uv": PackedVector2Array([
			Vector2(0,0), 
			Vector2(1,1), 
			Vector2(1,0), 
			Vector2(0,0), 
			Vector2(0,1), 
			Vector2(1,1)
		]),
	},
]
