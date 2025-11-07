extends CharacterBody2D

@export var speed = 1.2
@export var unit : PackedScene

var interact_unit = null

func _process(_delta):
	if Input.is_action_just_pressed("order_summon"):
		var curr_lane_pos = snappedf(position.y - Global.top_lane_pos, Global.lane_spacing) + Global.top_lane_pos
		var unit_instance = unit.instantiate()
		get_tree().root.add_child(unit_instance)
		unit_instance.is_enemy = false
		unit_instance.target_lane_pos = curr_lane_pos
		unit_instance.position = Vector2(10, curr_lane_pos)
	
	if Input.is_action_just_pressed("order_attack_rock") && interact_unit:
		interact_unit.attack_form = Unit.AttackForm.ROCK
	if Input.is_action_just_pressed("order_attack_paper") && interact_unit:
		interact_unit.attack_form = Unit.AttackForm.PAPER
	if Input.is_action_just_pressed("order_attack_scissors") && interact_unit:
		interact_unit.attack_form = Unit.AttackForm.SCISSORS
	
	if Input.is_action_just_pressed("order_lane_up") && interact_unit:
		interact_unit.state = Unit.State.LANE_UP
	if Input.is_action_just_pressed("order_lane_down") && interact_unit:
		interact_unit.state = Unit.State.LANE_DOWN

func _physics_process(_delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	move_and_slide()


func _on_interact_area_entered(area: Area2D) -> void:
	var unit = area.get_owner()
	if !unit.is_enemy:
		interact_unit = unit


func _on_interact_area_exited(area: Area2D) -> void:
	var unit = area.get_owner()
	if interact_unit == unit:
		interact_unit = null
