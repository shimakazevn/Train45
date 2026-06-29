extends Control

@onready var current_label: Label = %CurrentLabel
@onready var stage_grid: GridContainer = %StageGrid

var _floor_manager: FloorManager
var _route_data: RouteData

func setup(floor_manager: FloorManager) -> void:
	_floor_manager = floor_manager
	_route_data = _floor_manager.route_data if _floor_manager else RouteData.new()
	_update_current_label(_floor_manager.next_stage_path.get_file().get_basename() if _floor_manager else "")
	_populate()

func _get_display_text(stage_name: String) -> String:
	var title := tr(_route_data.get_route_title_routename(stage_name, "name"))
	if title.is_empty():
		return stage_name
	return title + "\n" + stage_name

func _update_current_label(stage_name: String) -> void:
	if stage_name.is_empty():
		current_label.text = "Next: -"
	else:
		current_label.text = "Next:  " + _get_display_text(stage_name).replace("\n", "  /  ")

func _populate() -> void:
	var stage_names: Array[String] = []
	var dir := DirAccess.open("res://Gameplay/Levels/")
	if dir:
		for file in dir.get_files():
			if file.ends_with(".tscn"):
				stage_names.append(file.get_basename())
	stage_names.sort()

	for stage_name in stage_names:
		var btn := Button.new()
		btn.text = _get_display_text(stage_name)
		btn.custom_minimum_size = Vector2(118, 40)
		btn.add_theme_font_size_override("font_size", 9)
		btn.pressed.connect(_on_stage_selected.bind(stage_name))
		stage_grid.add_child(btn)

func _on_stage_selected(stage_name: String) -> void:
	if _floor_manager:
		_floor_manager.next_stage_path = "res://Gameplay/Levels/" + stage_name + ".tscn"
	_update_current_label(stage_name)
	current_label.text += "  ✓"
	
	var title := tr(_route_data.get_route_title_routename(stage_name, "name"))
	var display := (title + " (" + stage_name + ")") if not title.is_empty() else stage_name
	NotionEvent.notion("Next Stage: " + display)
