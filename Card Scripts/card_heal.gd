class_name CardHeal extends Card

func get_icon():
	return load("res://UI/Icons/Card_Heal.png")
func get_name():
	return "Heal"
func get_desc():
	return r"""Select a friendly unit.
	Unit will be healed for 1 health."""

func get_cost():
	return 1
func get_selection_rules():
	return [
		{"flags" : [SLCT_FRIEND]}, 
	]

func do_effect():
	var unit_pos = _curr_selections[0]
	
	var unit = Global.grid[unit_pos.x][unit_pos.y]
	unit.health += 1
