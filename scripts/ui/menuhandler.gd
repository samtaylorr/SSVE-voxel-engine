extends Control

@export var pages : Array[VBoxContainer]
@export var button_list : VBoxContainer

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

func update_new_world_name(new_text:String):
	new_world_name = new_text

func _ready() -> void:
	switch_page(0)
