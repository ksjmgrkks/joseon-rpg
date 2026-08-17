extends Node
##
## ScreenFit autoload — 화면비 방어.
##
## `stretch/aspect = expand` 는 가로로 긴 폰(19.5:9)에서 레터박스를 없애 주지만,
## **세로로 든 폰/브라우저**에서는 뷰포트가 위아래로 한없이 길어져 하늘만 보이는
## 이상한 화면이 된다(웹은 `handheld/orientation` 이 안 먹는다 — 브라우저 창을 따라간다).
##
## 그래서 창 비율이 가로로 충분할 때만 expand 를 쓰고, 세로로 길면 keep(레터박스)로
## 되돌린 뒤 "가로로 돌려 주십시오" 안내를 띄운다.
##

## 이보다 세로로 길면 레터박스 + 안내. (16:9=1.78, 4:3=1.33)
const MIN_ASPECT := 1.25

var _hint_layer: CanvasLayer = null
var _hint_label: Label = null


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_hint()
    var root := get_tree().root
    root.size_changed.connect(_apply)
    _apply()


func _apply() -> void:
    var win := get_window()
    if win == null:
        return
    var s := Vector2(win.size)
    if s.x <= 0.0 or s.y <= 0.0:
        return
    var aspect := s.x / s.y
    var portrait := aspect < MIN_ASPECT
    win.content_scale_aspect = (Window.CONTENT_SCALE_ASPECT_KEEP if portrait
        else Window.CONTENT_SCALE_ASPECT_EXPAND)
    if _hint_layer:
        _hint_layer.visible = portrait and _is_handheld()


func _is_handheld() -> bool:
    return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("web")


## 세로일 때 뜨는 안내 — 먹빛 장막 위 한지빛 사극체 한 줄.
func _build_hint() -> void:
    _hint_layer = CanvasLayer.new()
    _hint_layer.layer = 100
    _hint_layer.visible = false
    add_child(_hint_layer)

    var veil := ColorRect.new()
    veil.color = Color(0.06, 0.05, 0.05, 0.88)
    veil.set_anchors_preset(Control.PRESET_FULL_RECT)
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _hint_layer.add_child(veil)

    _hint_label = Label.new()
    _hint_label.text = "휴대폰을 가로로 돌려 주십시오"
    _hint_label.set_anchors_preset(Control.PRESET_FULL_RECT)
    _hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _hint_label.add_theme_font_size_override("font_size", 28)
    _hint_label.add_theme_color_override("font_color", Color(0.93, 0.90, 0.82))
    _hint_layer.add_child(_hint_label)
