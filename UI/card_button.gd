extends Control

func _make_custom_tooltip(for_text: String) -> Object:
	self.get_theme().set_stylebox("panel", "TooltipPanel", StyleBoxEmpty.new())
	if for_text == "":
		return null
	var tool_tip = load("res://UI/button_tooltip.tscn").instantiate()
	tool_tip.text = for_text
	return tool_tip
