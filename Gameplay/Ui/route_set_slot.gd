extends RouteSlot
class_name RouteSetSlot

func route_info_update():
	if current_route == {}:
		return
	if !MetaProgression.has_route_data(route_path):
		route_title.text = "???"
	else:
		route_title.text = current_route["title"]
		disabled = false
