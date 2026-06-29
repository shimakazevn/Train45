class_name ChapterScreen
extends CanvasLayer

signal chapter_screen_end

static var is_playing: bool = false

@export var debug_test_next_chapter: int = 0
@export var debug_test_lang: String = "ko"

@onready var chapter_label: Label = %ChapterLabel
@onready var description_label: Label = %DescriptionLabel
@onready var goal_label: Label = %GoalLabel
@onready var chapter_player: AnimationPlayer = $ChapterPlayer


var next_chapter : int
var chapter_info : ChapterInfo

var chapter_str : String
var description_str : String

func _ready() -> void:
	if Constants.CHAPTER_SCREEN_DEBUG:
		push_error("debug_test중입니다. 테스트 후 해제해 주세요.")
		next_chapter = debug_test_next_chapter
		LanguageManager.set_language(debug_test_lang)
	
	chapter_info = ChapterInfo.new()
	var loading_screen = get_parent() as LoadingScreen
	if loading_screen:
		loading_screen.transition_in_complete.connect(screen_play)
	chapter_label.text = chapter_info.chapters[next_chapter]["title"]
	description_label.text = chapter_info.chapters[next_chapter]["description"]
	var goal_int = chapter_info.chapters[next_chapter]["goal"]
	goal_label.text = str(goal_int)
	
	if Constants.CHAPTER_SCREEN_DEBUG:
		screen_play()

func screen_end():
	is_playing = false
	chapter_screen_end.emit()

func screen_play():
	is_playing = true
	chapter_player.play("in")
	
