extends Node
##
## WorldTint autoload — TimeManager 시간대에 따라 화면 색을 살짝 어둡게/푸르게.
##
## 직접 CanvasModulate 를 인스턴스해 SceneTree.root 에 붙이고, 매 time_changed 시
## TimeManager.tint_for(t) 결과로 color 를 갱신.
## CanvasModulate 는 한 캔버스(=Viewport)에 하나만 동작하므로 씬마다 따로 둘 필요 없음.
##

## 2026-07-10: 밤낮 순환 제거 — 시간에 따라 변하지 않고, 흐리고 비 오는 날의
## 침잠한 회청색 한 톤으로 전 화면을 눌러 어둡게 한다(너무 밝던 지면을 가라앉힘).
const OVERCAST := Color(0.40, 0.45, 0.55)

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
