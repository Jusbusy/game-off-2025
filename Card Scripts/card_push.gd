class_name CardPush extends Card

func get_icon():
	return load("res://UI/Icons/Card_Move.png")
func get_name():
	return "Push"

func get_cost():
	return 1
func get_selection_rules():
	return [
		{"flags" : [SLCT_FRIEND]}, 
		{"adjacents" : [Vector2i(1, 0)], "flags" : [SLCT_ENEMY]}
	]

func do_effect():
	#var unit_pos = _curr_selections[0]
	var enemy_pos = _curr_selections[1]
	
	#var unit = Global.grid[unit_pos.x][unit_pos.y]
	var enemy = Global.grid[enemy_pos.x][enemy_pos.y]
	var push_pos = enemy_pos + Vector2i(1, 0)
	if Rect2i(Vector2i.ZERO, Global.grid_size).has_point(push_pos) && Global.grid[enemy_pos.x + 1][enemy_pos.y] == null:
		enemy.move(push_pos)
	else:
		enemy.health -= 1
	
	#unit.move(enemy_pos)
	#enemy.move(unit_pos)
	#Global.grid[enemy_pos.x][enemy_pos.y] = unit
