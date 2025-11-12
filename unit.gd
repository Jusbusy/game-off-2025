class_name Unit extends GridElement

@export var friendly_sprite : Texture2D
@export var enemy_sprite : Texture2D

var is_enemy: bool:
	get:
		return is_enemy
	set(value):
		is_enemy = value
		if value:
			get_node("MainSprite").texture = enemy_sprite
		else:
			get_node("MainSprite").texture = friendly_sprite
		


var max_health = 4
var health: int:
	get:
		return health
	set(value):
		health = value
		if value == 0:
			self.queue_free()
			return
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

func _process_turn():
	if state == State.ADVANCE:
		if is_enemy && grid_pos.x == 0:
			print("Enemy scored")
			self.queue_free()
			return
		if !is_enemy && grid_pos.x == Global.grid_size.x - 1:
			print("Player scored")
			self.queue_free()
			return
		
		var mov_dir = Vector2i(-1 if is_enemy else 1, 0)
		var elem = get_local(mov_dir)
		
		if !elem:
			move(grid_pos + mov_dir)
			return
		if is_enemy != elem.is_enemy: # Attacking
			var enemy_attack_form = elem.attack_form
			if attack_form == enemy_attack_form:
				elem.health -= 1
				return
			if attack_form == AttackForm.ROCK && enemy_attack_form == AttackForm.SCISSORS || \
			   attack_form == AttackForm.PAPER && enemy_attack_form == AttackForm.ROCK || \
			   attack_form == AttackForm.SCISSORS && enemy_attack_form == AttackForm.PAPER:
				elem.health -= 1
			return
			
	elif state == State.LANE_UP:
		var elem = get_local(Vector2i(0, -1))
		if !elem:
			move(grid_pos + Vector2i(0, -1))
		state = State.ADVANCE
	elif state == State.LANE_DOWN:
		var elem = get_local(Vector2i(0, 1))
		if !elem:
			move(grid_pos + Vector2i(0, 1))
		state = State.ADVANCE

#func _process(_delta):
	#match(state):
		#State.ADVANCE:
			#mov_dir = Vector2(1, 0) * (-1 if is_enemy else 1)
			#mov_speed = speed
		#State.LANE_UP:
			#if target_lane_pos < position.y:
				#state = State.MOVE_LANE
				#return
			#if target_lane_pos <= Global.top_lane_pos:
				#state = State.ADVANCE
				#return
			#target_lane_pos -= Global.lane_spacing
			#state = State.MOVE_LANE
		#State.LANE_DOWN:
			#if target_lane_pos > position.y:
				#state = State.MOVE_LANE
				#return
			#if target_lane_pos >= Global.top_lane_pos + Global.lane_spacing * (Global.lane_count - 1):
				#state = State.ADVANCE
				#return
			#target_lane_pos += Global.lane_spacing
			#state = State.MOVE_LANE
		#State.MOVE_LANE:
			#if abs(position.y - target_lane_pos) <= mov_speed * _delta:
				#position.y = target_lane_pos
				#state = State.ADVANCE
				#return
			#mov_dir = Vector2(0, target_lane_pos - position.y).normalized()
			#mov_speed = speed
			#
#
#func _physics_process(_delta):
	#velocity = mov_dir * mov_speed
	#move_and_slide()
#
#func _on_collision_area_entered(area: Area2D) -> void:
	#var collided_unit = area.get_owner()
	#if !(collided_unit is Unit):
		#return
	#
	#if is_enemy != collided_unit.is_enemy:
#
		#var enemy_attack_form = collided_unit.attack_form
		#
		#if attack_form == enemy_attack_form:
			#return
		#
		#if attack_form == AttackForm.ROCK && enemy_attack_form == AttackForm.SCISSORS || \
		   #attack_form == AttackForm.PAPER && enemy_attack_form == AttackForm.ROCK || \
		   #attack_form == AttackForm.SCISSORS && enemy_attack_form == AttackForm.PAPER:
			#collided_unit.queue_free()
