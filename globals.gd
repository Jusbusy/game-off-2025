extends Node

var rng = RandomNumberGenerator.new()

const card_button = preload("res://UI/CardButton.tscn")

var game_ui:
	get:
		var node = get_tree().root.get_node("Game/CanvasLayer/Desktop/GameUI")
		if !node:
			print("Attempted to access GameUI, but could not find it")
		return node

var storage_container:
	get:
		var node = get_tree().root.get_node("Game/CanvasLayer/Desktop/StorageUI/ScrollContainer/GridContainer")
		if !node:
			print("Attempted to access StorageContainer, but could not find it")
		return node

var card_button_container:
	get:
		var node = game_ui.get_node("CardContainer")
		if !node:
			print("Attempted to access CardButtonContainer, but could not find it")
		return node

const grid_spacing = Vector2i(72, 72)
const grid_origin = Vector2i(46, 120)
#var grid_origin: Vector2i:
	#get:
		#return Vector2i(game_ui.global_position) + grid_offset
const grid_size = Vector2i(5, 5)

var grid = []

enum TurnPhase { SPAWN, CARD, BATTLE, MOVE, BASE }
var turn_phase
var blocking_animations = 0
var turn_count = 0
var turn_ended = false

var spawn_freqs = [["e_melee", 2], ["e_melee", 2], ["e_tank", 2]]

var player_base_health: int:
	get:
		return player_base_health
	set(value):
		player_base_health = value
		game_ui.get_node("Back/ServerProgress").value = value

var enemy_base_health: int:
	get:
		return enemy_base_health
	set(value):
		enemy_base_health = value
		game_ui.get_node("Back/ClientProgress").value = value

const turn_ap = 4
var player_ap: int:
	get:
		return player_ap
	set(value):
		player_ap = value
		game_ui.get_node("Back/BandProgress").value = value
		#ap_label.text = "AP: %d" % value

var death_queue = []

const hand_size = 3

var starter_deck = [
	CardMove.new(), CardMove.new(),
	CardUnitMelee.new(), CardUnitMelee.new(),
	CardHeal.new(), CardHeal.new(), CardHeal.new(), CardHeal.new()
]
var deck = []
var draw = []
var hand = []
var selected_card = -1

func _ready():
	for card in starter_deck:
		call_deferred("add_card_to_deck", card)
	
	game_ui.get_node("Back/EndTurnBtn").pressed.connect(
		func(): 
			if turn_phase == TurnPhase.CARD:
				turn_ended = true
	)
	
	for i in range(grid_size.x):
		grid.append([])
		grid[i].resize(grid_size.y)
	player_base_health = 10
	enemy_base_health = 10
	player_ap = turn_ap
	
	var unit_instance = load("res://Units/Friendlies/f_melee.tscn").instantiate()
	game_ui.add_child.call_deferred(unit_instance)
	unit_instance.init(Vector2i(0, 2))
	unit_instance.attack_form = rng.randi() % 3
	
	turn_phase = TurnPhase.SPAWN

func _process(_delta):
	if blocking_animations != 0:
		return
	
	match(turn_phase):
		TurnPhase.SPAWN: # Handle unit spawns
			for spawn in spawn_freqs:
				if turn_count % spawn[1] != 0:
					continue
					
				var spawn_y = choose_enemy_spawn_pos()
				if spawn_y == null:
					continue
					
				var unit_res = load("res://Units/Enemies/" + spawn[0] + ".tscn")
				var unit_instance = unit_res.instantiate()
				game_ui.add_child.call_deferred(unit_instance)
				unit_instance.init(Vector2i(grid_size.x - 1, spawn_y))
				unit_instance.attack_form = rng.randi() % 3
			
			draw_cards()
			turn_phase = TurnPhase.CARD
		
		TurnPhase.CARD: # Handle player cards
			if !Input.is_action_just_pressed("end_turn") && !turn_ended:
				if selected_card == -1:
					if Input.is_action_just_pressed("select_card_1") && hand.size() >= 1:
						selected_card = 0
					elif Input.is_action_just_pressed("select_card_2") && hand.size() >= 2:
						selected_card = 1
					elif Input.is_action_just_pressed("select_card_3") && hand.size() >= 3:
						selected_card = 2
					else:
						if Input.is_action_just_pressed("select"):
							var select = Global.get_mouse_tile()
							if select == null:
								return
							var elem = grid[select.x][select.y]
							if elem && !elem.enemy && use_ap(1):
								elem.change_attack()
						return
				
				var card = deck[hand[selected_card]]
				if card.cost > player_ap:
					return
				
				if Input.is_action_just_pressed("cancel"):
					card.reset_selection()
					selected_card = -1
				
				if !card.update():
					discard_card(selected_card)
				
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
						elem._try_move_turn(col < furthest_friendly_col)
			for x in range(grid_size.x): # Move enemy units
				var col = grid[x]
				for elem in col:
					if elem && elem.enemy:
						elem._try_move_turn()
			
			turn_phase = TurnPhase.BASE
		
		TurnPhase.BASE: # Handle attacks to bases
			for elem in death_queue: # Remove dead units
				elem.queue_free()
				death_queue = []
			
			for elem in grid[grid_size.x - 1]:
				if elem && !elem.enemy:
					elem.play_blocking_animation("attack", 
						func():
							enemy_base_health -= elem.health
							elem.queue_free()
					)
			for elem in grid[0]:
				if elem && elem.enemy:
					elem.play_blocking_animation("attack", 
						func():
							player_base_health -= elem.health
							elem.queue_free()
					)
			
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

func draw_cards():
	while(hand.size() < hand_size && hand.size() != deck.size()):
		if draw.size() == 0:
			shuffle_draw()
		var drawn_card = draw.pop_back()
		storage_container.get_child(drawn_card).disabled = true
		hand.append(drawn_card)
		
		var card_button_instance = card_button.instantiate()
		card_button_container.add_child.call_deferred(card_button_instance)
		card_button_instance.icon = deck[drawn_card].icon
		card_button_instance.get_node("CardName").text = deck[drawn_card].name
		card_button_instance.gui_input.connect(
			func(event): 
				if event is InputEventMouseButton and event.pressed:
					match event.button_index:
						MOUSE_BUTTON_LEFT:
							selected_card = card_button_instance.get_index()
						MOUSE_BUTTON_RIGHT:
							discard_card(card_button_instance.get_index())
				
		)
		
func discard_card(hand_id):
	hand.remove_at(hand_id)
	card_button_container.get_child(hand_id).queue_free()
	selected_card = -1

func shuffle_draw():
	draw = range(deck.size())
	draw = draw.filter(func(x): return !hand.has(x))
	draw.shuffle()
	for i in range(deck.size()):
		if !hand.has(i):
			storage_container.get_child(i).disabled = false

func add_card_to_deck(card: Card):
	deck.append(card)
	deck.sort_custom(func(a, b): return a.name < b.name)
	
	var card_button_instance = card_button.instantiate()
	storage_container.add_child(card_button_instance)
	
	var card_buttons = storage_container.get_children()
	for i in range(deck.size()):
		card_buttons[i].icon = deck[i].icon
		card_buttons[i].get_node("CardName").text = deck[i].name

func remove_card_from_deck(card_id: int):
	deck.remove_at(card_id)
	storage_container.get_child(card_id).queue_free()
	pass

func get_mouse_tile():
	var mouse_pos = get_viewport().get_mouse_position()
	var mouse_tile = Vector2i((mouse_pos - (Vector2(grid_origin) + game_ui.global_position)) / Vector2(grid_spacing) + Vector2(0.5, 0.5))
	
	if Rect2i(Vector2i.ZERO, grid_size).has_point(mouse_tile):
		return mouse_tile
	return null
	
func use_ap(amt: int):
	if player_ap < amt:
		return false
	player_ap -= amt
	return true
