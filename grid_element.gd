class_name GridElement extends Node2D

var grid_pos

func _process_turn():
	pass

func init_position(pos : Vector2i):
	Global.grid[pos.x][pos.y] = self
	position = Global.grid_origin + Global.grid_spacing * pos
	grid_pos = pos

func move(target_pos : Vector2i):
	if target_pos.x < 0 || target_pos.y < 0 || target_pos.x >= Global.grid_size.x || target_pos.y >= Global.grid_size.y:
		print("OOB Move Occurred")
		return
	
	Global.grid[grid_pos.x][grid_pos.y] = null
	Global.grid[target_pos.x][target_pos.y] = self
	position = Global.grid_origin + Global.grid_spacing * target_pos
	grid_pos = target_pos
	
func get_local(local_pos : Vector2i):
	var target_pos = grid_pos + local_pos
	if target_pos.x < 0 || target_pos.y < 0 || target_pos.x >= Global.grid_size.x || target_pos.y >= Global.grid_size.y:
		return null
	return Global.grid[target_pos.x][target_pos.y]
