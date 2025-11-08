extends Node

const unit = preload("res://unit.tscn")

#const lane_spacing = 112
#const top_lane_pos = 88
#const lane_count = 5

const grid_spacing = 112
const grid_origin = Vector2i(88, 88)
const grid_size = Vector2i(10, 5)

var grid = []
func _ready():
	for i in range(grid_size.x):
		grid.append([])
		grid[i].resize(grid_size.y)
		
	var unit_instance = unit.instantiate()
	get_tree().root.add_child.call_deferred(unit_instance)
	unit_instance.is_enemy = true
	unit_instance.init_position(Vector2i(9, 2))
		
func process_turn():
	var grid_copy = grid.duplicate(true)
	for col in grid_copy:
		for elem in col:
			if elem:
				elem._process_turn()
