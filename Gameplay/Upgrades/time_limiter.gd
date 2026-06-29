extends TextureProgressBar

const ICON_TIMER = preload("res://resources/ui/icons/icons1.png")

var limit_gage := 100.0
var is_time_end := false

const MINUS_VALUE := 5

func _ready() -> void:
	GameEvents.stage_clear.connect(_on_stage_clear)
	GameEvents.in_next_stage.connect(_on_next_stage)
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	self.value = limit_gage

func _on_next_stage():
	self.queue_free()

func _process(delta: float) -> void:
	if not is_time_end:
		limit_gage -= MINUS_VALUE * delta
		self.set_value_no_signal(limit_gage)
		if limit_gage <= 0:
			is_time_end = true

func _on_stage_clear():
	var ticket_n: int = Constants.BONUS_TICKET_TIME_RIMIT
	var ticket_v: int = Constants.TICKET_VALUE_NORMAL # 2
	
	if not is_time_end:
		if GameEvents.get_current_stage_type() == Constants.TYPE_SAFE:
			GameEvents.emit_set_ticket("plus", ticket_n)
		else:
			GameEvents.emit_drop_item(Constants.PC_PLAYER, DropItemManager.ItemType.TICKET, int(float(ticket_n) / ticket_v))

		var message = tr("NOTI_ITEM_TIME_BONUS")%(ticket_n)
		NotionEvent.notion(message, ICON_TIMER)
		is_time_end = true

func _on_timeline_started():
	hide()
func _on_timeline_ended():
	show()
