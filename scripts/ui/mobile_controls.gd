extends CanvasLayer
##
## 모바일 터치 컨트롤 — 데스크탑(키보드+마우스)에선 자동 숨김, 터치 가능 기기/모바일 OS에서만 표시.
## 사용처: 일단 TestLevel에 인스턴스로 넣고, 실서비스에서는 autoload로 승격하는 것도 가능.
##

var _is_touch: bool = false


func _ready() -> void:
    _is_touch = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("web")
    visible = _is_touch
    # 대화 중엔 터치 버튼을 숨겨 하단 대화창과 겹치지 않고 몰입을 지킨다.
    Dialogue.dialogue_started.connect(func(_s, _t, _c) -> void: visible = false)
    Dialogue.dialogue_ended.connect(func() -> void: visible = _is_touch)
