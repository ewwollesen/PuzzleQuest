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

onready var destroyTimer: = $"../DestroyTimer"
onready var collapseTimer: = $"../CollapseTimer"
onready var refillTimer: = $"../RefillTimer"
onready var fireScore: = $"../VBoxContainer/FireScore"
onready var windScore: = $"../VBoxContainer/Wind"
onready var earthScore: = $"../VBoxContainer/Earth"
onready var waterScore: = $"../VBoxContainer/Water"
onready var xpScore: = $"../VBoxContainer/XP"
onready var goldScore: = $"../VBoxContainer/Gold"

func _ready() -> void:
	state = MOVE
	all_gems = make_array()
	spawn_gems()


func _process(_delta: float) -> void:
	if state == MOVE:
		ui_click()


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


func match_at(column: int, row: int, type: String) -> bool:
	if column > 1:
		if all_gems[column - 1][row] != null and all_gems[column - 2][row]:
			if all_gems[column - 1][row].type == type and all_gems[column - 2][row].type == type:
				return true

	if row > 1:
		if all_gems[column][row - 1] != null and all_gems[column][row - 2]:
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
		#print("First_gem column: ", column, " row: ", row)
		#print("Other_gem column: ", column, " row: ", row)
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


func find_matches() -> void:
	for column in WIDTH:
		for row in HEIGHT:
			if all_gems[column][row] != null:
				var current_type: String = all_gems[column][row].type
				if column > 0 and column < WIDTH - 1:
					if all_gems[column - 1][row] != null and all_gems[column + 1][row] != null:
						if all_gems[column - 1][row].type == current_type and all_gems[column + 1][row].type == current_type:
							all_gems[column - 1][row].matched = true
							all_gems[column - 1][row].dim()
							all_gems[column][row].matched = true
							all_gems[column][row].dim()
							all_gems[column + 1][row].matched = true
							all_gems[column + 1][row].dim()
				if row > 0 and row < HEIGHT - 1:
					if all_gems[column][row - 1] != null and all_gems[column][row + 1] != null:
						if all_gems[column][row - 1].type == current_type and all_gems[column][row + 1].type == current_type:
							all_gems[column][row - 1].matched = true
							all_gems[column][row - 1].dim()
							all_gems[column][row].matched = true
							all_gems[column][row].dim()
							all_gems[column][row + 1].matched = true
							all_gems[column][row + 1].dim()
	destroyTimer.start()
	

func keep_score(type):
	print(type)
	if type == "earth":
		earth_score += 1
		earthScore.text = "Earth: {0}".format([earth_score])
		print("earth: ", earth_score)
	elif type == "fire":
		fire_score += 1
		fireScore.text = "Fire: {0}".format([fire_score])
		print("fire: ", fire_score)
	elif type == "water":
		water_score += 1
		waterScore.text = "Water: {0}".format([water_score])
		print("water: ", water_score)
	elif type == "wind":
		wind_score += 1
		windScore.text = "Wind: {0}".format([wind_score])
		print("wind: ", wind_score)
	elif type == "gold":
		gold_score += 1
		goldScore.text = "Gold: {0}".format([gold_score])
		print("gold: ", gold_score)
	elif type == "xp":
		xp_score += 1
		xpScore.text = "XP: {0}".format([xp_score])
		print("xp: ", xp_score)


func destroy_match() -> void:
	var was_matched: bool = false
	for column in WIDTH:
		for row in HEIGHT:
			if all_gems[column][row] != null:
				if all_gems[column][row].matched:
					was_matched = true
					keep_score(all_gems[column][row].type)
					all_gems[column][row].queue_free()
					all_gems[column][row] = null
	move_checked = true
	if was_matched:
		collapseTimer.start()
	else:
		swap_back()


func collapse_columns() -> void:
	for column in WIDTH:
		for row in HEIGHT:
			if all_gems[column][row] == null:
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
			if all_gems[column][row] == null:
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
			if all_gems[column][row] != null:
				if match_at(column, row, all_gems[column][row].type):
					find_matches()
					destroyTimer.start()
					return
	state = MOVE
	move_checked = false


func _on_DestroyTimer_timeout():
	destroy_match()


func _on_CollapseTimer_timeout():
	collapse_columns()


func _on_RefillTimer_timeout():
	refill_columns()
