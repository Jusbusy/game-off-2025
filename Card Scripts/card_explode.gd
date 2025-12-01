class_name CardExplode extends Card

func get_icon():
	return load("res://UI/Icons/Card_Divide.png")
func get_name():
	return "Explode"
func get_desc():
	return r"""Select a friendly unit.
	Unit will be killed and deal damage equal to its health to all enemies in the lane."""

func get_cost():
	return 2
func get_selection_rules():
	return [
		{"flags" : [SLCT_FRIEND]}
	]

func do_effect():
	var unit_pos = _curr_selections[0]
	
	var unit = Global.grid[unit_pos.x][unit_pos.y]
	var unit_health = unit.health
	for x in range(Global.grid_size.x):
		var elem = Global.grid[x][unit_pos.y]
		if elem && elem.enemy:
			elem.health -= unit_health
	unit.health -= unit_health
