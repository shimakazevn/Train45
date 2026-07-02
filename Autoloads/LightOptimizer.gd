## 저사양 모드 시 씬 내 모든 Light2D를 비활성화하고 LowSpecLight 그룹 노드를 표시한다.
## 일반 모드에서는 아무 동작도 하지 않는다.
extends Node

var _quality: bool = true
## 현재 적용된 그래픽 프리셋 tier ("high" / "medium" / "low").
var _tier: String = "high"


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
		ConfigFileHandler.save_video_setting("quality_tier", "medium")
		ConfigFileHandler.save_video_setting("light_quality", false)
		ConfigFileHandler.save_video_setting("opengl_perf_default_applied", true)
		settings["quality_tier"] = "medium"
		settings["light_quality"] = false
	# tier가 저장돼 있으면 그걸 우선하고, 없으면 light_quality(하위호환)로 유추한다.
	_tier = settings.get("quality_tier", "high" if settings.get("light_quality", true) else "medium")
	_quality = _tier == "high"
	# FPS 상한 적용 (기본 60, 사용자 설정 시 그 값). 저사양 tier여도 30으로 강제하지 않는다.
	Engine.max_fps = int(settings.get("max_fps", 60))
	# 렌더 스케일은 content_scale_factor 방식이 화면을 축소시키는 문제가 있어 보류. (아래 set_render_scale 참고)
	# [KR] 모바일(타일 기반 GPU)에서 HDR 2D 중간 버퍼가 프레임마다 clear되지 않아
	# 잔상(고스팅)이 생기는 문제가 있어, 모바일에서는 tier와 무관하게 HDR 2D를 끈다.
	# [EN] On mobile (tile-based GPUs) the HDR 2D intermediate buffer isn't cleared per frame,
	# causing ghosting/trails — so keep HDR 2D off on mobile regardless of tier.
	get_viewport().use_hdr_2d = _quality and not ConfigFileHandler.is_mobile()
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
	elif node is GPUParticles2D or node is CPUParticles2D:
		node.emitting = false
	elif node is WorldEnvironment:
		_disable_glow(node)
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
	for particle in _get_all_particles():
		particle.emitting = false
	for env in get_tree().root.find_children("*", "WorldEnvironment", true, false):
		_disable_glow(env)
	for node in get_tree().get_nodes_in_group("LowSpecLight"):
		node.visible = true


## WorldEnvironment의 글로우(블룸)를 끈다. 모바일에서 가장 비싼 풀스크린 효과 중 하나.
## Environment 리소스가 다른 씬과 공유될 수 있으므로 복제 후 수정한다.
func _disable_glow(env: WorldEnvironment) -> void:
	if env.environment == null:
		return
	if env.environment.glow_enabled:
		env.environment = env.environment.duplicate()
		env.environment.glow_enabled = false


## 씬 내 모든 GPU/CPU 파티클 노드를 모은다.
func _get_all_particles() -> Array:
	var particles := get_tree().root.find_children("*", "GPUParticles2D", true, false)
	particles += get_tree().root.find_children("*", "CPUParticles2D", true, false)
	return particles


## light_quality 설정을 변경하고 현재 씬에 즉시 적용한다.
func set_quality(enabled: bool) -> void:
	_quality = enabled
	ConfigFileHandler.save_video_setting("light_quality", enabled)
	# 모바일에서는 잔상(고스팅) 방지를 위해 HDR 2D를 켜지 않는다. (위 _ready 주석 참고)
	get_viewport().use_hdr_2d = enabled and not ConfigFileHandler.is_mobile()
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
	for particle in _get_all_particles():
		particle.emitting = enabled
	for env in get_tree().root.find_children("*", "WorldEnvironment", true, false):
		if not enabled:
			_disable_glow(env)
	for node in get_tree().get_nodes_in_group("LowSpecLight"):
		node.visible = not enabled


func _get_all_lights() -> Array:
	var lights := get_tree().root.find_children("*", "PointLight2D", true, false)
	lights += get_tree().root.find_children("*", "DirectionalLight2D", true, false)
	return lights


## 현재 적용된 그래픽 프리셋 tier를 반환한다.
func get_tier() -> String:
	return _tier


## 그래픽 프리셋 tier("high"/"medium"/"low")를 적용하고 저장한다.
## high = 조명/글로우/파티클 전부 켬, medium·low = 저사양 경로(조명·글로우·파티클 끔).
## [br]Why: LightOptimizer가 이미 저사양 처리를 담당하므로 tier를 여기로 모아 옵션 UI와 부팅이 공유한다.
func apply_tier(tier: String) -> void:
	_tier = tier
	ConfigFileHandler.save_video_setting("quality_tier", tier)
	set_quality(tier == "high")


## FPS 상한을 즉시 적용하고 저장한다.
func set_max_fps(fps: int) -> void:
	ConfigFileHandler.save_video_setting("max_fps", fps)
	Engine.max_fps = fps
