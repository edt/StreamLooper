extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var button = Button.new()
	button.text = "Play"
	button.pressed.connect(_button_pressed)
	#add_child(button)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _button_pressed():
	$VideoStreamPlayer.play()
