extends CanvasLayer
##
## Weather autoload — 2026-08-18 사용자 요청으로 비 연출 제거(화면이 계속 어둡게
## 느껴지는 원인 중 하나였음). 오토로드는 SkillFxPreview 등의 `Weather` 참조가
## 깨지지 않게 남겨두되, 실제로는 아무것도 그리지 않는 빈 CanvasLayer 다.
##

func _ready() -> void:
	layer = 5
