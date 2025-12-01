class_name CardUnitShield extends Card

func get_icon():
	return load("res://UI/Icons/Card_Melee.png")
func get_name():
	return "Spawn Shield"

func get_cost():
	return 1
func get_selection_rules():
	return [
		{"flags" : [SLCT_FRIEND]},
		{"adjacents" : [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)], "flags" : [SLCT_EMPTY]}
	]

func do_effect():
	var spawn_pos = _curr_selections[1]
	
	var unit_instance = load("res://Units/Friendlies/f_shield.tscn").instantiate()
	Global.game_ui.add_child(unit_instance)
	unit_instance.init(spawn_pos)
	
	unit_instance.attack_form = Global.rng.randi() % 3
