extends Node

var rng = RandomNumberGenerator.new()

const card_button = preload("res://UI/CardButton.tscn")
const music_fade_rate = 1

var music:
	get:
		var node = get_tree().root.get_node("Game/Music")
		if !node:
			print("Attempted to access Music, but could not find it")
		return node

var audio_mouse:
	get:
		var node = get_tree().root.get_node("Game/AudioMouse")
		if !node:
			print("Attempted to access AudioMouse, but could not find it")
		return node

var email_ui:
	get:
		var node = get_tree().root.get_node("Game/CanvasLayer/Desktop/EmailUI")
		if !node:
			print("Attempted to access EmailUI, but could not find it")
		return node

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

var highlight:
	get:
		var node = get_tree().root.get_node("Game/Highlight")
		if !node:
			print("Attempted to access HighlightRect, but could not find it")
		return node
const default_highlight_color = Color(0x9175fc78)
const card_select_highlight_color = Color(0x00a89078)
const card_invalid_highlight_color = Color(0xf03e9c78)


const grid_spacing = Vector2i(72, 72)
const grid_origin = Vector2i(46, 120)
#var grid_origin: Vector2i:
	#get:
		#return Vector2i(game_ui.global_position) + grid_offset
const grid_size = Vector2i(5, 5)

var grid = []

var levels = [
	{
		"Icon" : "res://UI/Icons/Card_Divide.png",
		"Name" : "Level1.exe",
		"Freqs" : [["e_melee", 2], ["e_melee", 2], ["e_tank", 2]]
	},
	{
		"Icon" : "res://UI/Icons/Card_Divide.png",
		"Name" : "Level2.exe",
		"Freqs" : [["e_melee", 2], ["e_melee", 2], ["e_tank", 2]]
	}
]
var level_id = 0
var in_level = false
var level_over = false

#var spawn_freqs = [["e_melee", 2], ["e_melee", 2], ["e_tank", 2]]

enum TurnPhase { SPAWN, CARD, BATTLE, MOVE, BASE }
var turn_phase
var blocking_animations = 0
var turn_count = 0
var turn_ended = false

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
	CardHeal.new(), CardHeal.new(), CardHeal.new(), CardHeal.new(),
	CardUnitShield.new(), CardSwap.new()
]
var deck = []
var draw = []
var hand = []
var selected_card: int = -1:
	get:
		return selected_card
	set(value):
		if selected_card != -1:
			deck[hand[selected_card]].reset_selection()
			card_button_container.get_child(selected_card).disabled = false
		selected_card = value
		if selected_card != -1:
			card_button_container.get_child(selected_card).disabled = true

func _ready():
	for card in starter_deck:
		call_deferred("add_card_to_deck", card)
	
	game_ui.get_node("Back/EndTurnBtn").pressed.connect(
		func(): 
			audio_mouse.play()
			if level_over:
				end_level()
				return
			if turn_phase == TurnPhase.CARD:
				turn_ended = true
	)
	
	for i in range(grid_size.x):
		grid.append([])
		grid[i].resize(grid_size.y)

func _process(_delta):
	var arp_volume_dir = 1 if in_level else -1
	var arp_vol = db_to_linear(music.stream.get_sync_stream_volume(1))
	arp_vol = clamp(arp_vol + arp_volume_dir * _delta * music_fade_rate, 0, 1)
	music.stream.set_sync_stream_volume(1, linear_to_db(arp_vol))
	
	highlight.visible = false
	
	if Input.is_action_just_pressed("debug"):
		level_over = true
	
	if blocking_animations != 0 || !in_level:
		return
	
	if level_over:
		if Input.is_action_just_pressed("end_turn"):
			end_level()
		return
	
	match(turn_phase):
		TurnPhase.SPAWN: # Handle unit spawns
			if turn_count == 0:
				var unit_instance = load("res://Units/Friendlies/f_melee.tscn").instantiate()
				game_ui.add_child.call_deferred(unit_instance)
				unit_instance.init(Vector2i(0, 2))
				unit_instance.attack_form = rng.randi() % 3
			
			for spawn in levels[level_id]["Freqs"]:
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
			var mouse_tile = get_mouse_tile()
			if mouse_tile != null:
				highlight.visible = true
				highlight.get_node("ColorRect").color = default_highlight_color
				var highlight_pos = Vector2(mouse_tile)
				highlight_pos *= Vector2(grid_spacing)
				highlight_pos += Vector2(grid_origin) + game_ui.global_position
				highlight.position = highlight_pos
			
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
							audio_mouse.play()
							var elem = grid[select.x][select.y]
							if elem && !elem.enemy && use_ap(1):
								elem.change_attack()
						return
				
				var card = deck[hand[selected_card]]
				if mouse_tile != null && card.check_selection(mouse_tile):
					highlight.get_node("ColorRect").color = card_select_highlight_color
				else:
					highlight.get_node("ColorRect").color = card_invalid_highlight_color
				
				if Input.is_action_just_pressed("cancel"):
					selected_card = -1
				
				if card.cost > player_ap:
					return
				
				if !card.update():
					discard_card(selected_card)
				
				return
			
			selected_card = -1
			turn_ended = false
			turn_phase = TurnPhase.BATTLE
			
		TurnPhase.BATTLE: # Handle battles
			for col in grid:
				for elem in col:
					if elem:
						elem._try_attack()
			
			turn_phase = TurnPhase.MOVE
		
		TurnPhase.MOVE: # Handle unit movements
			var moved_units = {}
			for col in grid:
				for elem in col:
					if elem:
						if elem._try_move_turn(true, false):
							moved_units[elem] = true
			
			var furthest_friendly_col = 0
			for x in range(grid_size.x): # Move player units
				var col = grid_size.x - 1 - x
				for elem in grid[col]:
					if elem && !elem.enemy:
						if col > furthest_friendly_col:
							furthest_friendly_col = col
						if !moved_units.has(elem):
							elem._try_move_turn(false, col < furthest_friendly_col)
			for x in range(grid_size.x): # Move enemy units
				var col = grid[x]
				for elem in col:
					if elem && !moved_units.has(elem) && elem.enemy:
						elem._try_move_turn(false)
			
			turn_phase = TurnPhase.BASE
		
		TurnPhase.BASE: # Handle attacks to bases
			for elem in death_queue: # Remove dead units
				elem.kill()
				death_queue = []
			
			for elem in grid[grid_size.x - 1]:
				if elem && !elem.enemy:
					elem.get_node("AudioAttack").play()
					elem.play_blocking_animation("attack", 
						func():
							get_tree().root.get_node("Game/AudioBaseHit").play()
							enemy_base_health -= elem.health
							if enemy_base_health <= 0:
								level_over = true
							elem.kill()
					)
			for elem in grid[0]:
				if elem && elem.enemy:
					elem.get_node("AudioAttack").play()
					elem.play_blocking_animation("attack", 
						func():
							get_tree().root.get_node("Game/AudioBaseHit").play()
							player_base_health -= elem.health
							elem.kill()
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
		card_button_instance.get_node("APLabel").text = "%d Kb" % deck[drawn_card].cost
		card_button_instance.tooltip_text = deck[drawn_card].desc
		card_button_instance.gui_input.connect(
			func(event): 
				if event is InputEventMouseButton and event.pressed:
					audio_mouse.play()
					match event.button_index:
						MOUSE_BUTTON_LEFT:
							selected_card = card_button_instance.get_index()
						MOUSE_BUTTON_RIGHT:
							discard_card(card_button_instance.get_index())
				
		)
		
func discard_card(hand_id):
	selected_card = -1
	hand.remove_at(hand_id)
	card_button_container.get_child(hand_id).queue_free()

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
		card_buttons[i].get_node("APLabel").text = "%d Kb" % deck[i].cost
		card_buttons[i].tooltip_text = deck[i].desc
		card_buttons[i].pressed.connect(
			email_ui.try_deck_discard.bind(i)
		)

func remove_card_from_deck(card_id: int):
	deck.remove_at(card_id)
	storage_container.get_child(card_id).queue_free()
	pass

func get_mouse_tile():
	var mouse_pos = get_viewport().get_mouse_position()
	var mouse_pos_norm = (mouse_pos - (Vector2(grid_origin) + game_ui.global_position)) / Vector2(grid_spacing) + Vector2(0.5, 0.5)
	var mouse_tile = Vector2i(mouse_pos_norm)
	
	if Rect2i(Vector2i.ZERO, grid_size).has_point(mouse_tile) && mouse_pos_norm.x >= 0 && mouse_pos_norm.y >= 0:
		return mouse_tile
	return null
	
func use_ap(amt: int):
	if player_ap < amt:
		return false
	player_ap -= amt
	return true
	
func start_level(id):
	#music.stream.set_sync_stream_volume(1, 0)
	if id == 0:
		music.stream.set_sync_stream_volume(1, 0)
		music.play()
	level_id = id
	turn_phase = TurnPhase.SPAWN
	in_level = true
	level_over = false
	turn_count = 0
	player_base_health = 10
	enemy_base_health = 10
	player_ap = turn_ap
	game_ui.visible = true

func end_level():
	#music.stream.set_sync_stream_volume(1, -60)
	in_level = false
	for col in grid:
		for elem in col:
			if elem:
				elem.queue_free() 
	hand = []
	for button in card_button_container.get_children():
		button.queue_free()
	shuffle_draw()
	email_ui.post_next_email()
	game_ui.visible = false

var card_list = [
	[CardMove, 3],
	[CardUnitMelee, 3],
	[CardHeal, 3],
	[CardDivide, 2]
]

func gen_card():
	var total_weight = 0
	for item in card_list:
		total_weight += item[1]
	var r = rng.randi() % total_weight
	for item in card_list:
		r -= item[1]
		if r < 0:
			return item[0].new()
	return null
