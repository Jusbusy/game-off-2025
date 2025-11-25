extends Node

var rng = RandomNumberGenerator.new()

const unit = preload("res://Scenes/Friendlies/f_melee.tscn")
const card_button = preload("res://UI/CardButton.tscn")

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
		
var card_button_container:
	get:
		var node = get_tree().root.get_node("Game/CanvasLayer/GameUI/Panel/Panel/CardButtonContainer")
		if !node:
			print("Attempted to access CardButtonContainer, but could not find it")
		return node

const grid_spacing = Vector2i(210, 70)
const grid_origin = Vector2i(88, 88)
const grid_size = Vector2i(5, 5)

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

const turn_ap = 3
var player_ap: int:
	get:
		return player_ap
	set(value):
		player_ap = value
		ap_label.text = "AP: %d" % value

var death_queue = []

const hand_size = 3

var deck = [CardUnitMelee.new(), CardHeal.new(), CardMove.new(), CardDivide.new()]
var draw = []
var hand = []
var selected_card = -1

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
			
			draw_cards()
			turn_phase = TurnPhase.CARD
		
		TurnPhase.CARD: # Handle player cards
			if !turn_ended:
				if selected_card == -1:
					if Input.is_action_just_pressed("select_card_1") && hand.size() >= 1:
						selected_card = 0
					elif Input.is_action_just_pressed("select_card_2") && hand.size() >= 2:
						selected_card = 1
					elif Input.is_action_just_pressed("select_card_3") && hand.size() >= 3:
						selected_card = 2
					else:
						return
				
				var card = deck[hand[selected_card]]
				if card.cost > player_ap:
					return
				
				if Input.is_action_just_pressed("cancel"):
					card.reset_selection()
					selected_card = -1
				
				if !card.update():
					hand.remove_at(selected_card)
					card_button_container.get_child(selected_card).queue_free()
					selected_card = -1
				
				return
			
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
			
			player_ap = turn_ap
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

func draw_cards():
	while(hand.size() < hand_size && hand.size() != deck.size()):
		if draw.size() == 0:
			draw = range(deck.size())
			draw = draw.filter(func(x): return !hand.has(x))
			draw.shuffle()
		var drawn_card = draw.pop_back()
		hand.append(drawn_card)
		
		var card_button_instance = card_button.instantiate()
		card_button_container.add_child.call_deferred(card_button_instance)
		card_button_instance.icon = deck[drawn_card].icon
		card_button_instance.get_node("NameLabel").text = deck[drawn_card].name
		card_button_instance.pressed.connect(func(): selected_card = card_button_instance.get_index())

func get_mouse_tile():
	var mouse_pos = get_viewport().get_mouse_position()
	return Vector2i((mouse_pos - Vector2(grid_origin)) / Vector2(grid_spacing) + Vector2(0.5, 0.5))
