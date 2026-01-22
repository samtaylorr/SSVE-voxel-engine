extends Node
class_name ChunkHelper

static func chunk_to_world_space(chunk: Vector2i) -> Vector3:
	return Vector3(chunk.x*Chunk.CHUNK_SIZE, 0, chunk.y*Chunk.CHUNK_SIZE)

static func world_to_chunk(p: Vector3) -> Vector2i:
	var cx := int(floor(p.x / float(Chunk.CHUNK_SIZE)))
	var cz := int(floor(p.z / float(Chunk.CHUNK_SIZE)))
	return Vector2i(cx, cz)
