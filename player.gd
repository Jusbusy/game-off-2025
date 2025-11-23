extends GridElement

func _ready():
	init(Vector2i(0, 0), true)

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
		if Global.grid[0][grid_pos.y]:
			print("Summon position is occupied")
		else:
			var unit_instance = Global.unit.instantiate()
			get_tree().root.add_child(unit_instance)
			unit_instance.init(Vector2i(0, grid_pos.y))

func call_on_interactable(_func):
	var pos = Vector2i(0, 1)
	for i in range(4):
		var elem = get_local(pos)
		if elem && !elem.is_enemy:
			_func.call(elem)
		pos = Vector2i(-pos.y, pos.x) # rotate pos 90deg CW
	
	var _elem = get_local(Vector2i.ZERO)
	if _elem && !_elem.is_enemy:
		_func.call(_elem)
