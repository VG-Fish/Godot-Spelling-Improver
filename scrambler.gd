class_name Scrambler
extends Node
## Class for sensibly scrambling words.

## When instantiating the Scrambler class, make multiple Pattern objects to scramble words.
var _patterns: Array[Pattern]

## For special cases of _binary_search().
enum _binary_search_special_cases {
	## Returned when the substring wasn't found in patterns.
	NOT_FOUND = -2,
	## Returned when the substring was apart of a pattern, but it is not the complete pattern.
	IN_PATTERN = -1,
}

## Sort patterns array according to the [code]target[/code] of a pattern.
func sort_patterns() -> void: 
	_patterns.sort_custom(
		func(a: Pattern, b: Pattern): \
			return a.target < b.target
	)

## Add a pattern that will be searched for. If [code]add_opposite[/code] is true, another pattern with be added with
## [code]pattern.target[/code] & [code]pattern.replacement[/code] switched.
func add_pattern(pattern: Pattern, add_opposite: bool = false) -> void:
	_patterns.append(pattern)
	if add_opposite:
		_patterns.append(Pattern.new({
			"target": pattern.replacement,
			"replacement": pattern.target,
			"tip": pattern.tip,
			"chance": pattern.chance
		}))

## Delete a pattern that will no longer be searched for. If [code]delete_opposite[/code] is true, the opposite pattern
## will be deleted.
func delete_pattern(pattern: Pattern, delete_opposite: bool = false) -> void:
	_patterns.erase(pattern)
	if delete_opposite:
		_patterns.erase(Pattern.new({
			"target": pattern.replacement,
			"replacement": pattern.target,
			"tip": pattern.tip,
			"chance": pattern.chance
		}))

## Custom binary search for Array[Pattern].
func _binary_search(x: String) -> int:
	var low: int = 0
	var high: int = _patterns.size() - 1
	var mid: int
	var in_pattern: bool = false
	
	while low <= high:
		mid = (low + high) / 2
		if x == _patterns[mid].target:
			return mid
		elif x in _patterns[mid].target:
			in_pattern = true
			high = mid - 1
		elif _patterns[mid].target < x:
			low = mid + 1
		else:
			high = mid - 1
	
	if in_pattern:
		return _binary_search_special_cases.IN_PATTERN
	return _binary_search_special_cases.NOT_FOUND

## Scramble the word according to the patterns found in _patterns array.
## This algorithm scrambles the word by finding patterns in the [code]_patterns[/code] array
## and replacing them in word (input) with replacements defined in the [code]_patterns[/code] array.
func scramble_word(word: String) -> String:
	if _patterns.is_empty():
		return word
	# in order for binary search to work.
	sort_patterns()
	
	# variable that will be returned
	var scrambled_word: String = ""
	# window related vars.
	var window_start: int = 0
	var window_end: int = 1
	var window: String = ""
	var prev_window: String = ""
	var idx: int
	var chance_threshold: float
	
	while window_end <= word.length():
		# I use prev variables to minimize recalculations
		prev_window = window
		window = word.substr(window_start, window_end - window_start)
		idx = _binary_search(window)
		chance_threshold = randf()
		
		match idx:
			_binary_search_special_cases.NOT_FOUND:
				# This is to check if the last character of the window is apart of a new pattern, 
				# beacuse if so, we can't skip it since it may be the start of a new pattern.
				if _binary_search(window.substr(window.length() - 1, 1)) > -2:
					scrambled_word += prev_window
					window_start = window_end - 1
				else:
					scrambled_word += window
					window_start = window_end
					window_end += 1
			_binary_search_special_cases.IN_PATTERN:
				window_end += 1
			_:
				if _patterns[idx].chance > chance_threshold:
					scrambled_word += _patterns[idx].replacement
				else:
					scrambled_word += window
				window_start = window_end
				window_end += 1
	# Handling edge cases.
	# This happens when the window isn't found but the last character of the window is apart of a pattern & it's at 
	# the end of the string.
	if window_start < word.length():
		scrambled_word += window
	return scrambled_word

## The purpose of the Pattern class is to help aide in finding specific letter(s) & replacing them
## in a word, in an attempt to better scramble the word. This class is not supposed to be used by itself.
class Pattern:
	## The letter(s) to find in a word. This is required when [code]Patten[/code] is instantiated.
	var target: String 
	## What to place the target with. This is required when [code]Patten[/code] is instantiated.
	var replacement: String
	## This will be displayed to the user if they got the target part of the word wrong.
	## Default value is [code]"Don't mistake a(n) %s for a(n) %s" % [self.target, self.replacement][/code].
	## @experimental
	var tip: String
	## If the target is found, [code]chance[/code] is the percentage of target getting replaced by
	## [code]replacement[/code]. Default value is [code]0.5[/code].
	var chance: float

	func _init(args: Dictionary) -> void:
		self.target = args["target"]
		self.replacement = args["replacement"]
		self.tip = args.get("tip", "Don't mistake a(n) %s for a(n) %s." % [self.target, self.replacement])
		self.chance = args.get("chance", 0.5)

	func _to_string() -> String:
		return "<Pattern#%d = {\n\ttarget = %s,\n\treplacement = %s,\n\ttip = %s\n\tchance = %.3f\n}>" \
		% [self.get_instance_id(), self.target, self.replacement, self.tip, self.chance]
