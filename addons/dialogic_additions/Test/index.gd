@tool
extends DialogicIndexer

func _get_events() -> Array:
	return [this_folder.path_join('event_test.gd')]

func _get_subsystems() -> Array:
	return [{'name':'Test', 'script':this_folder.path_join('subsystem_test.gd')}]