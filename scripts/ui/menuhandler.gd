extends Control
class_name MenuHandler

@export var pages : Array[VBoxContainer]
@export var button_list : VBoxContainer

@export_category("Settings Menu")
@export var render_distance_slider : HSlider
@export var mouse_sensitivity_slider : HSlider

var hidden_menu := false

var new_world_name : String
var list_of_worlds : Array
var rng = RandomNumberGenerator.new()

func change_scene(path:String):
	get_tree().change_scene_to_file(path)

func quit_game():
	get_tree().quit()

func switch_page(index:int):
	for i in range(pages.size()):
		if i == index:
			pages[i].visible = true
		else:
			pages[i].visible = false

func _on_world_selected(world):
	WorldManager.selected_world = world
	WorldManager.load_world()
	change_scene("res://scenes/main.tscn")

func load_world():
	list_of_worlds = WorldManager.get_list_of_worlds()
	for child in button_list.get_children():
		child.queue_free()
	
	for world_data in list_of_worlds:
		var btn = Button.new()
		btn.text = world_data.get("name", world_data.get("folder_id", "Unknown World"))
		btn.pressed.connect(func(): _on_world_selected(world_data["folder_id"]))
		button_list.add_child(btn)

func new_world():
	WorldManager.create_world(new_world_name, rng.randi())
	WorldManager.set_world_params()
	change_scene("res://scenes/main.tscn")

func load_settings_into_ui():
	render_distance_slider.value = SettingsHandler.render_distance
	mouse_sensitivity_slider.value = SettingsHandler.mouse_sensitivity

func save_settings_from_ui():
	SettingsHandler.render_distance = render_distance_slider.value
	SettingsHandler.mouse_sensitivity = mouse_sensitivity_slider.value
	SettingsHandler.save_all_settings()

func update_new_world_name(new_text:String):
	new_world_name = new_text

func hide_menu():
	self.visible = false
	hidden_menu = true

func show_menu():
	self.visible = true
	hidden_menu = false

func _ready() -> void:
	switch_page(0)
