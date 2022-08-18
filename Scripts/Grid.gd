extends Node2D

# Play area variables
const WIDTH: int = 8
const HEIGHT: int = 8
const X_START: int = 336
const Y_START: int = 1040
const OFFSET: int = 64

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

func _ready() -> void:
	all_gems = make_array()
	spawn_gems()
	#print(all_gems)


func _process(_delta: float) -> void:
	ui_click()


func make_array() -> Array:
	var array = []
	
	for x in WIDTH:
		array.append([])
		for y in HEIGHT:
			array[x].append(null)
	return array


func spawn_gems():
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for x in WIDTH:
		for y in HEIGHT:
			# Choose a random number
			var rand: int = rng.randi_range(0, possible_gems.size() - 1)
			# Instance that piece from the array
			var gem = possible_gems[rand].instance()
			var count: int = 0
			while(match_at(x, y, gem.type) and count < 100):
				rand = rng.randi_range(0, possible_gems.size() - 1)
				gem = possible_gems[rand].instance()
				count += 1

			add_child(gem)
			gem.position = grid_to_pixel(x, y)
			all_gems[x][y] = gem


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
	all_gems[column][row] = other_gem
	all_gems[column + direction.x][row + direction.y] = first_gem
	#first_gem.position = grid_to_pixel(column + direction.x, row + direction.y)
	#other_gem.position = grid_to_pixel(column, row)
	first_gem.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_gem.move(grid_to_pixel(column, row))
	find_matches()
		
	
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


func find_matches():
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
