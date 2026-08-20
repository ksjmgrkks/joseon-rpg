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
## ⚠ 모바일 웹(특히 iOS Safari)에서는 회전 도중 `size_changed` 가 과도기 크기로 한 번만
## 오고 안정된 뒤엔 다시 안 오는 경우가 있어, 세로→가로로 되돌려도 안내가 안 사라지는
## 버그가 있었다(2026-08-20 사용자 리포트). 그래서 신호 하나만 믿지 않고 ①디바운스 재검사
## ②저빈도 폴링 ③안내 탭 시 즉시 재검사, 3중으로 방어한다.
##

## 이보다 세로로 길면 레터박스 + 안내. (16:9=1.78, 4:3=1.33)
const MIN_ASPECT := 1.25
## size_changed 직후 과도기 크기를 걸러내기 위한 디바운스 재검사 지연.
const RECHECK_DELAY := 0.2
## size_changed 가 누락되는 경우의 안전망 — 이 주기로 무조건 재확인.
const POLL_INTERVAL := 0.5

var _hint_layer: CanvasLayer = null
var _hint_label: Label = null
var _recheck_timer: Timer = null
var _poll_timer: Timer = null


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_hint()
    _build_timers()
    var root := get_tree().root
    root.size_changed.connect(_on_resize)
    _apply()


func _build_timers() -> void:
    _recheck_timer = Timer.new()
    _recheck_timer.one_shot = true
    _recheck_timer.wait_time = RECHECK_DELAY
    _recheck_timer.process_mode = Node.PROCESS_MODE_ALWAYS
    _recheck_timer.timeout.connect(func() -> void: _apply())
    add_child(_recheck_timer)

    # size_changed 가 안 와도(브라우저 회전 이벤트 유실) 결국은 맞는 상태로 수렴하도록.
    _poll_timer = Timer.new()
    _poll_timer.one_shot = false
    _poll_timer.wait_time = POLL_INTERVAL
    _poll_timer.process_mode = Node.PROCESS_MODE_ALWAYS
    _poll_timer.timeout.connect(func() -> void: _apply())
    add_child(_poll_timer)
    _poll_timer.start()


## size_changed 콜백 — 즉시 한 번 반영하고, 과도기 크기였을 경우를 대비해
## 잠시 뒤 다시 한 번 재확인한다(반복 호출돼도 타이머는 재시작만 될 뿐 쌓이지 않는다).
func _on_resize() -> void:
    _apply()
    _recheck_timer.start()


## 안내가 떠 있는데 실제로는 이미 가로라면(자동 감지가 놓친 경우) 화면을 탭해서
## 바로 재확인할 수 있게 하는 수동 안전망.
func _on_hint_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch or event is InputEventMouseButton:
        if event.pressed:
            _apply()


## size_override/handheld_override 를 주면 실제 창·기기 판정을 건드리지 않고
## 판정 로직만 검증할 수 있다(헤드리스 테스트용 — 실제 호출은 둘 다 기본값으로 둔다).
func _apply(size_override: Vector2 = Vector2.ZERO, handheld_override: Variant = null) -> void:
    var s := size_override
    if s.x <= 0.0 or s.y <= 0.0:
        var win := get_window()
        if win == null:
            return
        s = Vector2(win.size)
        if s.x <= 0.0 or s.y <= 0.0:
            return
    var aspect := s.x / s.y
    var portrait := aspect < MIN_ASPECT
    if size_override == Vector2.ZERO:
        var win2 := get_window()
        if win2:
            win2.content_scale_aspect = (Window.CONTENT_SCALE_ASPECT_KEEP if portrait
                else Window.CONTENT_SCALE_ASPECT_EXPAND)
    if _hint_layer:
        var handheld: bool = handheld_override if handheld_override != null else _is_handheld()
        _hint_layer.visible = portrait and handheld


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
    # STOP(무시가 아님) — 탭하면 즉시 재검사해서, 자동 감지가 놓쳐 안내가 안 사라질 때
    # 사용자가 직접 풀 수 있는 수동 안전망이 된다.
    veil.mouse_filter = Control.MOUSE_FILTER_STOP
    veil.gui_input.connect(_on_hint_input)
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
