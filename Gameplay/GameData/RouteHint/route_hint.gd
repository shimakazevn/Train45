extends Resource
class_name RouteHintPage

@export var id: String
@export var title: String
@export var texture : CompressedTexture2D = null
@export_multiline var description : String = ""
enum PartnerType { NONE = -1, REINA, MAI}
@export var partner_type:PartnerType = PartnerType.NONE
