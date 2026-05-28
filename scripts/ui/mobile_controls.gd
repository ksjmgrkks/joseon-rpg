extends CanvasLayer
##
## 모바일 터치 컨트롤 — 데스크탑(키보드+마우스)에선 자동 숨김, 터치 가능 기기/모바일 OS에서만 표시.
## 사용처: 일단 TestLevel에 인스턴스로 넣고, 실서비스에서는 autoload로 승격하는 것도 가능.
##

func _ready() -> void:
    var is_touch := DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("web")
    visible = is_touch
