class_name CardSwap extends Card

func get_icon():
	return load("res://UI/Icons/Card_Move.png")
func get_name():
	return "Swap"

func get_cost():
	return 1
func get_selection_rules():
	return [
		{"flags" : [SLCT_FRIEND, SLCT_CAN_MOVE]}, 
		{"adjacents" : [Vector2i(1, 0)], "flags" : [SLCT_ENEMY]}
	]

func do_effect():
	var unit_pos = _curr_selections[0]
	var enemy_pos = _curr_selections[1]
	
	var unit = Global.grid[unit_pos.x][unit_pos.y]
	var enemy = Global.grid[enemy_pos.x][enemy_pos.y]
	unit.move(enemy_pos)
	enemy.move(unit_pos)
	Global.grid[enemy_pos.x][enemy_pos.y] = unit
	unit.health -= 1
