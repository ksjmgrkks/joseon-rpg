extends TextureRect
class_name TouchLayoutHandle
##
## 터치 버튼 위치 편집기(TouchLayoutEditor)에서 쓰는 드래그 가능한 버튼 표시.
## 실제 게임 입력에는 관여하지 않는다 — 화면 위 위치만 드래그로 옮긴다.
##

signal moved(action: String, center: Vector2)

var action: String = ""
var radius: float = 40.0
## 크기 배율(1.0=기본) — +/- 로 조정. pivot_offset 을 중심에 둬서 커져도 중심이 안 밀린다.
var scale_mult: float = 1.0
## 드래그 가능 범위(사용영역, 부모 로컬 좌표). ZERO 면 제한 없음.
var clamp_rect: Rect2 = Rect2()


## pivot_offset 이 텍스처 중심(=radius,radius)에 있으므로 scale 을 걸어도 중심 좌표
## (position + radius,radius) 는 그대로다 — 커진 만큼만 사방으로 자란다.
func set_scale_mult(s: float) -> void:
    scale_mult = clampf(s, TouchLayoutConfig.MIN_SCALE, TouchLayoutConfig.MAX_SCALE)
    scale = Vector2.ONE * scale_mult
    moved.emit(action, position + Vector2(radius, radius))

var _dragging := false
## 손가락(마우스)이 처음 눌린 지점 - 그 순간 버튼 position 의 차이.
## 매 이벤트마다 절대 위치에서 이 차이를 빼서 위치를 정한다 — event.relative 를
## 그대로 누적하면(구 방식) 웹/터치에서 한 프레임에 이벤트가 여러 번 들어올 때
## 델타가 중복 반영돼 "통통 튀는" 느낌이 났다. 절대좌표 기준이라 그 문제가 없다.
var _grab_offset := Vector2.ZERO


func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var t := event as InputEventScreenTouch
        _dragging = t.pressed
        if _dragging:
            _grab_offset = t.position - position
        accept_event()
    elif event is InputEventMouseButton:
        var m := event as InputEventMouseButton
        if m.button_index == MOUSE_BUTTON_LEFT:
            _dragging = m.pressed
            if _dragging:
                _grab_offset = m.position - position
            accept_event()
    elif _dragging and (event is InputEventScreenDrag or event is InputEventMouseMotion):
        position = event.position - _grab_offset
        _clamp()
        moved.emit(action, position + Vector2(radius, radius))
        accept_event()


## 중심점(position + radius,radius) 기준으로 clamp — 커진 버튼도 실제 그려지는
## 가장자리(radius*scale_mult)가 사용영역을 벗어나지 않게 한다.
func _clamp() -> void:
    if clamp_rect.size == Vector2.ZERO:
        return
    var eff_r := radius * scale_mult
    var min_c := clamp_rect.position + Vector2(eff_r, eff_r)
    var max_c := clamp_rect.position + clamp_rect.size - Vector2(eff_r, eff_r)
    var center := position + Vector2(radius, radius)
    center.x = clampf(center.x, minf(min_c.x, max_c.x), maxf(min_c.x, max_c.x))
    center.y = clampf(center.y, minf(min_c.y, max_c.y), maxf(min_c.y, max_c.y))
    position = center - Vector2(radius, radius)
