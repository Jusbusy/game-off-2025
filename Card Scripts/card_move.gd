class_name CardMove extends Card

func get_cost():
	return 1
func get_selection_rules():
	return [
		{"flags" : [SLCT_FRIEND]}, 
		{"adjacents" : [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)], "flags" : [SLCT_EMPTY]}
	]

func do_effect():
	var unit_pos = _curr_selections[0]
	var move_pos = _curr_selections[1]
	
	var unit = Global.grid[unit_pos.x][unit_pos.y]
	unit.move(move_pos)
