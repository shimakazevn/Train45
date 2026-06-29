extends TextureRect

var floor_manager: FloorManager
const UNVISIT_NEED_STACK: int = 4
@onready var stack_label: Label = $StackLabel

var stack_add_lock: bool = false # 한 스테이지에 2개 이상 추가되는 것을 막기 위한 bool
var _stack_tween: Tween = null

const ICON_UNVISIT_FINDER = preload("res://resources/ui/icons/icons24.png")

func _ready() -> void:
	GameEvents.stage_clear.connect(_on_stage_clear)
	GameEvents.in_next_stage.connect(_on_next_stage)
	MetaProgression.stage_first_clear.connect(_on_stage_first_clear)
	floor_manager = get_tree().get_first_node_in_group("floormanager")
	floor_manager.clear_stack_update.connect(_on_clear_stack_update)
	if floor_manager.setting_route_manager.setting_route.size() > 0:
		self.self_modulate = Color.RED
		stack_label.hide()
	update_stack_lable()

func _on_stage_first_clear():
	pass

func _on_stage_clear():
	add_clear_num()

func _on_next_stage():
	self.queue_free()

func _on_clear_stack_update():
	update_stack_lable()

func add_clear_num():
	if not stack_add_lock:
		floor_manager.add_clear_stage_stack(UNVISIT_NEED_STACK)
		stack_add_lock = true

func update_stack_lable():
	await get_tree().process_frame
	if not floor_manager._has_unvisited_stage():
		if _stack_tween:
			_stack_tween.kill()
		self.self_modulate = Color.LAWN_GREEN
		stack_label.text = "٩(◕‿◕)۶"
		return
	var clear_stack: int = floor_manager.get_clear_stage_stack()
	stack_label.text = str(clear_stack) + "/" + str(UNVISIT_NEED_STACK)
	if clear_stack >= UNVISIT_NEED_STACK:
		_stack_tween = create_tween()
		_stack_tween.tween_property(self, "self_modulate", Color.WHITE, 1.0).from(Color.AQUAMARINE)
		_stack_tween.set_loops()
