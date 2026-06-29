extends CanvasLayer
##
## 대화 말풍선 UI — Dialogue autoload 시그널에 반응.
## ① 화자 머리 위에 말풍선이 뜨고(화자 노드를 매 프레임 추적),
## ② 대사 글자가 좌→우로 타이핑되듯 드러난다(AI 답변 스트리밍 느낌).
## ③ 화자 노드를 못 찾는 나레이션/넋은 화면 상단 중앙 박스로 폴백.
## 한지·먹 톤은 코드 StyleBox 로 입혀 별도 에셋(PNG) 없이 web 에 바로 반영된다.
##

const REVEAL_CPS: float = 34.0          # 초당 드러나는 글자 수(타이핑 속도)
const TAIL_W: float = 16.0
const TAIL_H: float = 10.0
const GAP_ABOVE: float = 12.0           # 머리 위 말풍선 간격(꼬리 높이 포함)

# 한지·먹 팔레트
const BG := Color(0.96, 0.93, 0.85)        # 한지 크림
const BORDER := Color(0.17, 0.13, 0.10)    # 먹 테두리
const INK_TEXT := Color(0.15, 0.12, 0.09)  # 본문 먹빛
const SPEAKER_COL := Color(0.55, 0.20, 0.17)  # 단청 적 — 화자명
const HINT_COL := Color(0.45, 0.39, 0.32)

@onready var bubble: PanelContainer = $Bubble
@onready var tail: Control = $Tail
@onready var speaker_label: Label = $Bubble/Margin/VBox/HBox/SpeakerLabel
@onready var text_label: RichTextLabel = $Bubble/Margin/VBox/TextLabel
@onready var choices_container: VBoxContainer = $Bubble/Margin/VBox/ChoicesContainer
@onready var advance_hint: Label = $Bubble/Margin/VBox/HBox/AdvanceHint

var _target: Node = null                 # 현재 화자 월드 노드(없으면 중앙 폴백)
var _revealing: bool = false             # 본문이 좌→우로 타이핑되는 중
var _reveal_tween: Tween = null


func _ready() -> void:
    _apply_skin()
    bubble.visible = false
    tail.visible = false
    set_process(false)
    tail.draw.connect(_draw_tail)
    Dialogue.dialogue_started.connect(_on_dialogue_event)
    Dialogue.dialogue_advanced.connect(_on_dialogue_event)
    Dialogue.dialogue_ended.connect(_on_dialogue_ended)


func _apply_skin() -> void:
    var sb := StyleBoxFlat.new()
    sb.bg_color = BG
    sb.border_color = BORDER
    sb.set_border_width_all(2)
    sb.set_corner_radius_all(7)
    sb.shadow_color = Color(0, 0, 0, 0.22)
    sb.shadow_size = 4
    sb.shadow_offset = Vector2(2, 3)
    bubble.add_theme_stylebox_override("panel", sb)
    speaker_label.add_theme_color_override("font_color", SPEAKER_COL)
    text_label.add_theme_color_override("default_color", INK_TEXT)
    advance_hint.add_theme_color_override("font_color", HINT_COL)


# ════════════ 입력 ════════════
func _unhandled_input(event: InputEvent) -> void:
    if not bubble.visible:
        return
    if choices_container.get_child_count() > 0:
        _handle_choice_input(event)
        return
    if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
        if _revealing:
            _finish_reveal()                 # 타이핑 중이면 먼저 즉시 완성(스킵)
        else:
            Dialogue.advance()
        get_viewport().set_input_as_handled()


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
    set_process(true)
    _target = _resolve_speaker_node(speaker)

    speaker_label.text = speaker
    speaker_label.visible = speaker.strip_edges() != ""

    # 「해원」 시그니처: 기억이 지워질수록 글자도 흐려진다(진행도 비례, seed 고정).
    var ratio := MemoryLedger.progress() if MemoryLedger else 0.0
    text_label.text = MemoryGlyph.dissolve(text, ratio, hash(speaker + text))

    # 선택지 즉시 구성(타이핑은 본문에만 적용 — 입력/테스트 즉시성 보장).
    for child in choices_container.get_children():
        child.queue_free()
    if choices.is_empty():
        choices_container.visible = false
        advance_hint.text = "[Space] 다음"
    else:
        choices_container.visible = true
        advance_hint.text = "[1~%d/↑↓] 선택" % choices.size()
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
    set_process(false)
    _target = null
    for child in choices_container.get_children():
        child.queue_free()


# ════════════ 위치 추적 ════════════
func _process(_delta: float) -> void:
    if not bubble.visible:
        return
    if _target != null and is_instance_valid(_target) and _target is Node2D:
        _place_above_target()
    else:
        _place_centered()


func _place_above_target() -> void:
    var node := _target as Node2D
    var ct := get_viewport().get_canvas_transform()
    var world_head := node.global_position + Vector2(0, _head_offset(node))
    var sp: Vector2 = ct * world_head            # 카메라 보정된 화면 좌표
    var sz := bubble.size
    var vp := get_viewport().get_visible_rect().size
    var x := clampf(sp.x - sz.x * 0.5, 8.0, maxf(8.0, vp.x - sz.x - 8.0))
    var y := clampf(sp.y - sz.y - GAP_ABOVE, 8.0, maxf(8.0, vp.y - sz.y - 8.0))
    bubble.position = Vector2(x, y)
    # 꼬리 — 말풍선 아래변에서 화자 쪽(sp.x)을 가리킨다.
    var tip_x := clampf(sp.x, x + 12.0, x + sz.x - 12.0)
    tail.position = Vector2(tip_x - TAIL_W * 0.5, y + sz.y - 1.0)
    tail.visible = true
    tail.queue_redraw()


func _place_centered() -> void:
    var sz := bubble.size
    var vp := get_viewport().get_visible_rect().size
    bubble.position = Vector2((vp.x - sz.x) * 0.5, vp.y * 0.16)
    tail.visible = false


## 화자 머리 위 오프셋(월드 기준, 음수=위).
func _head_offset(node: Node) -> float:
    if node.is_in_group("player"):
        return -54.0
    if node.is_in_group("enemy"):
        return -48.0
    return -52.0


func _draw_tail() -> void:
    var pts := PackedVector2Array([
        Vector2(0, 0), Vector2(TAIL_W, 0), Vector2(TAIL_W * 0.5, TAIL_H)])
    tail.draw_colored_polygon(pts, BG)
    # 좌·우 테두리(윗변은 말풍선과 맞닿아 생략)
    tail.draw_line(Vector2(0, 0), Vector2(TAIL_W * 0.5, TAIL_H), BORDER, 2.0)
    tail.draw_line(Vector2(TAIL_W, 0), Vector2(TAIL_W * 0.5, TAIL_H), BORDER, 2.0)


# ════════════ 화자 이름 → 월드 노드 매칭 ════════════
func _resolve_speaker_node(speaker: String) -> Node:
    var base := speaker.split("(")[0].strip_edges()
    if base == "":
        return null                          # 나레이션 — 중앙 박스
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
