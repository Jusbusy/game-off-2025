class_name CardUnitMelee extends Card

func get_icon():
	return load("res://UI/Icons/Card_Melee.png")
func get_name():
	return "Spawn Melee"

func get_cost():
	return 1
func get_selection_rules():
	return [
		{"flags" : [SLCT_FRIEND_SPAWN, SLCT_EMPTY]}
	]

func do_effect():
	var spawn_pos = _curr_selections[0]
	
	var unit_instance = load("res://Units/Friendlies/f_melee.tscn").instantiate()
	Global.get_tree().root.add_child(unit_instance)
	unit_instance.init(spawn_pos)
	
	unit_instance.attack_form = Global.rng.randi() % 3
