extends Control
##
## 스테이지 선택 화면 — 각 던전의 분위기를 한눈에 비교하는 가로 컨셉 카드 갤러리.
## 카드 배경은 PixelLab Pro 컨셉 아트, 제목·설명은 런타임 텍스트라 번역/해상도에 안전하다.
##

signal stage_chosen(scene_path: String)
signal cancelled

const STAGES := [
    {
        "chapter_key": "stageselect.stage1.chapter",
        "name_key": "stageselect.stage1.name",
        "desc_key": "stageselect.stage1.desc",
        "boss_key": "stageselect.stage1.boss",
        "scene": "res://scenes/levels/Foothills.tscn",
        "art": "res://assets/ui/stage_cards/stage1_flooded_valley.png",
        "crop_left": 1,
        "crop_right": 1,
        "accent": Color(0.38, 0.60, 0.66),
        "wash": Color(0.12, 0.19, 0.21),
    },
    {
        "chapter_key": "stageselect.stage2.chapter",
        "name_key": "stageselect.stage2.name",
        "desc_key": "stageselect.stage2.desc",
        "boss_key": "stageselect.stage2.boss",
        "scene": "res://scenes/levels/ForestShadow.tscn",
        "art": "res://assets/ui/stage_cards/stage2_geuseondae_forest.png",
        "crop_left": 10,
        "crop_right": 1,
        "accent": Color(0.37, 0.48, 0.42),
        "wash": Color(0.10, 0.14, 0.13),
    },
    {
        "chapter_key": "stageselect.stage3.chapter",
        "name_key": "stageselect.stage3.name",
        "desc_key": "stageselect.stage3.desc",
        "boss_key": "stageselect.stage3.boss",
        "scene": "res://scenes/levels/MarketRuins.tscn",
        "art": "res://assets/ui/stage_cards/stage3_ruined_market.png",
        "crop_left": 1,
        "crop_right": 1,
        "accent": Color(0.68, 0.45, 0.25),
        "wash": Color(0.20, 0.12, 0.08),
    },
    {
        "chapter_key": "stageselect.stage4.chapter",
        "name_key": "stageselect.stage4.name",
        "desc_key": "stageselect.stage4.desc",
        "boss_key": "stageselect.stage4.boss",
        "scene": "res://scenes/levels/FuneralPass.tscn",
        "art": "res://assets/ui/stage_cards/stage4_funeral_pass.png",
        "crop_left": 0,
        "crop_right": 0,
        "accent": Color(0.58, 0.68, 0.78),
        "wash": Color(0.075, 0.09, 0.13),
    },
]

@onready var window_frame: TextureRect = $WindowFrame
@onready var title_label: Label = $Margin/VBox/Title
@onready var lead_label: Label = $Margin/VBox/Lead
@onready var hint_label: Label = $Margin/VBox/Hint
@onready var cards_root: HBoxContainer = $Margin/VBox/Cards
@onready var back_btn: Button = $Margin/VBox/BackBtn


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    if window_frame and ResourceLoader.exists("res://assets/ui/stage_select_window.png"):
        window_frame.texture = load("res://assets/ui/stage_select_window.png")
    title_label.text = Locale.t("stageselect.title")
    lead_label.text = Locale.t("stageselect.lead")
    hint_label.text = Locale.t("stageselect.hint")
    back_btn.text = Locale.t("stageselect.back")
    back_btn.pressed.connect(_on_back)
    _build_cards()


func _build_cards() -> void:
    for c in cards_root.get_children():
        c.queue_free()
    var first_card: Button = null
    for stage in STAGES:
        var card := _make_card(stage)
        cards_root.add_child(card)
        if first_card == null:
            first_card = card
    if first_card != null:
        first_card.call_deferred("grab_focus")


func _make_card(stage: Dictionary) -> Button:
    var btn := Button.new()
    btn.text = ""
    btn.custom_minimum_size = Vector2(0, 380)
    btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
    btn.focus_mode = Control.FOCUS_ALL
    btn.clip_contents = true
    btn.tooltip_text = "%s — %s" % [
        Locale.t(String(stage.get("name_key", ""))),
        Locale.t(String(stage.get("boss_key", ""))),
    ]
    var accent: Color = stage.get("accent", Color(0.65, 0.52, 0.28))
    var wash: Color = stage.get("wash", Color(0.12, 0.10, 0.08))
    btn.add_theme_stylebox_override("normal", _card_style(wash, accent, 2, false))
    btn.add_theme_stylebox_override("hover", _card_style(wash.lightened(0.08), accent.lightened(0.22), 3, true))
    btn.add_theme_stylebox_override("focus", _card_style(wash.lightened(0.06), Color(0.88, 0.72, 0.38), 3, true))
    btn.add_theme_stylebox_override("pressed", _card_style(wash.lightened(0.12), Color(0.95, 0.80, 0.48), 4, false))
    btn.mouse_entered.connect(func() -> void: _animate_card(btn, true))
    btn.mouse_exited.connect(func() -> void: _animate_card(btn, false))
    btn.focus_entered.connect(func() -> void: _animate_card(btn, true))
    btn.focus_exited.connect(func() -> void: _animate_card(btn, false))
    btn.resized.connect(func() -> void: btn.pivot_offset = btn.size * 0.5)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_top", 11)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_bottom", 10)
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    btn.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 6)
    column.mouse_filter = Control.MOUSE_FILTER_IGNORE
    margin.add_child(column)

    var chapter := _label(Locale.t(String(stage.get("chapter_key", ""))), 14, accent.lightened(0.35))
    chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    column.add_child(chapter)

    var art_frame := PanelContainer.new()
    art_frame.custom_minimum_size = Vector2(0, 218)
    art_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
    art_frame.add_theme_stylebox_override("panel", _art_style(accent))
    art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    column.add_child(art_frame)
    var art_path := String(stage.get("art", ""))
    if ResourceLoader.exists(art_path):
        var art := TextureRect.new()
        var source := load(art_path) as Texture2D
        var crop_left := int(stage.get("crop_left", 0))
        var crop_right := int(stage.get("crop_right", 0))
        if source != null and crop_left + crop_right > 0:
            var cropped := AtlasTexture.new()
            cropped.atlas = source
            cropped.region = Rect2(
                crop_left,
                0,
                source.get_width() - crop_left - crop_right,
                source.get_height()
            )
            art.texture = cropped
        else:
            art.texture = source
        art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        art.mouse_filter = Control.MOUSE_FILTER_IGNORE
        art_frame.add_child(art)
    else:
        var fallback := ColorRect.new()
        fallback.color = wash.lightened(0.12)
        fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
        art_frame.add_child(fallback)

    var name_label := _label(Locale.t(String(stage.get("name_key", ""))), 23, Color(0.93, 0.88, 0.75))
    column.add_child(name_label)
    var desc_label := _label(Locale.t(String(stage.get("desc_key", ""))), 14, Color(0.75, 0.72, 0.64))
    desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc_label.custom_minimum_size.y = 36
    column.add_child(desc_label)
    var boss_label := _label(Locale.t(String(stage.get("boss_key", ""))), 13, accent.lightened(0.36))
    column.add_child(boss_label)
    var enter_label := _label(Locale.t("stageselect.enter"), 13, Color(0.84, 0.70, 0.40))
    enter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    column.add_child(enter_label)

    btn.pressed.connect(func() -> void: _on_pick(String(stage.get("scene", ""))))
    return btn


func _label(text_value: String, size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_outline_color", Color(0.025, 0.022, 0.018, 0.96))
    label.add_theme_constant_override("outline_size", 3)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return label


func _card_style(bg: Color, border: Color, width: int, raised: bool) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = bg
    box.border_color = border
    box.set_border_width_all(width)
    box.set_corner_radius_all(5)
    box.shadow_color = Color(0.01, 0.008, 0.006, 0.72)
    box.shadow_size = 8 if raised else 5
    box.shadow_offset = Vector2(0, 4)
    return box


func _art_style(accent: Color) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = Color(0.035, 0.032, 0.028)
    box.border_color = Color(accent.r, accent.g, accent.b, 0.72)
    box.set_border_width_all(1)
    box.set_corner_radius_all(3)
    return box


func _animate_card(card: Control, raised: bool) -> void:
    if not is_instance_valid(card):
        return
    card.z_index = 4 if raised else 0
    var tween := card.create_tween().set_parallel()
    tween.tween_property(card, "scale", Vector2(1.018, 1.018) if raised else Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(card, "modulate", Color(1.08, 1.06, 1.02) if raised else Color.WHITE, 0.12)


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
