extends CanvasLayer
##
## 대화 말풍선 UI — Dialogue autoload 시그널에 반응. 세 가지 표현 모드:
##  ① 말(SPEECH)    — 화자 머리 위 한지 말풍선 + 뾰족한 꼬리. 글자는 좌→우 타이핑.
##  ② 혼잣말(THOUGHT) — 주인공의 속내(괄호 대사/독백). 말풍선 아래 '…' 점 3개로 생각임을 표시.
##  ③ 나레이션(NARRATION) — 화자 없는 상황 설명. 말풍선이 아니라 화면 아래 '수묵 자막 띠'로
##     깔려, 누가 말하는 것처럼 보이지 않게 한다(몰입 보존).
##
## 가독성: 본문 색은 모드별로 '일정'하게 고정한다. 「해원」 시그니처(기억이 지워질수록 글자가
## 흐려짐)는 **진혼 직후 그 한 줄에만**(JSON `"dissolve": true`) 켜 — 평소 대사는 또렷이 읽힌다.
## 한지·먹 톤은 코드 StyleBox 로 입혀 별도 에셋(PNG) 없이 web 에 바로 반영된다.
##

const REVEAL_CPS: float = 34.0          # 초당 드러나는 글자 수(타이핑 속도)
const TAIL_W: float = 16.0
const TAIL_H: float = 10.0
const HEAD_MARGIN: float = 10.0         # 꼬리 끝을 머리 꼭대기보다 살짝 안쪽으로
const THOUGHT_GAP: float = 26.0         # 혼잣말: 말풍선과 머리 사이 '…' 점 자리

# 표현 모드
const MODE_SPEECH := 0
const MODE_THOUGHT := 1
const MODE_NARRATION := 2

# 한지·먹 팔레트 — 말(SPEECH)
const BG := Color(0.96, 0.93, 0.85)        # 한지 크림
const BORDER := Color(0.17, 0.13, 0.10)    # 먹 테두리
const INK_TEXT := Color(0.15, 0.12, 0.09)  # 본문 먹빛
const SPEAKER_COL := Color(0.55, 0.20, 0.17)  # 단청 적 — 화자명
const HINT_COL := Color(0.45, 0.39, 0.32)
# 혼잣말(THOUGHT) — 살짝 바랜 한지 + 푸른 먹빛 글자(속내)
const THOUGHT_BG := Color(0.90, 0.91, 0.93)
const THOUGHT_BORDER := Color(0.36, 0.38, 0.44)
const THOUGHT_TEXT := Color(0.24, 0.26, 0.33)
# 나레이션(NARRATION) — 수묵 자막 띠: 어두운 반투명 + 한지빛 글자
const NARR_BG := Color(0.06, 0.06, 0.07, 0.76)
const NARR_TEXT := Color(0.91, 0.89, 0.82)
const NARR_HINT := Color(0.66, 0.63, 0.57)

const SPEECH_MIN_W := 236.0
const NARR_MIN_W := 460.0

@onready var bubble: PanelContainer = $Bubble
@onready var tail: Control = $Tail
@onready var tap_catcher: Button = $TapCatcher
@onready var speaker_label: Label = $Bubble/Margin/VBox/HBox/SpeakerLabel
@onready var text_label: RichTextLabel = $Bubble/Margin/VBox/TextLabel
@onready var choices_container: VBoxContainer = $Bubble/Margin/VBox/ChoicesContainer
@onready var advance_hint: Label = $Bubble/Margin/VBox/HBox/AdvanceHint

var _target: Node = null                 # 현재 화자 월드 노드(없으면 중앙 폴백)
var _mode: int = MODE_SPEECH
var _revealing: bool = false             # 본문이 좌→우로 타이핑되는 중
var _reveal_tween: Tween = null
var _thought_span: float = 18.0          # 혼잣말 점들이 내려갈 거리

var _sb_speech: StyleBoxFlat
var _sb_thought: StyleBoxFlat
var _sb_narration: StyleBoxFlat


func _ready() -> void:
    _build_styleboxes()
    bubble.visible = false
    tail.visible = false
    tap_catcher.visible = false
    set_process(false)
    tail.draw.connect(_draw_tail)
    # 모바일 터치/마우스로 대화 넘기기 — 전체화면 투명 버튼(중복 입력 없이 1탭 1회).
    tap_catcher.pressed.connect(_on_tap_advance)
    Dialogue.dialogue_started.connect(_on_dialogue_event)
    Dialogue.dialogue_advanced.connect(_on_dialogue_event)
    Dialogue.dialogue_ended.connect(_on_dialogue_ended)


func _build_styleboxes() -> void:
    _sb_speech = StyleBoxFlat.new()
    _sb_speech.bg_color = BG
    _sb_speech.border_color = BORDER
    _sb_speech.set_border_width_all(2)
    _sb_speech.set_corner_radius_all(7)
    _sb_speech.shadow_color = Color(0, 0, 0, 0.22)
    _sb_speech.shadow_size = 4
    _sb_speech.shadow_offset = Vector2(2, 3)

    _sb_thought = StyleBoxFlat.new()
    _sb_thought.bg_color = THOUGHT_BG
    _sb_thought.border_color = THOUGHT_BORDER
    _sb_thought.set_border_width_all(2)
    _sb_thought.set_corner_radius_all(13)   # 더 둥글게 — 생각 구름 느낌
    _sb_thought.shadow_color = Color(0, 0, 0, 0.16)
    _sb_thought.shadow_size = 3
    _sb_thought.shadow_offset = Vector2(1, 2)

    _sb_narration = StyleBoxFlat.new()
    _sb_narration.bg_color = NARR_BG
    _sb_narration.set_corner_radius_all(3)
    _sb_narration.set_content_margin_all(4)
    _sb_narration.set_border_width_all(0)


# ════════════ 입력 ════════════
func _unhandled_input(event: InputEvent) -> void:
    if not bubble.visible:
        return
    if choices_container.get_child_count() > 0:
        _handle_choice_input(event)
        return
    if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
        _advance_or_skip()
        get_viewport().set_input_as_handled()


## 화면 탭(모바일/마우스)으로 진행. 선택지가 있으면 탭으로 넘기지 않는다(버튼으로 고름).
func _on_tap_advance() -> void:
    if not bubble.visible:
        return
    if choices_container.get_child_count() > 0:
        return
    _advance_or_skip()


func _advance_or_skip() -> void:
    if _revealing:
        _finish_reveal()                     # 타이핑 중이면 먼저 즉시 완성(스킵)
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
    bubble.visible = true
    tap_catcher.visible = true
    set_process(true)

    _mode = _classify(speaker, text)
    _apply_mode_skin(_mode)
    _target = _resolve_speaker_node(speaker) if _mode != MODE_NARRATION else null

    speaker_label.text = speaker
    speaker_label.visible = _mode == MODE_SPEECH and speaker.strip_edges() != ""

    # 본문 구성 — 혼잣말은 겉 괄호를 벗기고, 기억 소거(dissolve) 표시가 있으면 그 줄만 흐린다.
    var do_dissolve := false
    if Dialogue:
        do_dissolve = Dialogue.meta("dissolve") == true
    var body := text
    if _mode == MODE_THOUGHT:
        body = _strip_parens(text)
    if do_dissolve and MemoryLedger:
        # 「해원」 시그니처: 진혼 직후 그 한 줄의 글자가 진행도만큼 흐려진다.
        body = MemoryGlyph.dissolve(body, MemoryLedger.progress(), hash(speaker + text))
    elif _mode == MODE_THOUGHT:
        body = "[i]%s[/i]" % body
    text_label.text = body

    # 선택지 즉시 구성(타이핑은 본문에만 적용 — 입력/테스트 즉시성 보장).
    for child in choices_container.get_children():
        child.queue_free()
    if choices.is_empty():
        choices_container.visible = false
        advance_hint.text = "탭 ▶"
    else:
        choices_container.visible = true
        advance_hint.text = "골라서 탭"
        for i in range(choices.size()):
            var btn := Button.new()
            btn.text = "%d. %s" % [i + 1, String(choices[i].get("text", "..."))]
            var idx := i
            btn.pressed.connect(func() -> void: Dialogue.choose(idx))
            choices_container.add_child(btn)
        var first := choices_container.get_child(0)
        if first is Control:
            (first as Control).call_deferred("grab_focus")

    _start_reveal()


## 화자/본문으로 표현 모드를 가른다.
func _classify(speaker: String, text: String) -> int:
    if speaker.strip_edges() == "":
        return MODE_NARRATION          # 화자 없음 = 상황 나레이션
    if _is_inner_thought(speaker, text):
        return MODE_THOUGHT
    return MODE_SPEECH


## 주인공의 속내인가 — 화자가 길손이고 ①본문이 통째 괄호이거나 ②화자에 (독백)/(속으로)/(생각) 꼬리표.
## "길손(낮게)" 처럼 소리 내어 읊는 말은 제외(괄호 본문이 아님 → 말로 분류).
func _is_inner_thought(speaker: String, text: String) -> bool:
    var base := speaker.split("(")[0].strip_edges()
    var is_player := base == "길손" or base.begins_with("길손") or base == "나"
    if not is_player:
        return false
    if speaker.find("독백") >= 0 or speaker.find("속으로") >= 0 or speaker.find("생각") >= 0:
        return true
    var t := text.strip_edges()
    return t.begins_with("(") and t.ends_with(")")


func _strip_parens(text: String) -> String:
    var t := text.strip_edges()
    if t.length() >= 2 and t.begins_with("(") and t.ends_with(")"):
        return t.substr(1, t.length() - 2).strip_edges()
    return t


## 모드별 스킨(말풍선 배경·글자색·본문 폭·화자색)을 일정하게 적용.
func _apply_mode_skin(mode: int) -> void:
    match mode:
        MODE_THOUGHT:
            bubble.add_theme_stylebox_override("panel", _sb_thought)
            text_label.add_theme_color_override("default_color", THOUGHT_TEXT)
            advance_hint.add_theme_color_override("font_color", HINT_COL)
            text_label.custom_minimum_size = Vector2(SPEECH_MIN_W, 24)
        MODE_NARRATION:
            bubble.add_theme_stylebox_override("panel", _sb_narration)
            text_label.add_theme_color_override("default_color", NARR_TEXT)
            advance_hint.add_theme_color_override("font_color", NARR_HINT)
            text_label.custom_minimum_size = Vector2(NARR_MIN_W, 24)
        _:
            bubble.add_theme_stylebox_override("panel", _sb_speech)
            text_label.add_theme_color_override("default_color", INK_TEXT)
            speaker_label.add_theme_color_override("font_color", SPEAKER_COL)
            advance_hint.add_theme_color_override("font_color", HINT_COL)
            text_label.custom_minimum_size = Vector2(SPEECH_MIN_W, 24)


## 본문 글자를 좌→우로 드러내는 타이핑 연출.
func _start_reveal() -> void:
    if _reveal_tween and _reveal_tween.is_valid():
        _reveal_tween.kill()
    # 말풍선 등장 — 살짝 떠오르듯 페이드 인
    bubble.modulate.a = 0.0
    var fade := bubble.create_tween()
    fade.tween_property(bubble, "modulate:a", 1.0, 0.12)
    var n := text_label.get_total_character_count()
    if n <= 0:
        text_label.visible_ratio = 1.0
        _revealing = false
        return
    text_label.visible_ratio = 0.0
    _revealing = true
    var dur := clampf(float(n) / REVEAL_CPS, 0.12, 2.6)
    _reveal_tween = create_tween()
    _reveal_tween.tween_property(text_label, "visible_ratio", 1.0, dur)
    _reveal_tween.tween_callback(_finish_reveal)


## 타이핑 완료(또는 스킵) — 본문 전체 표시.
func _finish_reveal() -> void:
    if _reveal_tween and _reveal_tween.is_valid():
        _reveal_tween.kill()
    _revealing = false
    text_label.visible_ratio = 1.0


func _on_dialogue_ended() -> void:
    if _reveal_tween and _reveal_tween.is_valid():
        _reveal_tween.kill()
    _revealing = false
    bubble.visible = false
    tail.visible = false
    tap_catcher.visible = false
    set_process(false)
    _target = null
    for child in choices_container.get_children():
        child.queue_free()


# ════════════ 위치 추적 ════════════
func _process(_delta: float) -> void:
    if not bubble.visible:
        return
    if _mode == MODE_NARRATION:
        _place_narration()
    elif _target != null and is_instance_valid(_target) and _target is Node2D:
        _place_above_target()
    else:
        _place_centered()


func _place_above_target() -> void:
    var node := _target as Node2D
    var ct := get_viewport().get_canvas_transform()
    var head_world := _head_world(node)          # 실제 스프라이트 머리 꼭대기(월드)
    var sp: Vector2 = ct * head_world            # 카메라 보정된 화면 좌표
    var sz := bubble.size
    var vp := get_viewport().get_visible_rect().size
    var tip := sp + Vector2(0, HEAD_MARGIN)
    var gap := TAIL_H if _mode == MODE_SPEECH else THOUGHT_GAP
    var x := clampf(tip.x - sz.x * 0.5, 8.0, maxf(8.0, vp.x - sz.x - 8.0))
    var y := clampf(tip.y - gap - sz.y, 8.0, maxf(8.0, vp.y - sz.y - 8.0))
    bubble.position = Vector2(x, y)
    var tip_x := clampf(tip.x, x + 12.0, x + sz.x - 12.0)
    if _mode == MODE_THOUGHT:
        # 말풍선 아래변에서 머리까지 '…' 점 3개(생각 표시).
        tail.position = Vector2(tip_x, y + sz.y)
        _thought_span = maxf(tip.y - (y + sz.y), 18.0)
    else:
        tail.position = Vector2(tip_x - TAIL_W * 0.5, y + sz.y)
    tail.visible = true
    tail.queue_redraw()


## 화자 스프라이트의 머리 꼭대기 월드 좌표(없으면 원점 기준 근사).
func _head_world(node: Node2D) -> Vector2:
    var spr := _find_sprite(node)
    if spr != null:
        var h := _sprite_frame_h(spr)
        if h > 0.0:
            var local_top := Vector2.ZERO
            if "offset" in spr:
                local_top = spr.offset
            var centered := true
            if "centered" in spr:
                centered = spr.centered
            if centered:
                local_top.y -= h * 0.5
            return spr.get_global_transform() * local_top
    return node.global_position + Vector2(0, _fallback_offset(node))


func _find_sprite(node: Node) -> Node2D:
    var v := node.get_node_or_null("Visual")
    if v is AnimatedSprite2D or v is Sprite2D:
        return v
    for c in node.get_children():
        if c is AnimatedSprite2D or c is Sprite2D:
            return c
    return null


func _sprite_frame_h(spr: Node2D) -> float:
    if spr is AnimatedSprite2D:
        var asp := spr as AnimatedSprite2D
        if asp.sprite_frames == null or not asp.sprite_frames.has_animation(asp.animation):
            return 0.0
        var tex := asp.sprite_frames.get_frame_texture(asp.animation, asp.frame)
        return float(tex.get_height()) if tex != null else 0.0
    if spr is Sprite2D:
        var ssp := spr as Sprite2D
        if ssp.texture == null:
            return 0.0
        return float(ssp.texture.get_height()) / float(maxi(1, ssp.vframes))
    return 0.0


## 나레이션 — 화면 아래쪽 가운데 '수묵 자막 띠'. 누가 말하는 게 아니라 상황을 깐다.
func _place_narration() -> void:
    var sz := bubble.size
    var vp := get_viewport().get_visible_rect().size
    bubble.position = Vector2((vp.x - sz.x) * 0.5, vp.y * 0.76 - sz.y)
    tail.visible = false


func _place_centered() -> void:
    var sz := bubble.size
    var vp := get_viewport().get_visible_rect().size
    bubble.position = Vector2((vp.x - sz.x) * 0.5, vp.y * 0.16)
    tail.visible = false


## 스프라이트를 못 찾았을 때의 머리 높이 근사(월드 기준, 음수=위).
func _fallback_offset(node: Node) -> float:
    if node.is_in_group("player"):
        return -74.0
    if node.is_in_group("enemy"):
        return -56.0
    return -64.0


func _draw_tail() -> void:
    if _mode == MODE_THOUGHT:
        _draw_thought_dots()
        return
    var pts := PackedVector2Array([
        Vector2(0, 0), Vector2(TAIL_W, 0), Vector2(TAIL_W * 0.5, TAIL_H)])
    tail.draw_colored_polygon(pts, BG)
    # 좌·우 테두리(윗변은 말풍선과 맞닿아 생략)
    tail.draw_line(Vector2(0, 0), Vector2(TAIL_W * 0.5, TAIL_H), BORDER, 2.0)
    tail.draw_line(Vector2(TAIL_W, 0), Vector2(TAIL_W * 0.5, TAIL_H), BORDER, 2.0)


## 혼잣말 표시 — 말풍선 아래로 내려가며 작아지는 점 3개(…).
func _draw_thought_dots() -> void:
    var span := _thought_span
    var ts := [0.16, 0.5, 0.84]
    var rs := [4.0, 3.0, 2.2]
    for i in range(3):
        var c := Vector2(0, span * ts[i])
        tail.draw_circle(c, rs[i], THOUGHT_BG)
        tail.draw_arc(c, rs[i], 0.0, TAU, 14, THOUGHT_BORDER, 1.5)


# ════════════ 화자 이름 → 월드 노드 매칭 ════════════
func _resolve_speaker_node(speaker: String) -> Node:
    var base := speaker.split("(")[0].strip_edges()
    if base == "":
        return null                          # 나레이션 — 자막 띠
    var player := get_tree().get_first_node_in_group("player")
    if player and (base == "길손" or base.begins_with("길손") or base == "나"):
        return player
    # NPC 대화는 트리거가 넘긴 상대 노드(말을 거는 그 NPC)가 곧 화자.
    var partner := Dialogue.partner_node()
    if partner != null and is_instance_valid(partner) and partner != player:
        return partner
    # 적/보스는 display_name 으로 매칭(전투 중 일갈 등).
    for n in get_tree().get_nodes_in_group("enemy"):
        if "display_name" in n:
            var dn := String(n.display_name)
            if dn != "" and (speaker.find(dn) >= 0 or dn.find(base) >= 0):
                return n
    return null
