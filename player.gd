extends GridElement

func _ready():
	init_position(Vector2i(0, 0))

func _process(_delta):
	if Input.is_action_just_pressed("end_turn"):
		Global.process_turn()
	
	if Input.is_action_just_pressed("move_left"):
		move(grid_pos + Vector2i(-1, 0))
	if Input.is_action_just_pressed("move_right"):
		move(grid_pos + Vector2i(1, 0))
	if Input.is_action_just_pressed("move_up"):
		move(grid_pos + Vector2i(0, -1))
	if Input.is_action_just_pressed("move_down"):
		move(grid_pos + Vector2i(0, 1))
	
	if Input.is_action_just_pressed("order_summon"):
		var unit_instance = Global.unit.instantiate()
		get_tree().root.add_child(unit_instance)
		unit_instance.is_enemy = false
		unit_instance.init_position(Vector2i(0, grid_pos.y))
	
	if Input.is_action_just_pressed("order_attack_rock"):
		call_on_interactable(func(i_unit) : i_unit.attack_form = Unit.AttackForm.ROCK)
	if Input.is_action_just_pressed("order_attack_paper"):
		call_on_interactable(func(i_unit) : i_unit.attack_form = Unit.AttackForm.PAPER)
	if Input.is_action_just_pressed("order_attack_scissors"):
		call_on_interactable(func(i_unit) : i_unit.attack_form = Unit.AttackForm.SCISSORS)
	
	if Input.is_action_just_pressed("order_lane_up"):
		call_on_interactable(func(i_unit) : i_unit.state = Unit.State.LANE_UP)
	if Input.is_action_just_pressed("order_lane_down"):
		call_on_interactable(func(i_unit) : i_unit.state = Unit.State.LANE_DOWN)

func call_on_interactable(_func):
	var pos = Vector2i(0, 1)
	for i in range(4):
		var elem = get_local(pos)
		if elem && !elem.is_enemy:
			_func.call(elem)
		pos = Vector2i(-pos.y, pos.x) # rotate pos 90deg CW
