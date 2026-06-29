class_name ShopTable

var items: Array[Dictionary] = []

func add_item(item: AbilityUpgrade, grade : int):
	if not has_item(item):
		items.append({"item": item, "grade": grade})

func has_item(item: AbilityUpgrade) -> bool:
	for entry in items:
		if entry["item"] == item:
			return true
	return false

func remove_item(item_to_remove):
	items = items.filter(func (item): return item["item"] != item_to_remove)
