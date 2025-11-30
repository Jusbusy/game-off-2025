@abstract
class_name Card

var icon:
	get:
		return get_icon()
func get_icon():
	return null
var name: String:
	get:
		return get_name()
func get_name() -> String:
	return ""

var cost: int:
	get:
		return get_cost()
func get_cost() -> int:
	return 0
	 
var selection_rules: Array: # [{area: ..., adjacents: ..., flags: }]
	get:
		return get_selection_rules()
func get_selection_rules() -> Array:
	return []

const SLCT_EMPTY = 1 << 0
const SLCT_FRIEND = 1 << 1
const SLCT_ENEMY = 1 << 2
const SLCT_FRIEND_SPAWN = 1 << 3
const SLCT_ENEMY_SPAWN = 1 << 4

var _select_id = 0
var _curr_selections = []
func update():
	if Input.is_action_just_pressed("select"):
		var select = Global.get_mouse_tile()
		if select != null && check_selection(select):
			_curr_selections.append(select)
			_select_id += 1
	
	if _select_id >= selection_rules.size():
		Global.player_ap -= cost
		do_effect()
		reset_selection()
		return false
	
	return true

func reset_selection():
	_select_id = 0
	_curr_selections = []

func check_selection(pos: Vector2i):
	if _select_id >= selection_rules.size():
		return false
	var rules = selection_rules[_select_id]
	
	# Check OOB
	if pos.x < 0 || pos.y < 0 || pos.x >= Global.grid_size.x || pos.y >= Global.grid_size.y:
		return false
	
	# Set flags
	var selected_flags = 0
	var elem = Global.grid[pos.x][pos.y]
	if !elem:
		selected_flags = selected_flags | SLCT_EMPTY
	else:
		if !elem.enemy:
			selected_flags = selected_flags | SLCT_FRIEND
		else:
			selected_flags = selected_flags | SLCT_ENEMY
	if pos.x == 0:
		selected_flags = selected_flags | SLCT_FRIEND_SPAWN
	if pos.x == Global.grid_size.x - 1:
		selected_flags = selected_flags | SLCT_ENEMY_SPAWN
	
	# Check flags
	if rules.has("flags"):
		for flag in rules["flags"]:
			if flag & selected_flags == 0:
				return false
	
	# Check if in valid adjacent tile
	if rules.has("adjacents"):
		var prev_pos = _curr_selections[_select_id - 1]
		for adj in rules["adjacents"]:
			if prev_pos + adj == pos:
				return true
		return false
	
	return true
	
func do_effect():
	pass
