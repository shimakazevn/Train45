extends GutTest

const DM := preload("res://Autoloads/dialogic_dubbing_manager.gd")


func test_build_voice_path_normal() -> void:
	assert_eq(
		DM.build_voice_path("res://Gameplay/Dialog/Voice", "epilogue_0", "2a4f"),
		"res://Gameplay/Dialog/Voice/epilogue_0/2a4f.ogg"
	)


func test_build_voice_path_trims_trailing_slash() -> void:
	assert_eq(
		DM.build_voice_path("res://Gameplay/Dialog/Voice/", "basetalk", "10"),
		"res://Gameplay/Dialog/Voice/basetalk/10.ogg"
	)


func test_build_voice_path_empty_id_or_timeline() -> void:
	assert_eq(DM.build_voice_path("res://V", "tl", ""), "")
	assert_eq(DM.build_voice_path("res://V", "", "ab"), "")
