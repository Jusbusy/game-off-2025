class_name CardMassHeal extends Card

func get_icon():
	return load("res://UI/Icons/Card_Divide.png")
func get_name():
	return "Mass Heal"

func get_cost():
	return 2
func get_selection_rules():
	return [
		{"flags" : [SLCT_FRIEND]}, 
	]

func do_effect():
	var unit_pos = _curr_selections[0]
	
	#var new_unit = load("res://Units/Friendlies/f_peasant.tscn")
	
	for y in range(Global.grid_size.y):
		var elem = Global.grid[unit_pos.x][y]
		if elem && !elem.enemy:
			elem.health += 1
