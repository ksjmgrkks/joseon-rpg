extends Control
##
## 「해원」 엔딩 — 「빈 강」. 동튼 강 위에 떠가는 물등들. 글자 없는 고요.
##  · 마지막 굽이(윤슬 천도) 후 도달. 사이드 진혼/단서 발견 수에 따라 등불 개수·마지막 한 줄 변주.
##  · 전부 코드 드로잉 + 물등 스프라이트 — 셰이더/외부 에셋 추가 import 불필요(웹 빌드에 바로 보임).
##

const MENU := "res://scenes/ui/MainMenu.tscn"
const FIRST := "res://scenes/levels/Haewon0Prologue.tscn"
const LANTERN_TEX := "res://assets/tilesets/mul_deung.png"

var _t := 0.0
var _horizon := 0.62          # 화면 높이 대비 지평선 비율
var _lanterns: Array = []     # {spr, speed, phase, base_y}
var _line: Label
var _buttons: VBoxContainer


func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    resized.connect(queue_redraw)

    # 발견한 단서(통문·비녀) 수 → 정성의 척도. 등불 개수·마지막 한 줄 변주.
    var found := 0
    if Flags.has_flag("haewon_tongmun_found"):
        found += 1
    if Flags.has_flag("haewon_yunseul_token_found"):
        found += 1
    var lantern_count := 3 + found    # 3~5

    var tex: Texture2D = load(LANTERN_TEX) if ResourceLoader.exists(LANTERN_TEX) else null
    var vp := get_viewport_rect().size
    for i in lantern_count:
        var spr := Sprite2D.new()
        if tex != null:
            spr.texture = tex
            spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            spr.scale = Vector2(0.45, 0.45)
        spr.modulate = Color(1.0, 0.95, 0.82, 0.96)
        var base_y := vp.y * (0.66 + 0.06 * float(i % 3))
        spr.position = Vector2(vp.x * (0.12 + 0.2 * i), base_y)
        add_child(spr)
        _lanterns.append({"spr": spr, "speed": 14.0 + 5.0 * (i % 3), "phase": float(i) * 1.3, "base_y": base_y})

    # 마지막 한 줄(고요 뒤 천천히 떠오름)
    _line = Label.new()
    _line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _line.set_anchors_preset(Control.PRESET_CENTER)
    _line.anchor_left = 0.5; _line.anchor_right = 0.5; _line.anchor_top = 0.5; _line.anchor_bottom = 0.5
    _line.offset_left = -360; _line.offset_right = 360; _line.offset_top = -40; _line.offset_bottom = 20
    _line.add_theme_color_override("font_color", Color(0.28, 0.24, 0.20))
    _line.add_theme_font_size_override("font_size", 22)
    _line.text = _closing_line(found)
    _line.modulate = Color(1, 1, 1, 0)
    add_child(_line)

    _buttons = _build_buttons()
    add_child(_buttons)
    _buttons.modulate = Color(1, 1, 1, 0)

    # 완급: 한참 고요 → 마지막 줄 → 버튼.
    await get_tree().create_timer(3.0).timeout
    create_tween().tween_property(_line, "modulate:a", 1.0, 2.0)
    await get_tree().create_timer(3.0).timeout
    var tw := create_tween()
    tw.tween_property(_buttons, "modulate:a", 1.0, 1.2)
    tw.tween_callback(_focus_first_button)


func _focus_first_button() -> void:
    if _buttons.get_child_count() > 0:
        var b := _buttons.get_child(0)
        if b is Control:
            (b as Control).grab_focus()


func _process(delta: float) -> void:
    _t += delta
    var w := size.x if size.x > 0 else get_viewport_rect().size.x
    for L in _lanterns:
        var spr: Sprite2D = L["spr"]
        spr.position.x += L["speed"] * delta
        spr.position.y = L["base_y"] + sin(_t * 0.8 + L["phase"]) * 4.0
        if spr.position.x > w + 60.0:
            spr.position.x = -60.0


func _closing_line(found: int) -> String:
    match found:
        2: return "강은 다시 고요하다. 물비늘마다, 잊어버린 이름들이 잠깐씩 반짝였다."
        1: return "강은 다시 고요하다. 등불 몇이 천천히 멀어진다."
        _: return "강은 다시 고요하다."


func _build_buttons() -> VBoxContainer:
    var box := VBoxContainer.new()
    box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    box.anchor_left = 0.5; box.anchor_right = 0.5; box.anchor_top = 1.0; box.anchor_bottom = 1.0
    box.offset_left = -120; box.offset_right = 120; box.offset_top = -150; box.offset_bottom = -40
    box.add_theme_constant_override("separation", 12)
    var menu_btn := Button.new()
    menu_btn.text = "처음으로"
    menu_btn.custom_minimum_size = Vector2(240, 48)
    menu_btn.pressed.connect(_on_menu)
    box.add_child(menu_btn)
    return box


func _on_menu() -> void:
    Flags.clear()
    Inventory.clear()
    if Equipment:
        Equipment.clear()
    PlayerStats.reset()
    if SkillManager:
        SkillManager.reset_cooldowns()
    if MemoryLedger:
        MemoryLedger.reset()
    SceneManager.change_scene(MENU)


func _draw() -> void:
    var s := size
    if s.x <= 0.0 or s.y <= 0.0:
        s = get_viewport_rect().size
    var horizon_y := s.y * _horizon
    # 하늘: 상단 옅은 금 → 지평선 따뜻한 살구 (동틀녘)
    var top := Color(0.86, 0.80, 0.62)
    var horizon := Color(0.95, 0.83, 0.61)
    var bands := 24
    for i in bands:
        var t := float(i) / float(bands)
        draw_rect(Rect2(0, horizon_y * t, s.x, horizon_y / float(bands) + 1.0), top.lerp(horizon, t))
    # 강: 지평선 살구빛 반영 → 아래로 식는 물빛
    var river_top := Color(0.88, 0.80, 0.66)
    var river_bot := Color(0.50, 0.55, 0.58)
    var rb := 18
    for i in rb:
        var t := float(i) / float(rb)
        draw_rect(Rect2(0, horizon_y + (s.y - horizon_y) * t, s.x, (s.y - horizon_y) / float(rb) + 1.0),
            river_top.lerp(river_bot, t))
    # 첫 햇살 — 지평선에 가로 금빛 띠 ('그 빛이 곧 윤슬')
    draw_rect(Rect2(0, horizon_y - 3.0, s.x, 6.0), Color(1.0, 0.93, 0.72, 0.85))
