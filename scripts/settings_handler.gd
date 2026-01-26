extends Node

# Create new ConfigFile object.
const SETTINGS_PATH = "user://settings.cfg"
var config = ConfigFile.new()

var render_distance := 8
var mouse_sensitivity := 0.002

func _ready() -> void:
	# Load data from a file.
	config.load(SETTINGS_PATH)
	
	if config.get_sections().is_empty():
		config.set_value("Graphics", "render_distance", render_distance)
		config.set_value("Controls", "mouse_sensitivity", mouse_sensitivity)
	
	render_distance = config.get_value("Graphics", "render_distance", render_distance)
	mouse_sensitivity = config.get_value("Controls", "mouse_sensitivity", mouse_sensitivity)
	config.save(SETTINGS_PATH)

func save_all_settings():
	config.set_value("Graphics", "render_distance", render_distance)
	config.set_value("Controls", "mouse_sensitivity", mouse_sensitivity)
	config.save(SETTINGS_PATH)
