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

const rock_icon = preload("res://Attack Sprites/RockAttackIcon.png")
const paper_icon = preload("res://Attack Sprites/PaperAttackIcon.png")
const scissors_icon = preload("res://Attack Sprites/ScissorsAttackIcon.png")

const health_bar_1 = preload("res://Health Bar Sprites/HealthBar1.png")
const health_bar_2 = preload("res://Health Bar Sprites/HealthBar2.png")
const health_bar_3 = preload("res://Health Bar Sprites/HealthBar3.png")
const health_bar_4 = preload("res://Health Bar Sprites/HealthBar4.png")

func _ready():
	health = max_health

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
	
func _try_move(allow_auto_move = true):
	var elem = get_local(forward)
	if (!elem && allow_auto_move) || (elem && elem.health == 0 && enemy != elem.enemy):
		move(grid_pos + forward)
