extends GridContainer
class_name InventoryCostBubbles

@export var cost_bubble_scene: PackedScene

const COST_BUBBLE_EMPTY = preload("res://resources/ui/Inventory/cost_bubble_0.png")
const COST_BUBBLE_FILL = preload("res://resources/ui/Inventory/cost_bubble_1.png")

func _ready() -> void:
	init_bubbles()

func init_bubbles():
	if self.get_child_count() >= 0:
		for bubble in self.get_children():
			if is_instance_valid(bubble):
				bubble.queue_free()

func update_cost_bubble(total_cost: int, equip_cost: int):
	init_bubbles()

	for i in total_cost:
		var cost_bubble_instance = cost_bubble_scene.instantiate()
		self.add_child(cost_bubble_instance)

		var texture: Texture2D
		if i < equip_cost:
			texture = COST_BUBBLE_FILL
		else:
			texture = COST_BUBBLE_EMPTY

		cost_bubble_instance.texture = texture

func show_cost_bubble_example(item_cost: int = 0):
	reset_bubble_colors()

	var empty_bubbles: Array = []

	# 먼저 빈 버블들만 모음
	for bubble in self.get_children():
		if bubble is TextureRect and bubble.texture == COST_BUBBLE_EMPTY:
			empty_bubbles.append(bubble)

	# 장착 불가능한 경우 (남은 빈 버블보다 아이템 코스트가 더 큼)
	if item_cost > empty_bubbles.size():
		for bubble in empty_bubbles:
			bubble.modulate = Color.RED
	else:
		for i in item_cost:
			empty_bubbles[i].modulate = Color.AQUAMARINE

func reset_bubble_colors():
	for bubble in self.get_children():
		bubble.modulate = Color.WHITE
