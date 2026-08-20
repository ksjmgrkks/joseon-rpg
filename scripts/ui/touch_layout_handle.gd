extends TextureRect
class_name TouchLayoutHandle
##
## 터치 버튼 위치 편집기(TouchLayoutEditor)에서 쓰는 드래그 가능한 버튼 표시.
## 실제 게임 입력에는 관여하지 않는다 — 화면 위 위치만 드래그로 옮긴다.
##

signal moved(action: String, center: Vector2)

var action: String = ""
var radius: float = 40.0
## 드래그 가능 범위(사용영역, 부모 로컬 좌표). ZERO 면 제한 없음.
var clamp_rect: Rect2 = Rect2()

var _dragging := false


func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var t := event as InputEventScreenTouch
        _dragging = t.pressed
        accept_event()
    elif event is InputEventMouseButton:
        var m := event as InputEventMouseButton
        if m.button_index == MOUSE_BUTTON_LEFT:
            _dragging = m.pressed
            accept_event()
    elif _dragging and (event is InputEventScreenDrag or event is InputEventMouseMotion):
        var rel: Vector2 = event.relative
        position += rel
        _clamp()
        moved.emit(action, position + Vector2(radius, radius))
        accept_event()


func _clamp() -> void:
    if clamp_rect.size == Vector2.ZERO:
        return
    position.x = clampf(position.x, clamp_rect.position.x, clamp_rect.position.x + clamp_rect.size.x - size.x)
    position.y = clampf(position.y, clamp_rect.position.y, clamp_rect.position.y + clamp_rect.size.y - size.y)
