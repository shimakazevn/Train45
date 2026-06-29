## 저사양 모드 시 씬 내 모든 Light2D를 비활성화하고 LowSpecLight 그룹 노드를 표시한다.
## 일반 모드에서는 아무 동작도 하지 않는다.
extends Node

var _quality: bool = true


func _ready() -> void:
	var settings = ConfigFileHandler.load_video_setting()
	var is_opengl := is_compatibility_renderer()
	# 버그 제보 진단용: OpenGL(Compatibility)로 구동된 경우 GPU·드라이버 정보를 로그에 남긴다.
	# Vulkan 자동 폴백으로 OpenGL이 됐는지 추적할 수 있어, 튕김 제보 분석에 쓰인다.
	if is_opengl:
		print("[Renderer] Running in Compatibility(OpenGL) mode — GPU: %s, Driver: %s" % [
			RenderingServer.get_video_adapter_name(), OS.get_video_adapter_driver_info()])
	# Compatibility(OpenGL) 렌더러에서는 Light2D·글로우가 정상 표시되지 않는다.
	# 최초 OpenGL 구동 시 퍼포먼스 모드를 기본값으로 1회만 켜고, 이후엔 사용자가 저장한 선택을 따른다.
	# (Vulkan 자동 폴백/수동 --rendering-driver opengl3 모두 동일하게 적용됨)
	if is_opengl and not settings.get("opengl_perf_default_applied", false):
		ConfigFileHandler.save_video_setting("light_quality", false)
		ConfigFileHandler.save_video_setting("opengl_perf_default_applied", true)
		settings["light_quality"] = false
	_quality = settings.get("light_quality", true)
	get_viewport().use_hdr_2d = _quality
	if not _quality:
		get_tree().node_added.connect(_on_node_added)
		GameEvents.stage_change.connect(_on_stage_change)
		call_deferred("_apply_to_existing_nodes")


## 현재 Compatibility(OpenGL) 렌더러로 구동 중인지 여부.
## Forward+/Mobile은 RenderingDevice(Vulkan/D3D12)를 쓰지만 Compatibility는 쓰지 않아 null이 된다.
func is_compatibility_renderer() -> bool:
	return RenderingServer.get_rendering_device() == null


func _on_node_added(node: Node) -> void:
	if node is Light2D:
		node.enabled = false
	elif node is GPUParticles2D:
		node.emitting = false
	elif node.is_in_group("LowSpecLight"):
		node.visible = true


## 스테이지 전환 후 이미 트리에 있는 노드에 저사양 설정을 재적용한다.
## node_added만으로는 _ready()에서 재활성화되는 노드를 잡지 못할 수 있기 때문.
func _on_stage_change() -> void:
	await get_tree().process_frame
	_apply_to_existing_nodes()


func _apply_to_existing_nodes() -> void:
	for light in _get_all_lights():
		light.enabled = false
	for particle in get_tree().root.find_children("*", "GPUParticles2D", true, false):
		particle.emitting = false
	for node in get_tree().get_nodes_in_group("LowSpecLight"):
		node.visible = true


## light_quality 설정을 변경하고 현재 씬에 즉시 적용한다.
func set_quality(enabled: bool) -> void:
	_quality = enabled
	ConfigFileHandler.save_video_setting("light_quality", enabled)
	get_viewport().use_hdr_2d = enabled
	if enabled:
		if get_tree().node_added.is_connected(_on_node_added):
			get_tree().node_added.disconnect(_on_node_added)
		if GameEvents.stage_change.is_connected(_on_stage_change):
			GameEvents.stage_change.disconnect(_on_stage_change)
	else:
		if not get_tree().node_added.is_connected(_on_node_added):
			get_tree().node_added.connect(_on_node_added)
		if not GameEvents.stage_change.is_connected(_on_stage_change):
			GameEvents.stage_change.connect(_on_stage_change)
	for light in _get_all_lights():
		light.enabled = enabled
	for particle in get_tree().root.find_children("*", "GPUParticles2D", true, false):
		particle.emitting = enabled
	for node in get_tree().get_nodes_in_group("LowSpecLight"):
		node.visible = not enabled


func _get_all_lights() -> Array:
	var lights := get_tree().root.find_children("*", "PointLight2D", true, false)
	lights += get_tree().root.find_children("*", "DirectionalLight2D", true, false)
	return lights
