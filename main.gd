extends Control

# Generic vars
var length: int
var word_arr: PackedStringArray
var curr_word: String
var scrambled_curr_word: String
var score: int = 0
var words_attempted: int = 0
var success_rate: float
var vowels: PackedStringArray = "aeiou".split()
var scrambler: Scrambler = preload("res://scrambler.gd").new()
var is_paused: bool = false

# For tts
var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language("en")
var voice_id: String = voices[0]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	word_arr = load_file("words.txt")
	length = word_arr.size()
	_initialize_patterns()
	new_word()
 
func _initialize_patterns() -> void:
	scrambler.add_pattern(scrambler.Pattern.new({
		"target": "ie", 
		"replacement": "ei", 
		"tip": "It will only be ei with the ei is before a c. Otherwise, assume ie.",
		"chance": 0.5
	}))
	scrambler.add_pattern(scrambler.Pattern.new({
		"target": "ph",
		"replacement": "f",
		"tip": "While ph sounds like f, it's spelled ph.",
		"chance": 0.1
	}))
	scrambler.add_pattern(scrambler.Pattern.new({
		"target": "oa", 
		"replacement": "ao",
		"chance": 0.1
	}))
	scrambler.add_pattern(scrambler.Pattern.new({
		"target": "a", 
		"replacement": "e",
		"chance": 0.3
	}))
	scrambler.add_pattern(scrambler.Pattern.new({
		"target": "s", 
		"replacement": "c",
		"chance": 0.4
	}), true)
	scrambler.add_pattern(scrambler.Pattern.new({
		"target": "c", 
		"replacement": "k",
		"chance": 0.25
	}), true)
	scrambler.add_pattern(scrambler.Pattern.new({
		"target": "k", 
		"replacement": "s",
		"chance": 0.25
	}), true)
	scrambler.add_pattern(scrambler.Pattern.new({
		"target": "y", 
		"replacement": "i",
		"chance": 0.25
	}), true)
	scrambler.add_pattern(scrambler.Pattern.new({
		"target": "ss", 
		"replacement": "s",
		"chance": 0.5
	}))

func load_file(path: String) -> PackedStringArray:
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	return content.split("\n", false)

func _on_new_word_pressed():
	new_word()

func new_word() -> void:
	curr_word = word_arr[randi_range(0, length - 1)].to_lower()
	speak_curr_word()
	scrambled_curr_word = scrambler.scramble_word(curr_word)
	$"CanvasLayer/VBoxContainer/Current Word".text = "Spell the word correctly: " + scrambled_curr_word
	$CanvasLayer/VBoxContainer/Diff.clear()

func _on_editor_text_submitted(new_text: String) -> void:
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()
	if new_text.is_empty():
		new_word()
		return
	
	words_attempted += 1
	if curr_word == new_text:
		$"CanvasLayer/VBoxContainer/Current Word".text = "You spelled %s correctly." % curr_word
		score += 1
	else:
		$"CanvasLayer/VBoxContainer/Current Word".text = "You spelled %s incorrectly." % curr_word
	
	show_diff(new_text)
	await get_tree().create_timer(2, false).timeout # wait x seconds
	
	update_score()
	$CanvasLayer/VBoxContainer/Editor.text = ""
	new_word()

func update_score() -> void:
	success_rate = float(score) / float(words_attempted) * 100
	success_rate = success_rate if not is_nan(success_rate) else 0.0
	$CanvasLayer/Score.text = \
	"Score: %d\nWords Attempted: %d\nSuccess Rate: %.2f%%" \
	 % [score, words_attempted, success_rate]

func show_diff(input: String) -> void:
	var input_diff: String = "" 
	var word_diff: String  = ""
	
	# Check input
	for i in range(min(input.length(), curr_word.length())):
		if curr_word[i] == input[i]:
			input_diff += curr_word[i]
			word_diff += curr_word[i]
		else:
			input_diff += "[color=red]%s[/color]" % input[i]
			word_diff += "[color=green]%s[/color]" % curr_word[i]
	
	# In case the input was less than the actual word
	for i in range(input.length(), curr_word.length()):
		word_diff += "[color=green]%s[/color]" % curr_word[i]
	
	# In case the input was greater than the actual word
	for i in range(curr_word.length(), input.length()):
		input_diff += "[color=red]%s[/color]" % input[i]
	
	$CanvasLayer/VBoxContainer/Diff.clear()
	var left_text: String = "Inputted Word:\nCorrect Word:\nScrambled Word:"
	var right_text: String = "%s\n%s\n%s" % [input_diff, word_diff, scrambled_curr_word]
	$CanvasLayer/VBoxContainer/Diff.append_text(
		"[table=2]
		[cell]%s[/cell]
		[cell]%s[/cell]
		[/table]" % [left_text, right_text]
	)
	save_words(input_diff, word_diff)

func save_words(input_diff: String, word_diff: String) -> void:
	var file = FileAccess.open("res://log.txt", FileAccess.WRITE)
	file.store_line("%s\n%s" % [input_diff, word_diff])

func _on_speak_pressed() -> void:
	speak_curr_word()

func speak_curr_word() -> void:
	if not DisplayServer.tts_is_speaking():
		DisplayServer.tts_speak(curr_word, voice_id)

func _on_slow_pressed() -> void:
	if not DisplayServer.tts_is_speaking():
		DisplayServer.tts_speak(curr_word, voice_id, 50, 1.0, 0.25)

func _on_fast_pressed() -> void:
	if not DisplayServer.tts_is_speaking():
		DisplayServer.tts_speak(curr_word, voice_id, 50, 1.0, 3.0)

func _on_reset_pressed():
	words_attempted = 0
	score = 0
	update_score()

func _on_pause_pressed():
	is_paused = not is_paused
	get_tree().paused = is_paused
	if is_paused:
		$CanvasLayer/VBoxContainer/Pause.text = "Game is paused."
	else:
		$CanvasLayer/VBoxContainer/Pause.text = "Pause Game"
