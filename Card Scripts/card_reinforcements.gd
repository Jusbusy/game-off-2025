class_name CardReinforcements extends Card

func get_icon():
	return load("res://UI/Icons/Card_Divide.png")
func get_name():
	return "Reinforcements"
func get_desc():
	return r"""Select a friendly unit and a tile the leftmost column.
	A copy of the selected unit will be spawned at full health on the selected tile."""

func get_cost():
	return 1
func get_selection_rules():
	return [
		{"flags" : [SLCT_FRIEND]}, 
		{"flags" : [SLCT_FRIEND_SPAWN, SLCT_EMPTY]}
	]

func do_effect():
	var unit_pos = _curr_selections[0]
	var target_pos = _curr_selections[1]
	
	var unit = Global.grid[unit_pos.x][unit_pos.y]
	
	#if Global.grid[0][unit_pos.y]:
		#return
	
	var new_unit_instance = unit.duplicate()
	Global.game_ui.add_child(new_unit_instance)
	new_unit_instance.init(target_pos)
	new_unit_instance.attack_form = unit.attack_form
	new_unit_instance.health = unit.max_health
