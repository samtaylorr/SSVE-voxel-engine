extends Control

func _process(_delta):
	if ChunkManager.initial_load:
		visible = false
