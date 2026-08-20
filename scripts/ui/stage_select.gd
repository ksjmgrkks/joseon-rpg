extends Control
##
## 스테이지 선택 화면 — 메인 메뉴 "새로 시작"에서 진입.
## 완성된 전투체인 스테이지(1~3) 중 하나를 골라 그 스테이지의 첫 굽이부터 새 런으로 시작한다.
##
## 카드 배경/버튼판은 PixelLab 생성 아트(assets/ui/stage_select_window.png, stage_select_button.png).
##

signal stage_chosen(scene_path: String)
signal cancelled

const STAGES := [
    {"name_key": "stageselect.stage1.name", "desc_key": "stageselect.stage1.desc", "scene": "res://scenes/levels/Foothills.tscn", "tint": Color(0.72, 0.82, 0.95)},
    {"name_key": "stageselect.stage2.name", "desc_key": "stageselect.stage2.desc", "scene": "res://scenes/levels/ForestShadow.tscn", "tint": Color(0.74, 0.9, 0.72)},
    {"name_key": "stageselect.stage3.name", "desc_key": "stageselect.stage3.desc", "scene": "res://scenes/levels/MarketRuins.tscn", "tint": Color(0.95, 0.78, 0.6)},
]

@onready var window_frame: TextureRect = $WindowFrame
@onready var title_label: Label = $Margin/VBox/Title
@onready var hint_label: Label = $Margin/VBox/Hint
@onready var cards_root: VBoxContainer = $Margin/VBox/Cards
@onready var back_btn: Button = $Margin/VBox/BackBtn


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    if window_frame and ResourceLoader.exists("res://assets/ui/stage_select_window.png"):
        window_frame.texture = load("res://assets/ui/stage_select_window.png")
    title_label.text = Locale.t("stageselect.title")
    hint_label.text = Locale.t("stageselect.hint")
    back_btn.text = Locale.t("stageselect.back")
    back_btn.pressed.connect(_on_back)
    _build_cards()
    back_btn.call_deferred("grab_focus")


func _build_cards() -> void:
    for c in cards_root.get_children():
        c.queue_free()
    for stage in STAGES:
        cards_root.add_child(_make_card(stage))


func _make_card(stage: Dictionary) -> Control:
    var btn := TextureButton.new()
    if ResourceLoader.exists("res://assets/ui/stage_select_button.png"):
        btn.texture_normal = load("res://assets/ui/stage_select_button.png")
    btn.ignore_texture_size = true
    btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
    btn.custom_minimum_size = Vector2(0, 96)
    btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    btn.modulate = stage.get("tint", Color.WHITE)
    btn.mouse_entered.connect(func() -> void: btn.modulate = Color(1.15, 1.15, 1.15) * stage.get("tint", Color.WHITE))
    btn.mouse_exited.connect(func() -> void: btn.modulate = stage.get("tint", Color.WHITE))

    var label_box := VBoxContainer.new()
    label_box.set_anchors_preset(Control.PRESET_FULL_RECT)
    label_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label_box.alignment = BoxContainer.ALIGNMENT_CENTER

    var name_label := Label.new()
    name_label.text = Locale.t(String(stage.get("name_key", "")))
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_label.add_theme_font_size_override("font_size", 22)
    name_label.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08))

    var desc_label := Label.new()
    desc_label.text = Locale.t(String(stage.get("desc_key", "")))
    desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    desc_label.add_theme_font_size_override("font_size", 14)
    desc_label.add_theme_color_override("font_color", Color(0.25, 0.2, 0.15, 0.85))

    label_box.add_child(name_label)
    label_box.add_child(desc_label)
    btn.add_child(label_box)

    btn.pressed.connect(func() -> void: _on_pick(String(stage.get("scene", ""))))
    return btn


func _on_pick(scene_path: String) -> void:
    if scene_path.is_empty():
        return
    stage_chosen.emit(scene_path)


func _on_back() -> void:
    cancelled.emit()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        cancelled.emit()
        get_viewport().set_input_as_handled()
