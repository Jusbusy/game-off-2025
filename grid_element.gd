class_name GridElement extends Node2D

var grid_pos
var is_ghost

func _process_turn():
	pass

func init(pos : Vector2i, _is_ghost : bool = false):
	is_ghost = _is_ghost
	
	if !is_ghost:
		Global.grid[pos.x][pos.y] = self
	position = Global.grid_origin + Global.grid_spacing * pos
	grid_pos = pos

func move(target_pos : Vector2i):
	if !Rect2i(Vector2i.ZERO, Global.grid_size).has_point(target_pos):
		print("OOB Move Occurred")
		return
	
	if !is_ghost:
		Global.grid[grid_pos.x][grid_pos.y] = null
		Global.grid[target_pos.x][target_pos.y] = self
	position = Global.grid_origin + Global.grid_spacing * target_pos
	grid_pos = target_pos
	
func get_local(local_pos : Vector2i):
	var target_pos = grid_pos + local_pos
	if Rect2i(Vector2i.ZERO, Global.grid_size).has_point(target_pos):
		return Global.grid[target_pos.x][target_pos.y]
	return null
