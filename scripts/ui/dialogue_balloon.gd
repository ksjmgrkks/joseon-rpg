extends CanvasLayer
##
## 대화 UI — 화면 하단에 크게 깔리는 한국풍(한지·먹·단청) 대화창. Dialogue autoload 시그널에 반응.
## 몰입을 위해: 대화가 뜨면 (플레이어/HUD/터치버튼은 각자) 잠기고, 화면 아래를 넉넉히 채우는
## 큰 창 하나로 모든 대사를 보여준다. 머리 위 말풍선 대신 비주얼노벨식 하단 창.
##
## 세 가지 표현 모드 — 창은 하나로 두되 스킨만 바꾼다:
##  ① 말(SPEECH)     — 단청 적 이름패 + 먹빛 본문.
##  ② 혼잣말(THOUGHT) — 이름패에 '속마음', 본문은 기울임·푸른 먹빛(속내).
##  ③ 나레이션(NARRATION) — 화자 없음. 이름패 감추고 본문을 가운데·기울임(상황 서술).
##
## 프레임 배경은 PixelLab 한지 패널(있으면 나인패치)로, 없으면 코드 StyleBox 로 폴백 —
## 에셋이 없어도 항상 그럴듯한 한지·먹 창이 뜬다(web export/테스트 안전).
##
## 가독성: 본문 색은 모드별로 '일정'하게 고정. 「해원」 시그니처(기억이 지워질수록 글자가
## 흐려짐)는 진혼 직후 그 한 줄에만(JSON `"dissolve": true`) 켠다.
##

const REVEAL_CPS: float = 34.0          # 초당 드러나는 글자 수(타이핑 속도)
const FRAME_TEX_PATH := "res://assets/ui/hanji_dialogue_panel.png"

# 표현 모드
const MODE_SPEECH := 0
const MODE_THOUGHT := 1
const MODE_NARRATION := 2

# 한지·먹·단청 팔레트
const HANJI := Color(0.95, 0.92, 0.83)       # 한지 크림(폴백 배경)
const INK_BORDER := Color(0.16, 0.12, 0.09)  # 먹 테두리
const INK_TEXT := Color(0.13, 0.10, 0.07)    # 본문 먹빛(말)
const DANCHEONG := Color(0.60, 0.20, 0.16)   # 단청 적 — 이름패
const NAME_ON_RED := Color(0.97, 0.94, 0.86) # 이름패 위 글자(한지빛)
const HINT_COL := Color(0.40, 0.33, 0.26)
# 혼잣말(THOUGHT)
const THOUGHT_PLATE := Color(0.30, 0.34, 0.42)  # 청먹 이름패
const THOUGHT_TEXT := Color(0.22, 0.24, 0.31)   # 속내 글자
# 나레이션(NARRATION) — 살짝 어둑한 먹 창(상황 서술)
const NARR_TEXT := Color(0.20, 0.16, 0.12)

@onready var box: Control = $Box
@onready var bg_panel: Panel = $Box/BgPanel
@onready var frame: NinePatchRect = $Box/Frame
@onready var name_plate: PanelContainer = $Box/Content/VBox/NamePlate
@onready var speaker_label: Label = $Box/Content/VBox/NamePlate/NameMargin/SpeakerLabel
@onready var text_label: RichTextLabel = $Box/Content/VBox/TextLabel
@onready var choices_container: VBoxContainer = $Box/Content/VBox/ChoicesContainer
@onready var advance_hint: Label = $Box/AdvanceHint
@onready var tap_catcher: Button = $TapCatcher

var _mode: int = MODE_SPEECH
var _revealing: bool = false
var _reveal_tween: Tween = null
var _hint_tween: Tween = null

var _sb_bg: StyleBoxFlat
var _sb_plate_red: StyleBoxFlat
var _sb_plate_slate: StyleBoxFlat


func _ready() -> void:
    _build_styleboxes()
    _load_frame_texture()
    box.visible = false
    tap_catcher.visible = false
    set_process(false)
    tap_catcher.pressed.connect(_on_tap_advance)
    Dialogue.dialogue_started.connect(_on_dialogue_event)
    Dialogue.dialogue_advanced.connect(_on_dialogue_event)
    Dialogue.dialogue_ended.connect(_on_dialogue_ended)


func _build_styleboxes() -> void:
    # 폴백 배경(한지 창) — PixelLab 프레임이 없을 때만 보인다.
    _sb_bg = StyleBoxFlat.new()
    _sb_bg.bg_color = HANJI
    _sb_bg.border_color = INK_BORDER
    _sb_bg.set_border_width_all(3)
    _sb_bg.set_corner_radius_all(6)
    _sb_bg.shadow_color = Color(0, 0, 0, 0.35)
    _sb_bg.shadow_size = 8
    _sb_bg.shadow_offset = Vector2(0, 3)
    bg_panel.add_theme_stylebox_override("panel", _sb_bg)

    # 이름패 — 단청 적 / 청먹
    _sb_plate_red = StyleBoxFlat.new()
    _sb_plate_red.bg_color = DANCHEONG
    _sb_plate_red.border_color = Color(0.80, 0.66, 0.34)   # 금테
    _sb_plate_red.set_border_width_all(2)
    _sb_plate_red.set_corner_radius_all(4)

    _sb_plate_slate = StyleBoxFlat.new()
    _sb_plate_slate.bg_color = THOUGHT_PLATE
    _sb_plate_slate.border_color = Color(0.62, 0.66, 0.74)
    _sb_plate_slate.set_border_width_all(2)
    _sb_plate_slate.set_corner_radius_all(4)


## PixelLab 한지 프레임이 있으면 나인패치로 입힌다(가장자리 장식은 유지, 가운데만 늘림).
func _load_frame_texture() -> void:
    if ResourceLoader.exists(FRAME_TEX_PATH):
        var tex: Texture2D = load(FRAME_TEX_PATH)
        if tex != null:
            frame.texture = tex
            # 코너 단청 꽃장식(약 70px)이 잘리지 않게 넉넉히 — 가운데 한지만 늘어난다.
            var m := 72
            frame.patch_margin_left = m
            frame.patch_margin_top = m
            frame.patch_margin_right = m
            frame.patch_margin_bottom = m
            frame.visible = true
            bg_panel.visible = false
            return
    frame.visible = false
    bg_panel.visible = true


# ════════════ 입력 ════════════
func _unhandled_input(event: InputEvent) -> void:
    if not box.visible:
        return
    if choices_container.get_child_count() > 0:
        _handle_choice_input(event)
        return
    if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
        _advance_or_skip()
        get_viewport().set_input_as_handled()


func _on_tap_advance() -> void:
    if not box.visible:
        return
    if choices_container.get_child_count() > 0:
        return
    _advance_or_skip()


func _advance_or_skip() -> void:
    if _revealing:
        _finish_reveal()
    else:
        Dialogue.advance()


func _handle_choice_input(event: InputEvent) -> void:
    var n := choices_container.get_child_count()
    if n == 0:
        return
    if event is InputEventKey and event.pressed and not event.echo:
        var k := (event as InputEventKey).keycode
        if k >= KEY_1 and k <= KEY_9:
            var idx := k - KEY_1
            if idx < n:
                Dialogue.choose(idx)
                get_viewport().set_input_as_handled()
                return
    if event.is_action_pressed("ui_down") or event.is_action_pressed("move_right"):
        _move_focus(1); get_viewport().set_input_as_handled(); return
    if event.is_action_pressed("ui_up") or event.is_action_pressed("move_left"):
        _move_focus(-1); get_viewport().set_input_as_handled(); return
    if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
        var f := _focused_index()
        Dialogue.choose(f if f >= 0 else 0)
        get_viewport().set_input_as_handled()


func _focused_index() -> int:
    for i in range(choices_container.get_child_count()):
        if choices_container.get_child(i).has_focus():
            return i
    return -1


func _move_focus(step: int) -> void:
    var n := choices_container.get_child_count()
    if n == 0:
        return
    var cur := _focused_index()
    if cur < 0:
        cur = 0
    var nxt := (cur + step) % n
    if nxt < 0:
        nxt += n
    (choices_container.get_child(nxt) as Control).grab_focus()


# ════════════ 대사 표시 ════════════
func _on_dialogue_event(speaker: String, text: String, choices: Array) -> void:
    var first_open := not box.visible
    box.visible = true
    tap_catcher.visible = true

    _mode = _classify(speaker, text)
    _apply_mode_skin(_mode)

    # 이름패 — 말/혼잣말만 표시. 나레이션은 투명하게(자리는 남겨 본문이 위로 튀지 않게).
    if _mode == MODE_NARRATION:
        speaker_label.text = " "
        name_plate.modulate.a = 0.0
    else:
        var plate_name := speaker
        if _mode == MODE_THOUGHT:
            plate_name = _speaker_base(speaker) + " · 속마음"
        speaker_label.text = plate_name if plate_name.strip_edges() != "" else " "
        name_plate.modulate.a = 1.0 if plate_name.strip_edges() != "" else 0.0

    # 본문 — 혼잣말은 겉 괄호를 벗기고, 기억 소거(dissolve)면 그 줄만 흐린다.
    var do_dissolve := false
    if Dialogue:
        do_dissolve = Dialogue.meta("dissolve") == true
    var body := text
    if _mode == MODE_THOUGHT:
        body = _strip_parens(text)
    if do_dissolve and MemoryLedger:
        body = MemoryGlyph.dissolve(body, MemoryLedger.progress(), hash(speaker + text))
    elif _mode != MODE_SPEECH:
        body = "[i]%s[/i]" % body
    if _mode == MODE_NARRATION:
        body = "[center]%s[/center]" % body
    text_label.text = body

    # 선택지 구성
    for child in choices_container.get_children():
        child.queue_free()
    if choices.is_empty():
        choices_container.visible = false
        advance_hint.text = "▼ 탭"
    else:
        choices_container.visible = true
        advance_hint.text = "골라서 탭"
        for i in range(choices.size()):
            var btn := Button.new()
            btn.text = "%d.  %s" % [i + 1, String(choices[i].get("text", "..."))]
            btn.add_theme_font_size_override("font_size", 20)
            var idx := i
            btn.pressed.connect(func() -> void: Dialogue.choose(idx))
            choices_container.add_child(btn)
        var f := choices_container.get_child(0)
        if f is Control:
            (f as Control).call_deferred("grab_focus")

    _start_reveal(first_open)
    _start_hint_blink()


## 화자/본문으로 표현 모드를 가른다.
func _classify(speaker: String, text: String) -> int:
    if speaker.strip_edges() == "":
        return MODE_NARRATION
    if _is_inner_thought(speaker, text):
        return MODE_THOUGHT
    return MODE_SPEECH


func _is_inner_thought(speaker: String, text: String) -> bool:
    var base := _speaker_base(speaker)
    var is_player := base == "길손" or base.begins_with("길손") or base == "나"
    if not is_player:
        return false
    if speaker.find("독백") >= 0 or speaker.find("속으로") >= 0 or speaker.find("생각") >= 0:
        return true
    var t := text.strip_edges()
    return t.begins_with("(") and t.ends_with(")")


func _speaker_base(speaker: String) -> String:
    return speaker.split("(")[0].strip_edges()


func _strip_parens(text: String) -> String:
    var t := text.strip_edges()
    if t.length() >= 2 and t.begins_with("(") and t.ends_with(")"):
        return t.substr(1, t.length() - 2).strip_edges()
    return t


## 모드별 스킨 — 이름패 색/본문 글자색을 일정하게 적용.
func _apply_mode_skin(mode: int) -> void:
    match mode:
        MODE_THOUGHT:
            name_plate.add_theme_stylebox_override("panel", _sb_plate_slate)
            speaker_label.add_theme_color_override("font_color", NAME_ON_RED)
            text_label.add_theme_color_override("default_color", THOUGHT_TEXT)
            text_label.add_theme_color_override("font_default_color", THOUGHT_TEXT)
        MODE_NARRATION:
            text_label.add_theme_color_override("default_color", NARR_TEXT)
            text_label.add_theme_color_override("font_default_color", NARR_TEXT)
        _:
            name_plate.add_theme_stylebox_override("panel", _sb_plate_red)
            speaker_label.add_theme_color_override("font_color", NAME_ON_RED)
            text_label.add_theme_color_override("default_color", INK_TEXT)
            text_label.add_theme_color_override("font_default_color", INK_TEXT)
    advance_hint.add_theme_color_override("font_color", HINT_COL)


## 본문 글자를 좌→우로 드러내는 타이핑 연출. 창이 처음 뜰 땐 살짝 떠오르듯 페이드 인.
func _start_reveal(first_open: bool) -> void:
    if _reveal_tween and _reveal_tween.is_valid():
        _reveal_tween.kill()
    if first_open:
        box.modulate.a = 0.0
        var fade := box.create_tween()
        fade.tween_property(box, "modulate:a", 1.0, 0.16)
    else:
        box.modulate.a = 1.0
    var n := text_label.get_total_character_count()
    if n <= 0:
        text_label.visible_ratio = 1.0
        _revealing = false
        return
    text_label.visible_ratio = 0.0
    _revealing = true
    var dur := clampf(float(n) / REVEAL_CPS, 0.12, 3.0)
    _reveal_tween = create_tween()
    _reveal_tween.tween_property(text_label, "visible_ratio", 1.0, dur)
    _reveal_tween.tween_callback(_finish_reveal)


## 타이핑 완료(또는 스킵) — 본문 전체 표시.
func _finish_reveal() -> void:
    if _reveal_tween and _reveal_tween.is_valid():
        _reveal_tween.kill()
    _revealing = false
    text_label.visible_ratio = 1.0


## '▼ 탭' 진행 표시 — 은은하게 깜빡여 다음을 유도.
func _start_hint_blink() -> void:
    if _hint_tween and _hint_tween.is_valid():
        _hint_tween.kill()
    advance_hint.modulate.a = 1.0
    _hint_tween = create_tween().set_loops()
    _hint_tween.tween_property(advance_hint, "modulate:a", 0.25, 0.7)
    _hint_tween.tween_property(advance_hint, "modulate:a", 1.0, 0.7)


func _on_dialogue_ended() -> void:
    if _reveal_tween and _reveal_tween.is_valid():
        _reveal_tween.kill()
    if _hint_tween and _hint_tween.is_valid():
        _hint_tween.kill()
    _revealing = false
    box.visible = false
    tap_catcher.visible = false
    for child in choices_container.get_children():
        child.queue_free()
