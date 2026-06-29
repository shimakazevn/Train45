## [KR] 컷씬 이미지의 표시/숨김을 관리하는 오토로드 싱글톤.
##
## [KR] [member cutscene_container] 하위의 [CutSceneAsset] 노드들을 수집하여
## [KR] 이름 기반으로 컷씬을 표시하거나 숨긴다.
## [KR] Dialogic 타임라인에서 [code]CutSceneManager.show_cutscene("name")[/code]으로 호출된다.
## [EN] Autoload singleton that manages show/hide of cutscene images.
##
## [EN] Collects [CutSceneAsset] nodes under [member cutscene_container] and
## [EN] shows or hides cutscenes by name.
## [EN] Called from Dialogic timeline via [code]CutSceneManager.show_cutscene("name")[/code].
extends Node

## [KR] 컷씬 에셋들이 배치된 부모 컨테이너. 에디터에서 할당한다.
## [EN] Parent container where cutscene assets are placed. Assigned in the editor.
@export var cutscene_container: Control
## [KR] 초기화 시 수집된 [CutSceneAsset] 목록.
## [EN] List of [CutSceneAsset] collected during initialization.
var cutscenes: Array[CutSceneAsset]



func _ready() -> void:
	for i in cutscene_container.get_children():
		if i is CutSceneAsset:
			cutscenes.append(i)

## [KR] 지정한 이름의 컷씬을 페이드인+이동 애니메이션으로 표시한다.
##
## [KR] [param cutscene_name]은 [CutSceneAsset] 노드의 [member Node.name]과 일치해야 한다.
## [KR] 일치하는 컷씬이 없으면 아무 동작도 하지 않는다.
## [EN] Shows the cutscene with the given name using fade-in and move animation.
##
## [EN] [param cutscene_name] must match the [member Node.name] of the [CutSceneAsset] node.
## [EN] Does nothing if no matching cutscene is found.
func show_cutscene(cutscene_name: String):
	var cutscene = _get_cutscene(cutscene_name)
	if cutscene:
		cutscene.cutscene_in()

## [KR] 지정한 이름의 컷씬을 페이드아웃+이동 애니메이션으로 숨긴다.
##
## [KR] [param cutscene_name]은 [CutSceneAsset] 노드의 [member Node.name]과 일치해야 한다.
## [KR] 일치하는 컷씬이 없으면 아무 동작도 하지 않는다.
## [EN] Hides the cutscene with the given name using fade-out and move animation.
##
## [EN] [param cutscene_name] must match the [member Node.name] of the [CutSceneAsset] node.
## [EN] Does nothing if no matching cutscene is found.
func hide_cutscene(cutscene_name: String):
	var cutscene = _get_cutscene(cutscene_name)
	if cutscene:
		cutscene.cutscene_out()

## [KR] 모든 컷씬을 숨긴다.
## [EN] Hides all cutscenes.
func hide_all_cutscenes():
	for i in cutscenes:
		var cutscene: CutSceneAsset = i
		cutscene.cutscene_out()

## [KR] 이름으로 컷씬 에셋을 검색한다.
##
## [KR] [param cutscene_name]과 일치하는 [CutSceneAsset]을 반환한다.
## [KR] 찾지 못하면 null을 반환한다.
## [EN] Searches for a cutscene asset by name.
##
## [EN] Returns the [CutSceneAsset] matching [param cutscene_name].
## [EN] Returns null if not found.
func _get_cutscene(cutscene_name: String)-> CutSceneAsset:
	for i in cutscenes:
		var cutscene: CutSceneAsset = i
		if cutscene.name == cutscene_name:
			return cutscene
	return null
