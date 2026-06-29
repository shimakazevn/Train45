extends HSlider
## 오디오 볼륨 슬라이더를 관리하는 [code]HSlider[/code].
## 오디오 버스의 볼륨을 조절하고 설정 파일에 저장한다.

## 제어할 오디오 버스 이름
@export var bus_name: String
## 오디오 버스 인덱스
var bus_index: int

## 초기화 시 [member bus_name]에 해당하는 버스 인덱스를 가져오고 현재 볼륨을 슬라이더에 반영한다.
func _ready() -> void:
	bus_index = AudioServer.get_bus_index(bus_name)
	value_changed.connect(_on_value_changed)
	
	value = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	
## 슬라이더 값 변경 시 오디오 버스 볼륨을 [param target_value]로 설정하고 설정 파일에 저장한다.
func _on_value_changed(target_value: float)-> void:
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(target_value))
	
	var target_key: String
	match bus_name:
		"Master":
			target_key = "volume_master"
		"Sfx":
			target_key = "volume_sfx"
		"Character":
			target_key = "volume_char"
		"Music":
			target_key = "volume_bg"
	
	ConfigFileHandler.save_audio_setting(target_key, target_value)
