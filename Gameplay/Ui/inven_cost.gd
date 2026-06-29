extends HBoxContainer
class_name InvenCost

var current_cost:= 0
var max_cost:= 0
@onready var current_cost_label: Label = $CurrentCostLabel
@onready var max_cost_label: Label = $MaxCostLabel
@onready var random_stream_player: AudioStreamPlayer = $RandomStreamPlayerGlobalComponent

var current_cost_tween: Tween
var max_cost_tween: Tween

enum CostType {CurrentCost, MaxCost}
func update_cost_label(input_cost: int, cost_type: CostType):
	var from: int
	var to: int
	var assign_target: Callable

	match cost_type:
		CostType.CurrentCost:
			if current_cost == input_cost:
				return
			from = current_cost
			to = input_cost
			current_cost = input_cost

			var tracker := {"prev_value": from}
			assign_target = func(v):
				var int_value = round(v)
				if int_value != tracker.prev_value:
					random_stream_player.play_random()
					tracker.prev_value = int_value
				current_cost_label.text = str(int_value)
		
		CostType.MaxCost:
			if max_cost == input_cost:
				return
			from = max_cost
			to = input_cost
			max_cost = input_cost
			assign_target = func(v): max_cost_label.text = str(round(v))

	var tween := create_tween()
	tween.tween_method(assign_target, from, to, 0.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
