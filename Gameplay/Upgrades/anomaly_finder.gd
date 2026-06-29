extends NinePatchRect

var color_rect
var noise
var noise_texture

func _ready():
	GameEvents.stage_clear.connect(_on_stage_clear)
	
	color_rect = $ColorRect2
	noise = color_rect.material as ShaderMaterial
	noise_texture = noise.get_shader_parameter("textureNoise")
	noise_texture.width = 1200.0
	noise_texture.height = 360.0
	noise.set_shader_parameter("textureNoise", noise_texture)
	
func _on_stage_clear():
	self.queue_free()
