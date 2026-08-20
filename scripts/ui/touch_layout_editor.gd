extends Control
##
## 터치 버튼 위치 편집기 — 설정 → "터치 버튼 위치 조정"에서 진입.
## 실제 MobileControls 를 임시로 띄워 현재(기본 또는 커스텀) 배치·모양을 그대로 읽어와
## 드래그 가능한 핸들로 복제한다. [저장]을 눌러야 [[TouchLayoutConfig]] 에 반영되고,
## [뒤로]는 드래그만 하고 저장하지 않은 변경을 버린다.
##

const MOBILE_SCENE := "res://scenes/ui/MobileControls.tscn"
const SETTINGS_PATH := "res://scenes/ui/SettingsMenu.tscn"
const HANDLE_SCRIPT := preload("res://scripts/ui/touch_layout_handle.gd")

@onready var hint_label: Label = $Margin/VBox/Hint
@onready var status_label: Label = $Margin/VBox/Status
@onready var save_btn: Button = $Margin/VBox/Buttons/SaveBtn
@onready var reset_btn: Button = $Margin/VBox/Buttons/ResetBtn
@onready var back_btn: Button = $Margin/VBox/Buttons/BackBtn
@onready var handle_layer: Control = $HandleLayer

var _handles: Dictionary = {}   # action(String) -> TouchLayoutHandle
var _origin := Vector2.ZERO
var _size := Vector2.ZERO


func _ready() -> void:
    hint_label.text = "버튼을 드래그해서 위치를 조정하세요"
    save_btn.pressed.connect(_on_save)
    reset_btn.pressed.connect(_on_reset)
    back_btn.pressed.connect(_on_back)
    _build_handles()


## 실제 MobileControls 를 잠깐 띄워 지금 배치(기본 또는 이미 저장된 커스텀)와
## 버튼 텍스처를 그대로 복제해온다 — 편집기에서도 실제와 똑같이 보이게.
func _build_handles() -> void:
    for c in handle_layer.get_children():
        c.queue_free()
    _handles.clear()

    var mc: CanvasLayer = load(MOBILE_SCENE).instantiate()
    add_child(mc)
    await get_tree().process_frame

    _origin = mc.get("_layout_origin")
    _size = mc.get("_layout_size")
    var clamp_rect := Rect2(_origin, _size)

    for b in mc.get_children():
        if b is TouchScreenButton:
            var btn := b as TouchScreenButton
            var radius: float = btn.get_meta("radius", 40.0)
            var center: Vector2 = btn.position + Vector2(radius, radius)
            _make_handle(String(btn.action), center, radius, btn.texture_normal, clamp_rect)

    mc.queue_free()


func _make_handle(action: String, center: Vector2, radius: float, tex: Texture2D, clamp_rect: Rect2) -> void:
    var h := TextureRect.new()
    h.set_script(HANDLE_SCRIPT)
    h.action = action
    h.radius = radius
    h.texture = tex
    h.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    h.size = Vector2(radius * 2.0, radius * 2.0)
    h.position = center - Vector2(radius, radius)
    h.mouse_filter = Control.MOUSE_FILTER_STOP
    h.clamp_rect = clamp_rect
    h.moved.connect(_on_handle_moved)
    handle_layer.add_child(h)
    _handles[action] = h

    var lbl := Label.new()
    lbl.text = action
    lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
    lbl.add_theme_font_size_override("font_size", 12)
    lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
    lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
    lbl.add_theme_constant_override("outline_size", 3)
    h.add_child(lbl)


func _on_handle_moved(_action: String, _center: Vector2) -> void:
    status_label.text = "드래그 중 — [저장]을 눌러야 반영됩니다"


func _on_save() -> void:
    for action in _handles:
        var h: TouchLayoutHandle = _handles[action]
        var center: Vector2 = h.position + Vector2(h.radius, h.radius)
        TouchLayoutConfig.set_position(action, center, _origin, _size)
    TouchLayoutConfig.commit()
    status_label.text = "저장됨"


func _on_reset() -> void:
    TouchLayoutConfig.reset_all()
    status_label.text = "기본값으로 초기화됨"
    _build_handles()


func _on_back() -> void:
    SceneManager.change_scene(SETTINGS_PATH)
