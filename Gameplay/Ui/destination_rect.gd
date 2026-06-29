extends TextureRect
class_name DestinationRect

var is_find := false
var current_route : Dictionary = {}
var route_path : String
var route_num : int

@onready var destination_title: Label = %DestinationTitle

func _ready() -> void:
	is_find = MetaProgression.has_visited_destination_route(route_path)
	route_info_update()

func route_info_update():
	if current_route == {}:
		return
	destination_title.text = get_route_title_info(true)

func get_route_title_info(hide_mode:bool = false)->String:
	var title: String
	if hide_mode:
		if !is_find:
			title = "???"
		else:
			title = current_route["title"]
	else:
		title = current_route["title"]
	return title
