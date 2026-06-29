## QA 테스터용 인게임 버그 제보 시스템.
## F12를 누르면 스크린샷을 찍고 Discord + ImgBB + Google Sheets에 전송한다.
extends Node

const BOUNDARY = "----GodotBugReport7x2kBoundary"
const GUILD_ID = "1435551083878547549"
const DIALOG_SCENE = preload("res://Autoloads/BugReporterDialog.tscn")
const SECRETS_PATH = "res://Autoloads/bug_reporter_secrets.cfg"

# 출시 PCK에 평문 시크릿이 박히지 않도록 별도 cfg로 분리(release export에서 제외).
# 파일이 없으면 빈 값 유지 → 네트워크 전송 비활성화.
var WEBHOOK_URL := ""
var IMGBB_API_KEY := ""
var SHEETS_SCRIPT_URL := ""

var _dialog = null
var _http_discord: HTTPRequest = null
var _http_imgbb: HTTPRequest = null
var _http_sheets: HTTPRequest = null
var _pending_screenshot: PackedByteArray = PackedByteArray()
var _is_sending: bool = false
var _was_paused: bool = false
var _report_data: Dictionary = {}
var _imgbb_url: String = ""
var _error_log: Array[String] = []
const MAX_ERROR_LOG = 5

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_secrets()

	_http_discord = HTTPRequest.new()
	_http_discord.use_threads = true
	add_child(_http_discord)
	_http_discord.request_completed.connect(_on_discord_completed)

	_http_imgbb = HTTPRequest.new()
	_http_imgbb.use_threads = true
	add_child(_http_imgbb)
	_http_imgbb.request_completed.connect(_on_imgbb_completed)

	_http_sheets = HTTPRequest.new()
	_http_sheets.use_threads = true
	_http_sheets.max_redirects = 0  # 302에서 멈춤 — doPost는 리다이렉트 전에 실행됨
	add_child(_http_sheets)
	_http_sheets.request_completed.connect(_on_sheets_completed)

## 전송용 시크릿을 외부 cfg에서 로드한다. 파일이 없으면(출시 빌드) 빈 값 유지.
func _load_secrets() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SECRETS_PATH) != OK:
		return
	WEBHOOK_URL = cfg.get_value("secrets", "webhook_url", "")
	IMGBB_API_KEY = cfg.get_value("secrets", "imgbb_api_key", "")
	SHEETS_SCRIPT_URL = cfg.get_value("secrets", "sheets_script_url", "")

func _unhandled_input(event: InputEvent) -> void:
	# 출시(익스포트) 빌드에서는 F2 버그 제보를 막는다. (dev 패널/QA 패널과 동일한 게이팅)
	# Why: 공개 릴리스에서 일반 플레이어가 F2로 개발자 Discord 웹훅에 스크린샷·세이브를 보낼 수 있다.
	# 테스터는 디버그 빌드를 사용하므로 그대로 동작한다.
	if not OS.is_debug_build():
		return
	if WEBHOOK_URL.is_empty() or _dialog != null:
		return
	if event.is_action_pressed("bug_report"):
		get_viewport().set_input_as_handled()
		_capture_and_show()

func _capture_and_show() -> void:
	var rect := Rect2i(DisplayServer.window_get_position(), DisplayServer.window_get_size())
	var img: Image = DisplayServer.screen_get_image_rect(rect)
	if img != null and not img.is_empty():
		_pending_screenshot = img.save_png_to_buffer()
	else:
		_pending_screenshot = PackedByteArray()
	_show_dialog()

func _show_dialog() -> void:
	_was_paused = get_tree().paused
	get_tree().paused = true
	GameEvents.set_window_state(Constants.WINDOW_STATE_BUG_REPORTER, true)

	var state = _collect_state()
	var info_text = "Stage: %s  |  Floor: %s  |  HP: %s  |  v%s" % [
		state.get("stage", "?"),
		state.get("floor", "?"),
		state.get("life", "?"),
		state.get("version", "?"),
	]

	_dialog = DIALOG_SCENE.instantiate()
	add_child(_dialog)
	_dialog.setup(_pending_screenshot, info_text)
	_dialog.cancelled.connect(_close_dialog)
	_dialog.send_pressed.connect(_on_send_pressed)

func _close_dialog() -> void:
	get_tree().paused = _was_paused
	GameEvents.set_window_state(Constants.WINDOW_STATE_BUG_REPORTER, false)
	if _dialog:
		_dialog.queue_free()
		_dialog = null
	_is_sending = false

## 에러 발생 지점에서 호출. 메시지와 콜스택을 버퍼에 저장한다.
func log_error(msg: String) -> void:
	var stack = get_stack().slice(1)  # 이 함수 프레임 제외
	var stack_str = _format_stack(stack)
	var entry = "[%s] %s\n%s" % [Time.get_time_string_from_system(), msg, stack_str]
	_error_log.append(entry)
	if _error_log.size() > MAX_ERROR_LOG:
		_error_log.pop_front()

func _format_stack(stack: Array) -> String:
	var lines: Array[String] = []
	for frame in stack:
		lines.append("  %s:%d @ %s()" % [
			(frame.get("source", "?") as String).get_file(),
			frame.get("line", 0),
			frame.get("function", "?"),
		])
	return "\n".join(lines)

func _collect_state() -> Dictionary:
	var state: Dictionary = {}
	state["version"] = ProjectSettings.get_setting("application/config/version", "?")
	state["time"] = Time.get_datetime_string_from_system()

	var ggm: Node = get_tree().root.find_child("GlobalGameManager", true, false)
	if ggm:
		state["life"] = str(ggm.get("life") if ggm.get("life") != null else "?")
		var fm = ggm.get("floor_manager")
		if fm:
			state["floor"] = str(fm.get("current_floor") if fm.get("current_floor") != null else "?")
			var level = fm.get("current_level")
			if level:
				state["stage"] = (level as Node).get_scene_file_path().get_file().get_basename()

	return state

# ── Step 0: 폼 전송 ──────────────────────────────────────────────────────────

func _on_send_pressed(form_data: Dictionary) -> void:
	if _is_sending:
		return
	_is_sending = true

	var state = _collect_state()
	_report_data = form_data.duplicate()
	_report_data.merge(state)
	if _report_data.get("description", "").is_empty():
		_report_data["description"] = "(설명 없음)"

	_send_to_discord()

# ── Step 1: Discord ───────────────────────────────────────────────────────────

func _send_to_discord() -> void:
	if _dialog:
		_dialog.set_sending(true, "Sending to Discord...")

	var content = "## 🐛 버그 제보\n"
	content += "**테스터:** %s\n" % _report_data.get("tester_name", "?")
	content += "**설명:** %s\n" % _report_data.get("description", "?")
	content += "**재현 방법:** %s\n" % (_report_data.get("steps", "") if not _report_data.get("steps", "").is_empty() else "(없음)")
	content += "**우선순위:** %s | **유형:** %s | **재현율:** %s\n" % [
		_report_data.get("priority", "?"),
		_report_data.get("bug_type", "?"),
		_report_data.get("reproducibility", "?"),
	]
	content += "**스테이지:** `%s` | **층:** %s | **라이프:** %s\n" % [
		_report_data.get("stage", "?"),
		_report_data.get("floor", "?"),
		_report_data.get("life", "?"),
	]
	content += "**버전:** v%s | **시각:** %s" % [_report_data.get("version", "?"), _report_data.get("time", "?")]
	if not _error_log.is_empty():
		content += "\n**최근 에러:**\n```\n%s\n```" % "\n---\n".join(_error_log)

	var payload_json = JSON.stringify({"content": content})
	var body = PackedByteArray()
	var file_index := 0

	var p1 = "--%s\r\n" % BOUNDARY
	p1 += "Content-Disposition: form-data; name=\"payload_json\"\r\n"
	p1 += "Content-Type: application/json\r\n\r\n"
	p1 += payload_json + "\r\n"
	body.append_array(p1.to_utf8_buffer())

	if _pending_screenshot.size() > 0:
		var p = "--%s\r\n" % BOUNDARY
		p += "Content-Disposition: form-data; name=\"files[%d]\"; filename=\"screenshot.png\"\r\n" % file_index
		p += "Content-Type: image/png\r\n\r\n"
		body.append_array(p.to_utf8_buffer())
		body.append_array(_pending_screenshot)
		body.append_array("\r\n".to_utf8_buffer())
		file_index += 1

	if is_instance_valid(MetaProgression) and not MetaProgression.save_data.is_empty():
		var json_bytes = JSON.stringify(MetaProgression.save_data, "\t").to_utf8_buffer()
		var p = "--%s\r\n" % BOUNDARY
		p += "Content-Disposition: form-data; name=\"files[%d]\"; filename=\"save_data.json\"\r\n" % file_index
		p += "Content-Type: application/json\r\n\r\n"
		body.append_array(p.to_utf8_buffer())
		body.append_array(json_bytes)
		body.append_array("\r\n".to_utf8_buffer())
		file_index += 1

	var active_slot = MetaProgression.save_slot if MetaProgression.save_slot >= 0 else Constants.AUTO_SAVE_INDEX
	var save_path = "user://game%d.save" % active_slot
	if FileAccess.file_exists(save_path):
		var save_bytes = FileAccess.get_file_as_bytes(save_path)
		var p = "--%s\r\n" % BOUNDARY
		p += "Content-Disposition: form-data; name=\"files[%d]\"; filename=\"game%d.save\"\r\n" % [file_index, active_slot]
		p += "Content-Type: application/octet-stream\r\n\r\n"
		body.append_array(p.to_utf8_buffer())
		body.append_array(save_bytes)
		body.append_array("\r\n".to_utf8_buffer())
		file_index += 1

	var log_path = "user://logs/godot.log"
	if FileAccess.file_exists(log_path):
		var log_file = FileAccess.open(log_path, FileAccess.READ)
		if log_file:
			const MAX_LOG_BYTES = 50000
			var size = log_file.get_length()
			if size > MAX_LOG_BYTES:
				log_file.seek(size - MAX_LOG_BYTES)
			var log_bytes = log_file.get_buffer(min(size, MAX_LOG_BYTES))
			log_file.close()
			var header = "[Bug Report] Floor: %s | HP: %s\n\n" % [_report_data.get("floor", "?"), _report_data.get("life", "?")]
			var p = "--%s\r\n" % BOUNDARY
			p += "Content-Disposition: form-data; name=\"files[%d]\"; filename=\"godot.log\"\r\n" % file_index
			p += "Content-Type: text/plain\r\n\r\n"
			body.append_array(p.to_utf8_buffer())
			body.append_array(header.to_utf8_buffer())
			body.append_array(log_bytes)
			body.append_array("\r\n".to_utf8_buffer())
			file_index += 1

	body.append_array(("--%s--\r\n" % BOUNDARY).to_utf8_buffer())

	var headers = ["Content-Type: multipart/form-data; boundary=%s" % BOUNDARY]
	var err = _http_discord.request_raw(WEBHOOK_URL + "?wait=true", headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		if _dialog:
			_dialog.set_sending(false, "Send error: HTTPRequest failed (%d)" % err)
		_is_sending = false

func _on_discord_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var body_str = body.get_string_from_utf8()
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body_str) == OK:
			var msg = json.get_data()
			if msg is Dictionary:
				var channel_id = str(msg.get("channel_id", ""))
				var msg_id = str(msg.get("id", ""))
				if channel_id != "" and msg_id != "":
					_report_data["discord_link"] = "https://discord.com/channels/%s/%s/%s" % [GUILD_ID, channel_id, msg_id]
	else:
		print("[BugReporter] Discord send failed HTTP %d / result %d" % [response_code, result])

	# Step 2: ImgBB 업로드
	if _pending_screenshot.size() > 0 and not IMGBB_API_KEY.is_empty():
		_upload_to_imgbb()
	else:
		_imgbb_url = ""
		_send_to_sheets()

# ── Step 2: ImgBB ─────────────────────────────────────────────────────────────

func _upload_to_imgbb() -> void:
	if _dialog:
		_dialog.set_sending(true, "Uploading screenshot...")

	var b64 = Marshalls.raw_to_base64(_pending_screenshot)
	var timestamp = _report_data.get("time", "unknown").replace(":", "-")
	var body_str = "key=%s&image=%s&name=bug_%s" % [IMGBB_API_KEY, b64.uri_encode(), timestamp]
	var headers = ["Content-Type: application/x-www-form-urlencoded"]
	var err = _http_imgbb.request_raw(
		"https://api.imgbb.com/1/upload",
		headers,
		HTTPClient.METHOD_POST,
		body_str.to_utf8_buffer()
	)
	if err != OK:
		print("[BugReporter] ImgBB upload error: %d" % err)
		_imgbb_url = ""
		_send_to_sheets()

func _on_imgbb_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_imgbb_url = ""
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var parsed = json.get_data()
			if parsed is Dictionary and parsed.get("success", false):
				_imgbb_url = parsed.get("data", {}).get("url", "")
	if _imgbb_url.is_empty():
		print("[BugReporter] ImgBB URL parse failed (HTTP %d / result %d)" % [response_code, result])
	_send_to_sheets()

# ── Step 3: Google Sheets ────────────────────────────────────────────────────

func _send_to_sheets() -> void:
	if SHEETS_SCRIPT_URL.is_empty():
		_finish_success()
		return
	if _dialog:
		_dialog.set_sending(true, "Logging to sheet...")

	var save_no = "game%d.save" % MetaProgression.save_slot if MetaProgression.save_slot >= 0 else "new"

	var payload = {
		"tester_name": _report_data.get("tester_name", ""),
		"priority": _report_data.get("priority", ""),
		"bug_type": _report_data.get("bug_type", ""),
		"location": _report_data.get("stage", "?"),
		"steps": _report_data.get("steps", ""),
		"description": _report_data.get("description", ""),
		"reproducibility": _report_data.get("reproducibility", ""),
		"screenshot_url": _imgbb_url,
		"discord_link": _report_data.get("discord_link", ""),
		"version": _report_data.get("version", "?"),
		"save_no": save_no,
		"date_added": _report_data.get("time", "?"),
	}

	var headers = ["Content-Type: application/json"]
	var err = _http_sheets.request_raw(
		SHEETS_SCRIPT_URL,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(payload).to_utf8_buffer()
	)
	if err != OK:
		print("[BugReporter] Sheets send error: %d" % err)
		_finish_success()

func _on_sheets_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	# 200 또는 302(리다이렉트 전 실행 완료) 모두 성공으로 처리
	if response_code != 200 and response_code != 302:
		print("[BugReporter] Sheets failed HTTP %d / result %d: %s" % [response_code, result, body.get_string_from_utf8()])
	_finish_success()

# ─────────────────────────────────────────────────────────────────────────────

func _finish_success() -> void:
	if _dialog:
		_dialog.set_sending(false, "✅ Submitted!")
	await get_tree().create_timer(1.5).timeout
	_close_dialog()
