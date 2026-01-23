extends MeshInstance3D
class_name HighlightCube

const OUTLINE_SHADER = preload("res://shaders/wireframe.gdshader")

func _ready() -> void:
	self.mesh = ChunkHelper.create_selection_mesh()
	var mat = ShaderMaterial.new()
	mat.shader = OUTLINE_SHADER
	self.material_override = mat

func snap_to_highlight(pos:Vector3):
	var block_pos = Vector3i(floor(pos.x), floor(pos.y), floor(pos.z))
	self.global_position = block_pos
	self.visible = true

func remove_highlight():
	self.visible = false
