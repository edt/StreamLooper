extends Control

const SUPPORTED_VIDEO: Array[String] = ["ogv", "mp4", "webm", "mov", "avi"]
const SUPPORTED_AUDIO: Array[String] = ["mp3", "wav", "ogg"]
# Also tested, not working: .swf

enum Stream_Type {VIDEO, AUDIO}

var loop_start : float = -1
var loop_end : float = -1
var stream_duration: float = 1.0
var stream_name: String
var stream_type: Stream_Type

@onready var progress_bar = $UIContainer/VBoxContainer/ProgressSlider
@onready var VideoPlayer = $AspectRatioContainer/VideoStreamPlayer
@onready var AudioPlayer = $AudioStreamPlayer
@onready var start_stop_button = $UIContainer/StartStopButton
@onready var loop_range = $UIContainer/VBoxContainer/HRangeSlider


func _ready() -> void:

	get_tree().root.files_dropped.connect(_on_files_dropped)
	start_stop_button.pressed.connect(_button_pressed)
	progress_bar.value_changed.connect(_timestamp_changed)
	loop_range.changed.connect(loop_selection_changed)
	
	var args = OS.get_cmdline_args()
	print("args: ", args)
	for arg in args:
		if FileAccess.file_exists(arg):
			_setup_stream(arg)
			break

	$Timer.timeout.connect(_timer_tick)


# callback for ProgressSlider
func _timestamp_changed(new_timestamp: float) -> void:
	update_stream_position(new_timestamp)
	
	
# update all things related to the current stream position
func update_stream_position(new_timestamp: float) -> void:
	if stream_type == Stream_Type.VIDEO:
		VideoPlayer.set_stream_position(new_timestamp)
	else:
		AudioPlayer.play(new_timestamp)
	update_label()
	

func update_label() ->void:
	var pos = get_stream_position()
	$UIContainer/VBoxContainer2/current_playtime_label.text=str(pos).pad_decimals(2)
	
	
func _input(event):
	if event is InputEventKey and event.pressed:
		print(OS.get_keycode_string(event.get_key_label_with_modifiers()))
		if event.keycode == KEY_SPACE and not Input.is_key_pressed(KEY_SHIFT):
			print("space was pressed")
			toggle_play_state()
		elif event.keycode == KEY_SPACE and Input.is_key_pressed(KEY_SHIFT):
			#set_loop_section()
			pass
		elif event.keycode == KEY_LEFT:
			update_stream_position(VideoPlayer.get_stream_position() - 5)
		elif event.keycode == KEY_RIGHT:
			update_stream_position(VideoPlayer.get_stream_position() + 5)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func get_stream_position() -> float:
	if stream_type == Stream_Type.VIDEO:
		return VideoPlayer.get_stream_position()
	else:
		return AudioPlayer.get_playback_position()


func set_stream_position(new_timestamp: float) -> void:
	if stream_type == Stream_Type.VIDEO:
		VideoPlayer.set_stream_position(new_timestamp)
	else:
		AudioPlayer.play(new_timestamp)

func _timer_tick() -> void:
	var pos = get_stream_position()
	
	if pos >= loop_end:
		set_stream_position(loop_start)
		pos = loop_start
	progress_bar.set_value_no_signal(pos)
	update_label()


func _on_files_dropped(files):
	print("............")
	print(files)
	_setup_stream(files.get(0))


func _stop_stream() -> void:
	VideoPlayer.stop()
	$Timer.stop()
	AudioPlayer.stop()


# initialize all elements for a new stream
func _setup_stream(file_name: String) -> void:
	
	_stop_stream()
	
	print("Loading ", file_name)
	if file_name.get_extension() in SUPPORTED_VIDEO:
		VideoPlayer.stream = load(file_name)
		stream_duration = VideoPlayer.get_stream_length()
		stream_name = VideoPlayer.get_stream_name()
		stream_type = Stream_Type.VIDEO
	elif file_name.get_extension() in SUPPORTED_AUDIO:
		# for some unknown reason calling load does not work
		# so instead we manually call the correct AudioStream constructor
		# AudioPlayer.stream = load(file_name)
		if file_name.get_extension() == "ogg":
			AudioPlayer.stream = AudioStreamOggVorbis.load_from_file(file_name)
		elif file_name.get_extension() == "mp3":
			AudioPlayer.stream = AudioStreamMP3.load_from_file(file_name)
		elif file_name.get_extension() == "wav":
			AudioPlayer.stream = AudioStreamWAV.load_from_file(file_name)
		else:
			OS.alert("Cannot load file.")
			return
		stream_duration = AudioPlayer.stream.get_length()
		stream_name = AudioPlayer.stream.get_name()
		stream_type = Stream_Type.AUDIO
		
	progress_bar.set_max(stream_duration)
	
	loop_end = stream_duration
	loop_start = 0
	
	loop_range.minimum=0
	loop_range.maximum = stream_duration
	loop_range.range_min_size = 2
	loop_range.range_begin = 0
	loop_range.range_end = stream_duration

	
	$UIContainer/VBoxContainer2/current_playtime_label.text= "0"
	$UIContainer/VBoxContainer2/max_playtime_label.text = str(stream_duration).pad_decimals(2)
	$UIContainer/VBoxContainer2/loop_begin_label.text= "0"
	$UIContainer/VBoxContainer2/loop_end_label.text=str(stream_duration).pad_decimals(2)
	
	get_window().title = "StreamLooper - " + stream_name
	
	$Timer.start()


func loop_selection_changed(range_begin : float, range_end : float):
	loop_start=range_begin
	loop_end=range_end
	$UIContainer/VBoxContainer2/loop_begin_label.text= str(range_begin).pad_decimals(2)
	$UIContainer/VBoxContainer2/loop_end_label.text=str(range_end).pad_decimals(2)


# callback play/pause button
func _button_pressed():
	toggle_play_state()
	
	
func toggle_play_state() -> void:
	
	if stream_type == Stream_Type.VIDEO:
		_toggle_video_play_state()
	else:
		_toggle_audio_play_state()

func _toggle_video_play_state() -> void:
	print("playing: ", VideoPlayer.is_playing(), " paused:",  VideoPlayer.is_paused())
	if VideoPlayer.is_playing() and not VideoPlayer.is_paused():
		start_stop_button.text = "Play"
		VideoPlayer.set_paused(true)
	elif VideoPlayer.is_playing() and VideoPlayer.is_paused():
		start_stop_button.text = "Pause"
		VideoPlayer.set_paused(false)
	else:
		start_stop_button.text = "Pause"
		VideoPlayer.play()

func _toggle_audio_play_state() -> void:
	if AudioPlayer.is_playing():
		start_stop_button.text = "Pause"
		AudioPlayer.stop()
	else:
		start_stop_button.text = "Play"
		AudioPlayer.play()
	
	
