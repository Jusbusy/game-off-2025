class_name Unit extends GridElement

@export var enemy : bool
@export var max_health : int = 2

var forward : Vector2i:
	get:
		return Vector2i(-1, 0) if enemy else Vector2i(1, 0)
		
var health: int:
	get:
		return health
	set(value):
		health = value
		if value <= 0 && !Global.death_queue.has(self):
			Global.death_queue.append(self)
		match(value):
			1:
				get_node("HealthBarSprite").texture = health_bar_1
			2:
				get_node("HealthBarSprite").texture = health_bar_2
			3:
				get_node("HealthBarSprite").texture = health_bar_3
			4:
				get_node("HealthBarSprite").texture = health_bar_4


enum AttackForm { ROCK, PAPER, SCISSORS }
var attack_form: AttackForm:
	get: 
		return attack_form
	set(value):
		attack_form = value
		match(value):
			AttackForm.ROCK:
				get_node("AttackIcon").texture = rock_icon
			AttackForm.PAPER:
				get_node("AttackIcon").texture = paper_icon
			AttackForm.SCISSORS:
				get_node("AttackIcon").texture = scissors_icon

enum State {ADVANCE, LANE_UP, LANE_DOWN}
var state = State.ADVANCE

const rock_icon = preload("res://Sprites/Attack Sprites/RockAttackIcon.png")
const paper_icon = preload("res://Sprites/Attack Sprites/PaperAttackIcon.png")
const scissors_icon = preload("res://Sprites/Attack Sprites/ScissorsAttackIcon.png")

const health_bar_1 = preload("res://Health Bar Sprites/HealthBar1.png")
const health_bar_2 = preload("res://Health Bar Sprites/HealthBar2.png")
const health_bar_3 = preload("res://Health Bar Sprites/HealthBar3.png")
const health_bar_4 = preload("res://Health Bar Sprites/HealthBar4.png")

func _ready():
	health = max_health

func _process(_delta):
	if !get_node("MainSprite").is_playing():
		get_node("MainSprite").play("idle")

func _try_attack():
	var elem = get_local(forward)
	if !elem || enemy == elem.enemy:
		return

	var enemy_attack_form = elem.attack_form
	if attack_form == AttackForm.ROCK && enemy_attack_form == AttackForm.SCISSORS || \
	   attack_form == AttackForm.PAPER && enemy_attack_form == AttackForm.ROCK || \
	   attack_form == AttackForm.SCISSORS && enemy_attack_form == AttackForm.PAPER:
		elem.health -= 2
	else:
		elem.health -= 1
	
	play_blocking_animation("attack")
	
func _try_move_turn(allow_battle_move, allow_auto_move = true):
	if health <= 0:
		return false
	var elem = get_local(forward)
	if (!elem && allow_auto_move) || (elem && elem.health <= 0 && enemy != elem.enemy && allow_battle_move):
		move(grid_pos + forward)
		return true
	return false

func move(target_pos : Vector2i):
	if !Rect2i(Vector2i.ZERO, Global.grid_size).has_point(target_pos):
		print("OOB Move Occurred")
		return
	
	play_move_animation(grid_pos, target_pos)
	Global.grid[grid_pos.x][grid_pos.y] = null
	Global.grid[target_pos.x][target_pos.y] = self
	grid_pos = target_pos

func change_attack():
	match attack_form:
		AttackForm.ROCK:
			attack_form = AttackForm.PAPER
		AttackForm.PAPER:
			attack_form = AttackForm.SCISSORS
		AttackForm.SCISSORS:
			attack_form = AttackForm.ROCK
			
func play_blocking_animation(anim_name: String, callback = null):
	Global.blocking_animations += 1
	get_node("MainSprite").play(anim_name)
	
	get_node("MainSprite").animation_finished.connect(
		func(): 
			Global.blocking_animations -= 1
			if callback: callback.call(),
		CONNECT_ONE_SHOT
	)

const move_time = 0.25

func play_move_animation(start_pos: Vector2i, target_pos: Vector2i):
	Global.blocking_animations += 1
	
	var curr_pos = Vector2(start_pos)
	var t = 0
	while (t < move_time):
		await get_tree().process_frame
		t += get_process_delta_time()
		var t_norm = t / move_time
		var lerp_pos = curr_pos.lerp(target_pos, t_norm * t_norm * t_norm)
		position = Vector2(Global.grid_origin) + Vector2(Global.grid_spacing) * lerp_pos
	
	position = Global.grid_origin + Global.grid_spacing * target_pos
	Global.blocking_animations -= 1
