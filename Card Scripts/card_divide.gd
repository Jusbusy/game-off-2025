class_name CardDivide extends Card

func get_icon():
	return load("res://UI/Icons/Card_Divide.png")
func get_name():
	return "Divide"

func get_cost():
	return 1
func get_selection_rules():
	return [
		{"flags" : [SLCT_FRIEND]}, 
		{"adjacents" : [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)], "flags" : [SLCT_EMPTY]}
	]

func do_effect():
	var unit_pos = _curr_selections[0]
	var div_pos = _curr_selections[1]
	
	var unit = Global.grid[unit_pos.x][unit_pos.y]
	var unit_health = unit.health
	if unit_health <= 1:
		return
	
	var new_unit_instance = unit.duplicate()
	Global.game_ui.add_child(new_unit_instance)
	new_unit_instance.init(div_pos)
	
	unit.health = unit_health / 2 + unit_health % 2
	new_unit_instance.health = unit_health / 2
