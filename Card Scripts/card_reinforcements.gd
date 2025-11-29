class_name CardReinforcements extends Card

func get_icon():
	return load("res://UI/Icons/Card_Divide.png")
func get_name():
	return "Reinforcements"

func get_cost():
	return 1
func get_selection_rules():
	return [
		{"flags" : [SLCT_FRIEND]}, 
	]

func do_effect():
	var unit_pos = _curr_selections[0]
	
	var unit = Global.grid[unit_pos.x][unit_pos.y]
	
	if Global.grid[0][unit_pos.y]:
		return
	
	var new_unit_instance = unit.duplicate()
	Global.get_tree().root.add_child(new_unit_instance)
	new_unit_instance.init(Vector2i(0, unit_pos.y))
	new_unit_instance.attack_form = unit.attack_form
	new_unit_instance.health = unit.max_health
