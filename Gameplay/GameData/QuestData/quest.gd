extends Resource
class_name QuestData

# -1 일 경우 해당하지 않음

@export var id: String
@export_multiline var description: String

@export_subgroup("Love")
@export var npcs : Array[QuestNpc] = []
@export_subgroup("Total Love")
@export var total_love:int = -1
@export_subgroup("Ticket")
@export var ticket: int = -1
@export_subgroup("FindRoute")
@export var route : int = -1
@export_subgroup("Collect Destinations")
@export var collect_destinations:int = -1
@export_subgroup("Collect Items")
@export var collect_items:int = -1
@export_subgroup("Complete Count")
@export var complete_count:int = -1
@export_subgroup("Talk")
@export_multiline var talk: String = ""
