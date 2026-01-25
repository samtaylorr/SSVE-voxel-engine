extends Control

@export var chunk_manager : ChunkManager

func _process(_delta):
	if chunk_manager.initial_load:
		visible = false
