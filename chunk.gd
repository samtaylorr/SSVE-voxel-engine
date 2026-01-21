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

enum Faces { BACK,FRONT,LEFT,RIGHT,TOP,BOTTOM }

const FACE_BACK   := 1 << Faces.BACK
const FACE_FRONT  := 1 << Faces.FRONT
const FACE_LEFT   := 1 << Faces.LEFT
const FACE_RIGHT  := 1 << Faces.RIGHT
const FACE_TOP    := 1 << Faces.TOP
const FACE_BOTTOM := 1 << Faces.BOTTOM

var blocks: PackedByteArray = PackedByteArray()
const CHUNK_SIZE := 16

func idx(x:int, y:int, z:int) -> int:
	return x + CHUNK_SIZE * (y + CHUNK_SIZE * z)
	# (equivalently: x + y*CHUNK_SIZE + z*CHUNK_SIZE*CHUNK_SIZE)

func get_block(x:int, y:int, z:int) -> int:
	return blocks[idx(x,y,z)]

func set_block(x:int, y:int, z:int, t:int) -> void:
	blocks[idx(x,y,z)] = t

func is_solid(t:int) -> bool:
	return t != BlockType.Air

func calculate_culling_mask(x:int, y:int, z:int) -> int:
	# Each side is represented by a bit inside of a byte, with the last two being empty.
	# 0 	0 	  0 	 0 	 0 	   0    0	  0
	# ^ 	^ 	  ^ 	 ^ 	 ^ 	   ^    ^	  ^
	# Empty Empty Bottom Top Right Left Front Back
	
	# Don't waste calls on calculating empty blocks
	if !is_solid(get_block(x,y,z)):
		return 0
	
	var mask := 0
	if z == 0 or !is_solid(get_block(x,y,z-1)):
		mask |= FACE_BACK
	if z == CHUNK_SIZE - 1 or !is_solid(get_block(x,y,z+1)):
		mask |= FACE_FRONT
	if y == 0 or !is_solid(get_block(x,y-1,z)):
		mask |= FACE_BOTTOM
	if y == CHUNK_SIZE - 1 or !is_solid(get_block(x,y+1,z)):
		mask |= FACE_TOP
	if x == 0 or !is_solid(get_block(x-1,y,z)):
		mask |= FACE_LEFT
	if x == CHUNK_SIZE - 1 or !is_solid(get_block(x+1,y,z)):
		mask |= FACE_RIGHT
	return mask

func create_cube(st: SurfaceTool, x:int, y:int, z:int, culling_mask:int):
	if (culling_mask & FACE_BACK) != 0:
		st.set_normal(Vector3(0, 0, -1))
		st.add_vertex(Vector3(x, y, z)) # bottom-left
		st.add_vertex(Vector3(x+1, y+1, z)) # top-right
		st.add_vertex(Vector3(x, y+1, z)) # top-left
		st.add_vertex(Vector3(x, y, z)) # bottom-left
		st.add_vertex(Vector3(x+1, y, z)) # bottom-right
		st.add_vertex(Vector3(x+1, y+1, z)) # top-right

	if (culling_mask & FACE_FRONT) != 0:
		st.set_normal(Vector3(0, 0, 1))
		st.add_vertex(Vector3(x,  y+1, z+1)) # top-left
		st.add_vertex(Vector3(x+1,  y+1, z+1)) # top-right
		st.add_vertex(Vector3(x, y, z+1)) # bottom-left
		st.add_vertex(Vector3(x+1,  y+1, z+1)) # top-right
		st.add_vertex(Vector3(x+1, y, z+1)) # bottom-right
		st.add_vertex(Vector3(x, y, z+1)) # bottom-left

	if (culling_mask & FACE_LEFT) != 0:
		st.set_normal(Vector3(-1, 0, 0))
		st.add_vertex(Vector3(x,  y+1,  z+1)) # front-top
		st.add_vertex(Vector3(x, y,  z+1)) # front-bottom
		st.add_vertex(Vector3(x,  y+1, z)) # back-top
		st.add_vertex(Vector3(x,  y+1, z)) # back-top
		st.add_vertex(Vector3(x, y,  z+1)) # front-bottom
		st.add_vertex(Vector3(x, y, z)) # back-bottom

	if (culling_mask & FACE_RIGHT) != 0:
		st.set_normal(Vector3(1, 0, 0))
		st.add_vertex(Vector3(x+1,  y+1, z)) # back-top
		st.add_vertex(Vector3(x+1, y, z)) # back-bottom
		st.add_vertex(Vector3(x+1,  y+1,  z+1)) # front-top
		st.add_vertex(Vector3(x+1,  y+1,  z+1)) # front-top
		st.add_vertex(Vector3(x+1, y, z)) # back-bottom
		st.add_vertex(Vector3(x+1, y,  z+1)) # front-bottom
	 
	if (culling_mask & FACE_TOP) != 0:
		st.set_normal(Vector3(0, 1, 0))
		st.add_vertex(Vector3(x,  y+1, z)) # back-left
		st.add_vertex(Vector3(x+1,  y+1, z)) # back-right
		st.add_vertex(Vector3(x+1,  y+1,  z+1)) # front-right
		st.add_vertex(Vector3(x,  y+1, z)) # back-left
		st.add_vertex(Vector3(x+1,  y+1,  z+1)) # front-right
		st.add_vertex(Vector3(x,  y+1,  z+1)) # front-left

	if (culling_mask & FACE_BOTTOM) != 0:
		st.set_normal(Vector3(0, -1, 0))
		st.add_vertex(Vector3(x, y, z)) # back-left
		st.add_vertex(Vector3(x+1, y,  z+1)) # front-right
		st.add_vertex(Vector3(x+1, y, z)) # back-right
		st.add_vertex(Vector3(x, y, z)) # back-left
		st.add_vertex(Vector3(x, y,  z+1)) # front-left
		st.add_vertex(Vector3(x+1, y,  z+1)) # front-right

func create_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			for z in range(CHUNK_SIZE):
				var cull: int = calculate_culling_mask(x,y,z)
				if cull == 0:
					continue
				create_cube(st, x, y, z, cull)

	mesh = st.commit()

func generate_chunk() -> void:
	blocks.resize(CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE)
	blocks.fill(BlockType.Grass) # super fast init

func delete_chunk() -> void:
	blocks = PackedByteArray()

func _ready() -> void:
	generate_chunk()
	create_mesh()
