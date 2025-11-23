extends Node

var rng = RandomNumberGenerator.new()

const unit = preload("res://Scenes/Friendlies/f_melee.tscn")

var player_base_health_label:
	get:
		var node = get_tree().root.get_node("Game/PlayerBaseHealthLabel")
		if !node:
			print("Attempted to access PlayerBaseHealthLabel, but could not find it")
		return node
		
var enemy_base_health_label:
	get:
		var node = get_tree().root.get_node("Game/EnemyBaseHealthLabel")
		if !node:
			print("Attempted to access EnemyBaseHealthLabel, but could not find it")
		return node
		
var ap_label:
	get:
		var node = get_tree().root.get_node("Game/APLabel")
		if !node:
			print("Attempted to access APLabel, but could not find it")
		return node

const grid_spacing = 112
const grid_origin = Vector2i(88, 88)
const grid_size = Vector2i(10, 5)

var grid = []

enum TurnPhase { SPAWN, CARD, BATTLE, MOVE, BASE }
var turn_phase
var turn_count = 0

var spawn_freqs = [["e_melee", 2], ["e_melee", 2], ["e_tank", 2]]

var player_base_health: int:
	get:
		return player_base_health
	set(value):
		player_base_health = value
		player_base_health_label.text = "Player Base: %d" % value

var enemy_base_health: int:
	get:
		return enemy_base_health
	set(value):
		enemy_base_health = value
		enemy_base_health_label.text = "Enemy Base: %d" % value

var player_ap: int:
	get:
		return player_ap
	set(value):
		player_ap = value
		ap_label.text = "AP: %d" % value

var death_queue = []

func _ready():
	for i in range(grid_size.x):
		grid.append([])
		grid[i].resize(grid_size.y)
	player_base_health = 10
	enemy_base_health = 10
	player_ap = 3
	turn_phase = TurnPhase.SPAWN

func _process(_delta):
	match(turn_phase):
		TurnPhase.SPAWN: # Handle unit spawns
			for spawn in spawn_freqs:
				if turn_count % spawn[1] != 0:
					continue
					
				var spawn_y = choose_enemy_spawn_pos()
				if spawn_y == null:
					continue
					
				var unit_res = load("res://Scenes/Enemies/" + spawn[0] + ".tscn")
				var unit_instance = unit_res.instantiate()
				get_tree().root.add_child.call_deferred(unit_instance)
				unit_instance.init(Vector2i(grid_size.x - 1, spawn_y))
				unit_instance.attack_form = rng.randi() % 3
			
			turn_phase = TurnPhase.CARD
		
		TurnPhase.CARD: # Handle player cards
			if turn_ended:
				turn_ended = false
				turn_phase = TurnPhase.BATTLE
			
		TurnPhase.BATTLE: # Handle battles
			for col in grid:
				for elem in col:
					if elem:
						elem._try_attack()
			
			turn_phase = TurnPhase.MOVE
		
		TurnPhase.MOVE: # Handle unit movements
			var furthest_friendly_col = 0
			for x in range(grid_size.x): # Move player units
				var col = grid_size.x - 1 - x
				for elem in grid[col]:
					if elem && !elem.enemy:
						if col > furthest_friendly_col:
							furthest_friendly_col = col
						elem._try_move(col < furthest_friendly_col)
			for x in range(grid_size.x): # Move enemy units
				var col = grid[x]
				for elem in col:
					if elem && elem.enemy:
						elem._try_move()
			
			turn_phase = TurnPhase.BASE
		
		TurnPhase.BASE: # Handle attacks to bases
			for elem in death_queue: # Remove dead units
				elem.queue_free()
				death_queue = []
			
			for elem in grid[grid_size.x - 1]:
				if elem && !elem.enemy:
					print(elem.health)
					enemy_base_health -= elem.health
					elem.queue_free()
			for elem in grid[0]:
				if elem && elem.enemy:
					player_base_health -= elem.health
					elem.queue_free()
			
			turn_count += 1
			turn_phase = TurnPhase.SPAWN

func choose_enemy_spawn_pos():
	# Find empty spawn tiles
	var potential_spawns = []
	for y in range(grid_size.y):
		if !grid[grid_size.x - 1][y]:
			potential_spawns.append(y)
	
	# Prioritize empty lanes
	var priority_spawns = []
	for y in potential_spawns:
		var lane_empty = true
		for x in range(grid_size.x):
			if grid[x][y] && grid[x][y] is Unit && grid[x][y].enemy:
				lane_empty = false
				break
		if lane_empty:
			priority_spawns.append(y)
	
	# Randomly choose spawn tile
	var spawns = priority_spawns if priority_spawns.size() > 0 else potential_spawns
	return spawns.pick_random()

var turn_ended = false
func process_turn():
	turn_ended = true
