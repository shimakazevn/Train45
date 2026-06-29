@tool
extends DialogicIndexer

func _get_events() -> Array:
	return [this_folder.path_join('event_choice_button_custom.gd')]
