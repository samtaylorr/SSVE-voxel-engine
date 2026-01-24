extends ReferenceRect
class_name SlotHandler

@export var slots : Array[Control]
# TODO: Automatically set individual texture atlases in slots to the right BlockType.


var blocks_in_slots = {
	0: ChunkHelper.BlockType.Dirt,
	1: ChunkHelper.BlockType.Grass,
	2: ChunkHelper.BlockType.Stone,
	3: ChunkHelper.BlockType.Planks,
	4: ChunkHelper.BlockType.Cobblestone
}

func change_highlighted_slot(slot:int):
	if slot > slots.size() or slot < 0:
		return
	else:
		position = Vector2(slots[slot].position.x, position.y)
