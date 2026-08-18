extends Node
##
## WorldTint autoload — TimeManager 시간대에 따라 화면 색을 살짝 어둡게/푸르게.
##
## 직접 CanvasModulate 를 인스턴스해 SceneTree.root 에 붙이고, 매 time_changed 시
## TimeManager.tint_for(t) 결과로 color 를 갱신.
## CanvasModulate 는 한 캔버스(=Viewport)에 하나만 동작하므로 씬마다 따로 둘 필요 없음.
##

## 2026-07-10: 밤낮 순환 제거 — 시간에 따라 변하지 않는 고정 톤.
## 2026-08-18: 흐리고 비 오는 회청색 어둠(사용자 피드백 "아직 어둡네요")을 걷어내고
## 중립(=원래 색 그대로) 톤으로 변경 — 전 화면 다운틴트 없음.
const OVERCAST := Color(1, 1, 1)

var _modulate: CanvasModulate


func _ready() -> void:
    _modulate = CanvasModulate.new()
    _modulate.color = OVERCAST
    # SceneTree 가 아직 안 만들어졌을 수 있으니 한 프레임 대기
    call_deferred("_install")
    if TimeManager and not TimeManager.STATIC_OVERCAST:
        TimeManager.time_changed.connect(_on_time_changed)


func _install() -> void:
    if get_tree() and get_tree().root and _modulate.get_parent() == null:
        get_tree().root.add_child(_modulate)


func _on_time_changed(t: float) -> void:
    if _modulate and TimeManager:
        _modulate.color = TimeManager.tint_for(t)
