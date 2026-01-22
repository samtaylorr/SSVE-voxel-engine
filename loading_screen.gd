extends Control

func _process(_delta):
	if ChunkManager.initial_load:
		queue_free()
