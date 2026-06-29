extends HBoxContainer
class_name HintBlankComponent
## 힌트 빈칸 슬롯을 관리하는 [code]HBoxContainer[/code].
## 주어진 숫자만큼의 빈칸을 표시하여 정답 자릿수를 시각적으로 나타낸다.
## 목적지 방문 전에는 [code]QMarkLabel[/code], 방문 후에는 [code]Label[/code]+[code]NumLabel[/code]을 표시한다.

@export var patial_label: Label

## [param num] 값에 따라 빈칸 슬롯의 표시 여부를 설정한다.
## [param num] 이후의 슬롯만 표시하고 나머지는 숨긴다.
func set_blank_slot(num: int):
	var current_num: int = 0
	for i in self.get_children():
		var blank: TextureRect = i
		blank.hide()
		if current_num == num:
			pass
		else:
			blank.show()
			current_num += 1

## [param hint_info]를 기반으로 각 슬롯 표시를 갱신한다.
## 방문된 경우 [code]Label[/code]+[code]NumLabel[/code] 표시, 아닌 경우 [code]QMarkLabel[/code] 표시.
func update_hint_labels(hint_info: RouteHintPage):
	if hint_info == null:
		return
	_update_partial_label(hint_info)
	var visible_slots: Array = []
	for child in get_children():
		if child is TextureRect and child.visible:
			visible_slots.append(child)

	if RouteData.is_clear_destination(hint_info.id):
		var route_data_list := _get_route_data(hint_info)
		for i in visible_slots.size():
			var slot: TextureRect = visible_slots[i]
			if i < route_data_list.size():
				_set_slot_answer(slot, route_data_list[i]["title"], str(route_data_list[i]["num"]))
			else:
				_set_slot_question(slot)
	else:
		for slot in visible_slots:
			_set_slot_question(slot)

## 슬롯에 정답(노선 제목·번호)을 표시한다.
func _set_slot_answer(slot: TextureRect, title: String, num: String):
	var label := slot.get_node_or_null("Label") as Label
	var num_label := slot.get_node_or_null("NumLabel") as Label
	var q_label := slot.get_node_or_null("QMarkLabel") as Label
	if label:
		label.text = title
		label.show()
	if num_label:
		num_label.text = num
		num_label.show()
	if q_label:
		q_label.hide()

## 슬롯에 물음표를 표시한다.
func _set_slot_question(slot: TextureRect):
	var label := slot.get_node_or_null("Label") as Label
	var num_label := slot.get_node_or_null("NumLabel") as Label
	var q_label := slot.get_node_or_null("QMarkLabel") as Label
	if label:
		label.hide()
	if num_label:
		num_label.hide()
	if q_label:
		q_label.show()

## [param hint_info]의 목적지에 해당하는 노선 제목·번호 딕셔너리 배열을 반환한다.
## 후보 노선 전체를 반환한다. partial_match_count가 있어도 후보를 모두 표시하며,
## 필요 개수는 [method _update_partial_label]의 "N개 이상" 라벨로 안내한다.
## [hint_slot.gd get_hint_answer] 참조.
func _get_route_data(hint_info: RouteHintPage) -> Array:
	var route_data := RouteData.new()
	var destination_info: Dictionary = (RouteData.destination_info as Dictionary).duplicate(true)
	for i in destination_info:
		if destination_info[i]["hint_id"] == hint_info.id:
			var routes: Array = destination_info[i]["route_list"]
			var route_list_type: String = destination_info[i]["route_list_type"]
			# partial 케이스도 후보 전체를 보여준다 (필요 개수는 "N개 이상" 라벨로 별도 안내)
			var count: int = routes.size()
			var result: Array = []
			for j in count:
				result.append({
					"title": tr(route_data.get_route_title_routename(routes[j], route_list_type)),
					"num": route_data.get_route_index_routename(routes[j], route_list_type)
				})
			return result
	return []

## partial_match_count가 있는 종착점이면 "N개 이상" 안내 라벨을 표시한다.
## 표시용 라벨([code]PartialLabel[/code]) 노드가 없으면 아무 것도 하지 않는다(노드는 씬에서 추가).
func _update_partial_label(hint_info: RouteHintPage) -> void:
	var label := patial_label
	if label == null:
		return
	var min_count := _partial_match_count(hint_info)
	if min_count > 0:
		label.text = tr("HINT_PARTIAL_NEEDED").format({"n": min_count})
		label.show()
	else:
		label.hide()

## 해당 힌트 종착점의 partial_match_count를 반환한다. 없으면 0.
func _partial_match_count(hint_info: RouteHintPage) -> int:
	for key in RouteData.destination_info:
		var dest: Dictionary = RouteData.destination_info[key]
		if dest.get("hint_id") == hint_info.id:
			var partial = dest.get("partial_match_count", null)
			return int(partial) if partial != null else 0
	return 0
