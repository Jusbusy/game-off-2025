class_name CardPeasants extends Card

func get_icon():
	return load("res://UI/Icons/Card_Divide.png")
func get_name():
	return "Peasants"
func get_desc():
	return r"""Select a friendly unit.
	A 1 health unit will be spawned in every empty space of the column."""

func get_cost():
	return 2
func get_selection_rules():
	return [
		{"flags" : [SLCT_FRIEND]}, 
	]

func do_effect():
	var unit_pos = _curr_selections[0]
	
	var new_unit = load("res://Units/Friendlies/f_peasant.tscn")
	
	for y in range(Global.grid_size.y):
		var elem = Global.grid[unit_pos.x][y]
		if !elem:
			var new_unit_instance = new_unit.instantiate()
			Global.game_ui.add_child(new_unit_instance)
			new_unit_instance.init(Vector2i(unit_pos.x, y))
			new_unit_instance.attack_form = Global.rng.randi() % 3
