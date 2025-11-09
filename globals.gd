extends Node

var rng = RandomNumberGenerator.new()

const unit = preload("res://unit.tscn")

#const lane_spacing = 112
#const top_lane_pos = 88
#const lane_count = 5

const grid_spacing = 112
const grid_origin = Vector2i(88, 88)
const grid_size = Vector2i(10, 5)

var grid = []

var turn_count = 0

func _ready():
	for i in range(grid_size.x):
		grid.append([])
		grid[i].resize(grid_size.y)

func process_turn():
	var grid_copy = grid.duplicate(true)
	for col in grid_copy:
		for elem in col:
			if elem:
				elem._process_turn()
	
	# Enemy spawning
	if turn_count % 2 == 0:
		var enemy_spawn_col = grid[grid_size.x - 1]
		var open_spawn_spaces = []
		for i in range(enemy_spawn_col.size()):
			if !enemy_spawn_col[i]:
				open_spawn_spaces.append(i)
		if open_spawn_spaces.size() != 0:
			var spawn_space = open_spawn_spaces.pick_random()
			var unit_instance = unit.instantiate()
			get_tree().root.add_child.call_deferred(unit_instance)
			unit_instance.is_enemy = true
			unit_instance.init(Vector2i(grid_size.x - 1, spawn_space))
			unit_instance.attack_form = rng.randi() % 3
	
	turn_count += 1
