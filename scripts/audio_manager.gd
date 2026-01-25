extends AudioStreamPlayer

var rng = RandomNumberGenerator.new()

var SFX : Dictionary = {
	"step": [
		preload("res://sounds/step1.ogg"),
		preload("res://sounds/step2.ogg"),
		preload("res://sounds/step3.ogg"),
		preload("res://sounds/step4.ogg")
	],
	"place": [preload("res://sounds/place.ogg")],
	"destroy": [preload("res://sounds/destroy.ogg")]
}

func play_sfx(effect_name: String):
	var clip = SFX[effect_name]
	
	# If it's an array (like steps), pick one. If not, play it directly.
	if clip is Array:
		stream = clip.pick_random()
	else:
		stream = clip
		
	play()

func _ready() -> void:
	max_polyphony = 8
