extends Control
signal play_pause
signal time_selected(time : float)

var dragging : bool = false

var stream_duration : float
var loop_start : float = -1
var loop_end : float = -1
var loop_selected: bool = false

@onready var progress_bar = $UIContainer/ProgressBar
#@onready var time_total_label = $MarginContainer/Controls/TimeDisplay/TimeTotal
#@onready var time_current_label = $MarginContainer/Controls/TimeDisplay/TimeCurrent
@onready var VideoPlayer = $VideoStreamPlayer
@onready var start_stop_button = $UIContainer/StartStopButton



func _ready() -> void:
	get_viewport().files_dropped.connect(_on_files_dropped)
	
	start_stop_button.pressed.connect(_button_pressed)
	
	#VideoPlayer.stream = load("/home/edt/Downloads/VideoDownloader/Gnarls Barkley - Crazy - From the Basement.mp4")
	$VideoStreamPlayer.stream = load("/home/edt/Downloads/VideoDownloader/Bones Owens performs ＂Sunday Fix＂ ｜ Live from Carter Vintage Guitars ｜ Nashville, TN.mp4")
	stream_duration = $VideoStreamPlayer.get_stream_length()
	progress_bar.set_max(stream_duration)
	
	$Timer.timeout.connect(_timer_tick)
	$Timer.start()
	

func _input(event):
	if event is InputEventKey and event.pressed:
		print(OS.get_keycode_string(event.get_key_label_with_modifiers()))
		if event.keycode == KEY_SPACE and not Input.is_key_pressed(KEY_SHIFT):
			print("space was pressed")
			toggle_play_state()
		elif event.keycode == KEY_SPACE and Input.is_key_pressed(KEY_SHIFT):
			set_loop_section()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _timer_tick() -> void:
	var pos = $VideoStreamPlayer.get_stream_position()

	if loop_selected:
		if pos >= loop_end:
			$VideoStreamPlayer.set_stream_position(loop_start)
			pos = loop_start
	progress_bar.set_value(pos)	

func _on_files_dropped(files):
	print(files)

func set_loop_section() -> void:
	var pos = $VideoStreamPlayer.get_stream_position()
	print("pos: ", pos)
	
	if loop_start != -1:
		loop_end = pos
		loop_selected = true
	else:
		loop_start = pos

func _button_pressed():
	toggle_play_state()
	
func toggle_play_state() -> void:
	print("playing: ", $VideoStreamPlayer.is_playing(), " paused:",  $VideoStreamPlayer.is_paused())
	if $VideoStreamPlayer.is_playing() and not $VideoStreamPlayer.is_paused():
		start_stop_button.text = "Play"
		$VideoStreamPlayer.set_paused(true)
	elif $VideoStreamPlayer.is_playing() and $VideoStreamPlayer.is_paused():
		start_stop_button.text = "Pause"
		$VideoStreamPlayer.set_paused(false)
	else:
		start_stop_button.text = "Pause"
		$VideoStreamPlayer.play()
