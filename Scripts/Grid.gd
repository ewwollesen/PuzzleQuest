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

func _ready() -> void:
	all_gems = make_array()
	spawn_gems()


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
	var default_return = false
	if column > 1:
		if all_gems[column - 1][row] != null and all_gems[column - 2][row]:
			if all_gems[column - 1][row].type == type and all_gems[column - 2][row].type == type:
				return true

	if row > 1:
		if all_gems[column][row - 1] != null and all_gems[column][row - 2]:
			if all_gems[column][row - 1].type == type and all_gems[column][row - 2].type == type:
				return true
	return default_return


func grid_to_pixel(column: int, row: int) -> Vector2:
	var new_x = X_START + OFFSET * row
	var new_y = Y_START - OFFSET * column
	return Vector2(new_x, new_y)
	

func ui_click():
	if Input.is_action_just_pressed("ui_click"):
		first_click = get_global_mouse_position()
	if Input.is_action_just_released("ui_click"):
		final_click = get_global_mouse_position()
