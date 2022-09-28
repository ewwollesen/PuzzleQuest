extends Node2D

# States for state machine
enum {
	WAIT,
	MOVE,
}

# Play area variables
const WIDTH: int = 8
const HEIGHT: int = 8
const X_START: int = 336
const Y_START: int = 1040
const OFFSET: int = 64
const Y_OFFSET: int = 2

# The gems array
var possible_gems: Array = [
	preload("res://Pieces/FireGem.tscn"),
	preload("res://Pieces/EarthGem.tscn"),
	preload("res://Pieces/WindGem.tscn"),
	preload("res://Pieces/WaterGem.tscn"),
	preload("res://Pieces/DamageGem.tscn"),
	preload("res://Pieces/GoldGem.tscn"),
	preload("res://Pieces/XPGem.tscn"),
]

# Current pieces in the scene
var all_gems: Array = []
var clone_array: Array = []
var current_matches: Array = []

# Click  variables
var first_click: Vector2 = Vector2.ZERO
var final_click: Vector2 = Vector2.ZERO
var controlling: bool = false

# State variable
var state: int

# Swap back variabls
var gem_one: Object = null
var gem_two: Object = null
var last_position: Vector2 = Vector2.ZERO
var last_direction: Vector2 = Vector2.ZERO
var move_checked: bool = false

# Score variables
var earth_score: int = 0
var fire_score: int = 0
var water_score: int = 0 
var wind_score: int = 0
var gold_score: int = 0
var xp_score: int = 0

# Hint variables
var hint: Object = null
var hint_effect: PackedScene = preload("res://HintEffect.tscn")
var match_type: String = ""

onready var destroyTimer: = $"../DestroyTimer"
onready var collapseTimer: = $"../CollapseTimer"
onready var refillTimer: = $"../RefillTimer"
onready var deadlockTimer: = $"../DeadlockTimer"
onready var hintTimer: = $"../HintTimer"
onready var fireScore: = $"../ScoreBoard/FireScore"
onready var windScore: = $"../ScoreBoard/Wind"
onready var earthScore: = $"../ScoreBoard/Earth"
onready var waterScore: = $"../ScoreBoard/Water"
onready var xpScore: = $"../ScoreBoard/XP"
onready var goldScore: = $"../ScoreBoard/Gold"

func _ready() -> void:
	state = MOVE
	all_gems = make_array()
	clone_array = make_array()
	spawn_gems()


func _process(_delta: float) -> void:
	if state == MOVE:
		ui_click()


func is_in_array(array: Array, item: Vector2) -> bool:
	if array != null:
		for items in array.size():
			if array[items] == item:
				return true
	return false


func make_array() -> Array:
	var array: Array = []
	
	for x in WIDTH:
		array.append([])
		for y in HEIGHT:
			array[x].append(null)
	return array


func spawn_gems():
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for column in WIDTH:
		for row in HEIGHT:
			# Choose a random number
			var rand: int = rng.randi_range(0, possible_gems.size() - 1)
			# Instance that piece from the array
			var gem = possible_gems[rand].instance()
			var count: int = 0
			while(match_at(column, row, gem.type) and count < 100):
				rand = rng.randi_range(0, possible_gems.size() - 1)
				gem = possible_gems[rand].instance()
				count += 1
			add_child(gem)
			gem.position = grid_to_pixel(column, row)
			all_gems[column][row] = gem
	if is_no_matches():
		deadlockTimer.start()
	hintTimer.start()


func is_piece_null(column: int, row: int, array: Array = all_gems) -> bool:
	if array[column][row] == null:
		return true
	return false


func match_at(column: int, row: int, type: String) -> bool:
	if column > 1:
		if not is_piece_null(column - 1, row) and all_gems[column - 2][row]:
			if all_gems[column - 1][row].type == type and all_gems[column - 2][row].type == type:
				return true

	if row > 1:
		if not is_piece_null(column, row -1) and all_gems[column][row - 2]:
			if all_gems[column][row - 1].type == type and all_gems[column][row - 2].type == type:
				return true
	return false


func grid_to_pixel(column: int, row: int) -> Vector2:
	var new_x = X_START + OFFSET * column
	var new_y = Y_START - OFFSET * row
	return Vector2(new_x, new_y)
	
	
func pixel_to_grid(pixel_x: float, pixel_y: float) -> Vector2:
	var new_x: int = round((pixel_x - X_START) / OFFSET)	
	var new_y: int = round((pixel_y - Y_START) / -OFFSET)
	return Vector2(new_x, new_y)


func is_in_grid(grid_position: Vector2) -> bool:
	if grid_position.x >= 0 and grid_position.x < WIDTH:
		if grid_position.y >= 0 and grid_position.y < HEIGHT:
			return true
	return false
	
	
func ui_click() -> void:
	if Input.is_action_just_pressed("ui_click"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)):
			first_click = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			controlling = true
			destroy_hint()
	if Input.is_action_just_released("ui_click"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)) and controlling:
			controlling = false
			final_click = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			click_difference(first_click, final_click)


func swap_gems(column: int, row: int, direction: Vector2) -> void:
	var first_gem: Node2D = all_gems[column][row]
	var other_gem: Node2D = all_gems[column + direction.x][row + direction.y]
	if first_gem != null and other_gem != null:
		store_gems(first_gem, other_gem, Vector2(column, row), direction)
		state = WAIT
		all_gems[column][row] = other_gem
		all_gems[column + direction.x][row + direction.y] = first_gem
		first_gem.move(grid_to_pixel(column + direction.x, row + direction.y))
		other_gem.move(grid_to_pixel(column, row))
		if not move_checked:
			find_matches()


func store_gems(first_gem, other_gem, place, direction):
	gem_one = first_gem
	gem_two = other_gem
	last_position = place
	last_direction = direction


func swap_back():
	if gem_one != null and gem_two != null:
		swap_gems(last_position.x, last_position.y, last_direction)
	state = MOVE
	move_checked = false
	hintTimer.start()
	print("no match")


func click_difference(grid_start, grid_end) -> void:
	var difference: Vector2 = grid_end - grid_start
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_gems(grid_start.x, grid_start.y, Vector2.RIGHT)
		elif difference.x < 0:
			swap_gems(grid_start.x, grid_start.y, Vector2.LEFT)
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_gems(grid_start.x, grid_start.y, Vector2.DOWN)
		elif difference.y < 0:
			swap_gems(grid_start.x, grid_start.y, Vector2.UP)


func find_matches(query: bool = false, array: Array = all_gems):
	for column in WIDTH:
		for row in HEIGHT:
			if array[column][row] != null:
				var current_type: String = array[column][row].type
				if column > 0 and column < WIDTH - 1:
					if array[column -1][row] != null and array[column + 1][row] != null:
						if array[column - 1][row].type == current_type and array[column + 1][row].type == current_type:
							if query:
								match_type = current_type 
								return true
							match_and_dim(array[column - 1][row])
							match_and_dim(array[column][row])
							match_and_dim(array[column + 1][row])
				if row > 0 and row < HEIGHT - 1:
					if array[column][row -1] != null and array[column][row + 1] != null:
						if array[column][row - 1].type == current_type and array[column][row + 1].type == current_type:
							if query:
								match_type = current_type
								return true
							match_and_dim(array[column][row - 1])
							match_and_dim(array[column][row])
							match_and_dim(array[column][row + 1])
	if query:
		return false
	destroyTimer.start()


func match_and_dim(gem: Object) -> void:
	gem.matched = true
	gem.dim()


func keep_score(type):
#	print(type)
	if type == "earth":
		earth_score += 1
		earthScore.text = "Earth: {0}".format([earth_score])
#		print("earth: ", earth_score)
	elif type == "fire":
		fire_score += 1
		fireScore.text = "Fire: {0}".format([fire_score])
#		print("fire: ", fire_score)
	elif type == "water":
		water_score += 1
		waterScore.text = "Water: {0}".format([water_score])
#		print("water: ", water_score)
	elif type == "wind":
		wind_score += 1
		windScore.text = "Wind: {0}".format([wind_score])
#		print("wind: ", wind_score)
	elif type == "gold":
		gold_score += 1
		goldScore.text = "Gold: {0}".format([gold_score])
#		print("gold: ", gold_score)
	elif type == "xp":
		xp_score += 1
		xpScore.text = "XP: {0}".format([xp_score])
#		print("xp: ", xp_score)


func destroy_match() -> void:
	var was_matched: bool = false
	for column in WIDTH:
		for row in HEIGHT:
			if not is_piece_null(column, row):
				if all_gems[column][row].matched:
					was_matched = true
					keep_score(all_gems[column][row].type)
					all_gems[column][row].queue_free()
					all_gems[column][row] = null
	move_checked = true
	if was_matched:
		destroy_hint()
		collapseTimer.start()
	else:
		swap_back()


func collapse_columns() -> void:
	for column in WIDTH:
		for row in HEIGHT:
			if is_piece_null(column, row):
				for cell in range(row + 1, HEIGHT):
					if all_gems[column][cell] != null:
						all_gems[column][cell].collapse(grid_to_pixel(column, row))
						all_gems[column][row] = all_gems[column][cell]
						all_gems[column][cell] = null
						break
	refillTimer.start()


func refill_columns() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for column in WIDTH:
		for row in HEIGHT:
			if is_piece_null(column, row):
				# Choose a random number
				var rand: int = rng.randi_range(0, possible_gems.size() - 1)
				# Instance that piece from the array
				var gem = possible_gems[rand].instance()
				var count: int = 0
				while(match_at(column, row, gem.type) and count < 100):
					rand = rng.randi_range(0, possible_gems.size() - 1)
					gem = possible_gems[rand].instance()
					count += 1
				add_child(gem)
				gem.position = grid_to_pixel(column, row - Y_OFFSET)
				gem.collapse(grid_to_pixel(column, row))
				all_gems[column][row] = gem
	after_refill()


func after_refill() -> void:
	for column in WIDTH:
		for row in HEIGHT:
			if not is_piece_null(column, row):
				if match_at(column, row, all_gems[column][row].type):
					find_matches()
					destroyTimer.start()
					return
	state = MOVE
	move_checked = false
	if is_no_matches():
		print("No matches")
		deadlockTimer.start()
	hintTimer.start()


func switch_gems(place: Vector2, direction: Vector2, array: Array) -> void:
	if is_in_grid(place):
		if is_in_grid(place + direction):
			# First hold the piece to swap with
			var holder = array[place.x + direction.x][place.y + direction.y]
			# Then set the swap spot as the original piece
			array[place.x + direction.x][place.y + direction.y] = array[place.x][place.y]
			# Then set the original spot as the other piece
			array[place.x][place.y] = holder


func switch_and_check(place: Vector2, direction: Vector2, array: Array) -> bool:
	switch_gems(place, direction, array)
	if find_matches(true, array):
		switch_gems(place, direction, array)
		return true
	switch_gems(place, direction, array)
	return false

func is_no_matches() -> bool:
	# Create copy of main array
	clone_array = copy_array(all_gems)
	for column in WIDTH:
		for row in HEIGHT:
			# Switch and check right
			if switch_and_check(Vector2(column, row), Vector2.RIGHT, clone_array):
				return false
			# Switch and check up
			if switch_and_check(Vector2(column, row), Vector2.UP, clone_array):
				return false
	return true


func copy_array(array_to_copy: Array) -> Array:
	var new_array: Array = make_array()
	for column in WIDTH:
		for row in HEIGHT:
			new_array[column][row] = array_to_copy[column][row]
	return new_array


func clear_and_store_board() -> Array:
	var holder_array: Array = []
	for column in WIDTH:
		for row in HEIGHT:
			if not is_piece_null(column, row):
				holder_array.append(all_gems[column][row])
				all_gems[column][row] = null
	return holder_array


func shuffle_board():
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var holder_array: Array = clear_and_store_board()
	for column in WIDTH:
		for row in HEIGHT:
			if all_gems[column][row] == null:
				# Choose a random number
				var rand: int = rng.randi_range(0, holder_array.size() - 1)
				# Instance that piece from the array
				var gem = holder_array[rand]
				var count: int = 0
				while(match_at(column, row, gem.type) and count < 100):
					rand = rng.randi_range(0, holder_array.size() - 1)
					gem = holder_array[rand]
					count += 1
				gem.move(grid_to_pixel(column, row))
				all_gems[column][row] = gem
				holder_array.remove(rand)
	if is_no_matches():
		deadlockTimer.start()
	state = MOVE


func find_all_matches() -> Array:
	var match_holder: Array = []
	clone_array = copy_array(all_gems)
	for column in WIDTH:
		for row in HEIGHT:
			if not is_piece_null(column, row):
				if switch_and_check(Vector2(column, row), Vector2(1,0), clone_array) and is_in_grid(Vector2(column + 1, row)):
					#add piece column,row to match_holder
					if match_type != "":
						if match_type == clone_array[column][row].type:
							match_holder.append(clone_array[column][row])
						else:
							match_holder.append(clone_array[column + 1][row])
						
				if switch_and_check(Vector2(column, row), Vector2(0,1), clone_array) and is_in_grid(Vector2(column, row + 1)):
					#add piece column,row to match_holder
					if match_type != "":
						if match_type == clone_array[column][row].type:
							match_holder.append(clone_array[column][row])
						else:
							match_holder.append(clone_array[column][row + 1])
	return match_holder


func generate_hint() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var hints: Array = find_all_matches()
	if hints != null:
		if hints.size() > 0:
			destroy_hint()
			var rand: int = rng.randi_range(0, hints.size() - 1)
			hint = hint_effect.instance()
			add_child(hint)
			hint.position = hints[rand].position
			hint.setup(hints[rand].get_node("Sprite").texture)


func destroy_hint():
	if hint:
		hint.queue_free()
		hint = null


func ai_move():
	destroy_hint()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var moves: Array = find_all_matches()
	print(moves)
	if moves != null:
		if moves.size() > 0:
			var rand: int = rng.randi_range(0, moves.size() - 1)
			var gem = pixel_to_grid(moves[rand].position.x, moves[rand].position.y)
			var column = gem.x
			var row = gem.y
			print("gem: ", gem)
#			swap_gems(gem.x, gem.y, Vector2.RIGHT)
			#func switch_and_check(place: Vector2, direction: Vector2, array: Array) -> bool:
			clone_array = copy_array(all_gems)
			if switch_and_check(gem, Vector2(1,0), clone_array) and is_in_grid(Vector2(column + 1, row)):
				#add piece column,row to match_holder
				if match_type != "":
					if match_type == clone_array[column][row].type:
						swap_gems(column, row, Vector2(1,0))
						print("test 1")
#					else:
#						swap_gems(column + 1, row, Vector2(1,0))
						
			elif switch_and_check(gem, Vector2(0,1), clone_array) and is_in_grid(Vector2(column, row + 1)):
				#add piece column,row to match_holder
				if match_type != "":
					if match_type == clone_array[column][row].type:
						swap_gems(column, row, Vector2(0, 1))
						print("test2")
#					else:
#						swap_gems(column, row +1, Vector2(1,0))
			
			elif switch_and_check(gem, Vector2(-1,0), clone_array) and is_in_grid(Vector2(column - 1, row)):
				#add piece column,row to match_holder
				if match_type != "":
					if match_type == clone_array[column][row].type:
						swap_gems(column, row, Vector2(-1,0))
						print("test3")
#					else:
#						swap_gems(column - 1, row, Vector2(-1,0))
						
			elif switch_and_check(gem, Vector2(0,-1), clone_array) and is_in_grid(Vector2(column, row - 1)):
				#add piece column,row to match_holder
				if match_type != "":
					if match_type == clone_array[column][row].type:
						swap_gems(column, row, Vector2(0, -1))
						print("test4")
#					else:
#						swap_gems(column, row -1, Vector2(-1,0))

func _on_DestroyTimer_timeout():
	destroy_match()


func _on_CollapseTimer_timeout():
	collapse_columns()


func _on_RefillTimer_timeout():
	refill_columns()


func _on_DeadlockTimer_timeout():
	shuffle_board()


func _on_HintTimer_timeout():
	generate_hint()


func _on_Button_button_up() -> void:
	print("Pressed")
	ai_move()
