extends Node

@export var world_folder : String
var level_data : Dictionary
var save_folder : String = "user://saves/"
var selected_world : String

func set_world_params():
	var world_seed = level_data.get("seed", -1)
	ChunkHelper.Seed = world_seed

func get_data_from_path(folder_path: String) -> Dictionary:
	var path = folder_path + "/level.dat"
	if not FileAccess.file_exists(path):
		printerr("File does not exist: ", path)
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		printerr("Could not open file. Error code: ", FileAccess.get_open_error())
		return {}

	return file.get_var()

func load_world():
	var dir_str = save_folder.path_join(selected_world)
	var data = get_data_from_path(dir_str)
	
	if data.is_empty():
		printerr("Failed to load world at: ", dir_str)
	else:
		level_data = data
		set_world_params()

func create_world(_name:String, _seed:int):
	var dir_str = save_folder + _name.to_camel_case()
	var new_level_data = {
		"name": _name,
		"seed": _seed,
		"created_at": Time.get_unix_time_from_system()
	}
	
	# Check if the directory exists; if not, create it.
	if not DirAccess.dir_exists_absolute(dir_str):
		var dir_err = DirAccess.make_dir_recursive_absolute(dir_str)
		if dir_err != OK:
			printerr("Failed to create directory! Error: ", dir_err)
			return
	
	var file = FileAccess.open(dir_str.path_join("level.dat"), FileAccess.WRITE)
	if file:
		file.store_var(new_level_data)
		file.close()
		
		selected_world = _name.to_camel_case()
		load_world()

func get_list_of_worlds() -> Array:
	var worlds = []
	var dir = DirAccess.open(save_folder)
	
	if not dir:
		first_time_setup()
		return []

	dir.list_dir_begin()
	var folder_name = dir.get_next()

	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			var world_info = save_folder.path_join(folder_name)
			var data = get_data_from_path(world_info)
			if not data.is_empty():
				data["folder_id"] = folder_name
				worlds.append(data)
		folder_name = dir.get_next()

	return worlds

func first_time_setup():
	var base_path = "user://saves"
	if not DirAccess.dir_exists_absolute(base_path):
		var err = DirAccess.make_dir_recursive_absolute(base_path)
		if err != OK:
			printerr("Could not create save directory! Error: ", err)

func _ready() -> void:
	first_time_setup()
