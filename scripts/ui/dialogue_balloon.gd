extends CanvasLayer
##
## 대화 UI — Dialogue autoload 시그널에 반응. 2026-08-20 개편: 머리 위로 떠다니던 말풍선을
## 화면 하단 고정 바(스테이지 선택 화면과 같은 PixelLab 목재 프레임 아트 재사용)로 옮기고,
## 주인공("길손")이 화자일 때는 화면 상단에 고퀄리티 초상화(사용자가 외부에서 만들어 온 것을
## assets/ui/portraits/protagonist/ 에 매팅해 넣음 — STYLE_BIBLE 픽셀아트 규칙의 의도적 예외,
## 자세한 사유는 docs/STYLE_BIBLE.md 끝부분 참고)를 띄운다. 세 가지 표현 모드는 유지:
##  ① 말(SPEECH)     — 하단 바 + (주인공이면) 상단 초상화.
##  ② 혼잣말(THOUGHT)  — 하단 바(살짝 다른 톤) + 기본 "생각하는" 표정 초상화.
##  ③ 나레이션(NARRATION) — 화자 없는 상황 설명. 여전히 화면 아래쪽 '수묵 자막 띠'로 깔려
##     누가 말하는 것처럼 보이지 않게 한다(몰입 보존) — 이 모드만 하단 바 아트를 쓰지 않음.
##
## 가독성: 본문 색은 모드별로 '일정'하게 고정한다. 「해원」 시그니처(기억이 지워질수록 글자가
## 흐려짐)는 **진혼 직후 그 한 줄에만**(JSON `"dissolve": true`) 켜 — 평소 대사는 또렷이 읽힌다.
##

const REVEAL_CPS: float = 34.0          # 초당 드러나는 글자 수(타이핑 속도)

# 표현 모드
const MODE_SPEECH := 0
const MODE_THOUGHT := 1
const MODE_NARRATION := 2

# 한지·먹 팔레트 — 말(SPEECH). 촌스럽지 않게: 맑은 한지 + 옅은 먹(움버) 테두리 + 금 실선 악센트.
const BG := Color(0.965, 0.945, 0.895, 0.965)  # 맑은 한지(살짝 투명)
const BORDER := Color(0.21, 0.16, 0.12)        # 옅은 먹(움버) — 순검정보다 부드럽게
const GOLD := Color(0.72, 0.58, 0.32)          # 금 실선 — 화자 구분선 악센트
const INK_TEXT := Color(0.17, 0.14, 0.11)      # 본문 먹빛
const SPEAKER_COL := Color(0.55, 0.24, 0.19)   # 단청 적(차분하게) — 화자명
const HINT_COL := Color(0.50, 0.44, 0.36)
# 혼잣말(THOUGHT) — 살짝 바랜 청먹 한지 + 푸른 먹빛 글자(속내)
const THOUGHT_BG := Color(0.905, 0.915, 0.94, 0.96)
const THOUGHT_BORDER := Color(0.34, 0.37, 0.44)
const THOUGHT_TEXT := Color(0.24, 0.27, 0.35)
# 나레이션(NARRATION) — 수묵 자막 띠: 어두운 반투명 + 한지빛 글자
const NARR_BG := Color(0.05, 0.05, 0.06, 0.72)
const NARR_TEXT := Color(0.92, 0.90, 0.83)
const NARR_HINT := Color(0.68, 0.65, 0.58)

const SPEECH_MIN_W := 236.0
const NARR_MIN_W := 460.0

const BAR_SIDE_MARGIN := 32.0    # 하단 바 좌우 여백
const BAR_HEIGHT := 158.0        # 하단 바 높이(말/혼잣말)
const NARR_HEIGHT := 90.0        # 나레이션 자막 띠 높이
const BAR_BOTTOM_GAP := 22.0     # 하단 바와 화면 바닥 사이 간격

const PORTRAIT_DIR := "res://assets/ui/portraits/protagonist/"
const PANEL_TEXTURE_PATH := "res://assets/ui/dialogue_panel.png"
const PANEL_MARGIN := 18         # dialogue_panel.png 프레임 두께(9-slice)

@onready var bubble: PanelContainer = $Bubble
@onready var portrait: TextureRect = $Portrait
@onready var tap_catcher: Button = $TapCatcher
@onready var speaker_label: Label = $Bubble/Margin/VBox/HBox/SpeakerLabel
@onready var rule: HSeparator = $Bubble/Margin/VBox/Rule
@onready var text_label: RichTextLabel = $Bubble/Margin/VBox/TextLabel
@onready var choices_container: VBoxContainer = $Bubble/Margin/VBox/ChoicesContainer
@onready var advance_hint: Label = $Bubble/Margin/VBox/HBox/AdvanceHint

var _mode: int = MODE_SPEECH
var _revealing: bool = false             # 본문이 좌→우로 타이핑되는 중
var _reveal_tween: Tween = null

var _sb_speech: StyleBox
var _sb_thought: StyleBox
var _sb_narration: StyleBoxFlat


func _ready() -> void:
    _build_styleboxes()
    bubble.visible = false
    portrait.visible = false
    tap_catcher.visible = false
    # 모바일 터치/마우스로 대화 넘기기 — 전체화면 투명 버튼(중복 입력 없이 1탭 1회).
    tap_catcher.pressed.connect(_on_tap_advance)
    Dialogue.dialogue_started.connect(_on_dialogue_event)
    Dialogue.dialogue_advanced.connect(_on_dialogue_event)
    Dialogue.dialogue_ended.connect(_on_dialogue_ended)


func _build_styleboxes() -> void:
    # 하단 바 — 스테이지 선택 화면과 같은 PixelLab 목재 프레임 아트(9-slice). 없으면(테스트
    # 환경 등) 예전 코드 StyleBox 로 안전하게 폴백.
    if ResourceLoader.exists(PANEL_TEXTURE_PATH):
        var tex := load(PANEL_TEXTURE_PATH)
        var sbt := StyleBoxTexture.new()
        sbt.texture = tex
        sbt.texture_margin_left = PANEL_MARGIN
        sbt.texture_margin_right = PANEL_MARGIN
        sbt.texture_margin_top = PANEL_MARGIN
        sbt.texture_margin_bottom = PANEL_MARGIN
        _sb_speech = sbt
        # 혼잣말 — 같은 프레임 아트에 살짝 청먹 틴트(패널 자체가 아니라 Bubble.modulate 로 입힘).
        _sb_thought = sbt
    else:
        _sb_speech = StyleBoxFlat.new()
        _sb_speech.bg_color = BG
        _sb_speech.border_color = BORDER
        _sb_speech.set_border_width_all(2)
        _sb_speech.set_corner_radius_all(11)
        _sb_speech.shadow_color = Color(0, 0, 0, 0.30)
        _sb_speech.shadow_size = 7
        _sb_speech.shadow_offset = Vector2(0, 4)

        _sb_thought = StyleBoxFlat.new()
        _sb_thought.bg_color = THOUGHT_BG
        _sb_thought.border_color = THOUGHT_BORDER
        _sb_thought.set_border_width_all(2)
        _sb_thought.set_corner_radius_all(16)   # 더 둥글게 — 생각 구름 느낌
        _sb_thought.shadow_color = Color(0, 0, 0, 0.22)
        _sb_thought.shadow_size = 6
        _sb_thought.shadow_offset = Vector2(0, 3)

    _sb_narration = StyleBoxFlat.new()
    _sb_narration.bg_color = NARR_BG
    _sb_narration.set_corner_radius_all(4)
    _sb_narration.set_content_margin_all(6)
    _sb_narration.set_border_width_all(0)

    # 화자 이름 아래 금빛 실선(SPEECH 전용) — 편집 디자인 느낌의 절제된 악센트.
    var sep := StyleBoxLine.new()
    sep.color = Color(GOLD.r, GOLD.g, GOLD.b, 0.55)
    sep.thickness = 1
    sep.grow_begin = 0.0
    sep.grow_end = 0.0
    rule.add_theme_stylebox_override("separator", sep)


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

    _mode = _classify(speaker, text)
    _apply_mode_skin(_mode)
    _update_portrait(speaker, _mode)
    _place_bar()

    speaker_label.text = speaker
    speaker_label.visible = _mode == MODE_SPEECH and speaker.strip_edges() != ""
    # 금빛 구분선은 화자 이름이 실제로 보일 때만(말풍선). 혼잣말/나레이션은 감춘다.
    rule.visible = speaker_label.visible

    # 본문 구성 — 혼잣말은 겉 괄호를 벗긴다.
    # 기억 소거(글자 흐려짐) 연출은 사용자 피드백(2026-07-11)으로 비활성:
    # 글자가 아예 안 보여 가독성이 떨어져, 대사는 항상 온전히 보이게 한다.
    # (기억 상실 서사는 대사 '내용'으로 전달. 다시 켜려면 아래 do_dissolve 배선 복구.)
    var body := text
    if _mode == MODE_THOUGHT:
        body = "[i]%s[/i]" % _strip_parens(text)
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


## 화자 이름(괄호 태그 제거)이 주인공("길손"/"나")인지.
func _is_player_speaker(speaker: String) -> bool:
    var base := speaker.split("(")[0].strip_edges()
    return base == "길손" or base.begins_with("길손") or base == "나"


## 주인공의 속내인가 — 화자가 길손이고 ①본문이 통째 괄호이거나 ②화자에 (독백)/(속으로)/(생각) 꼬리표.
## "길손(낮게)" 처럼 소리 내어 읊는 말은 제외(괄호 본문이 아님 → 말로 분류).
func _is_inner_thought(speaker: String, text: String) -> bool:
    if not _is_player_speaker(speaker):
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


## 화면 상단 주인공 초상화 — 화자가 주인공이고 나레이션이 아닐 때만 표시.
## 표정은 대화 노드의 "expression" 메타(JSON `"expression":"smirk"` 등)를 우선하고,
## 없으면 혼잣말은 "thinking", 그 외엔 "neutral" 로 기본값을 둔다.
func _update_portrait(speaker: String, mode: int) -> void:
    if mode == MODE_NARRATION or not _is_player_speaker(speaker):
        portrait.visible = false
        return
    var expr_meta: Variant = Dialogue.meta("expression")
    var expr: String = String(expr_meta) if expr_meta != null else ""
    if expr.is_empty():
        expr = "thinking" if mode == MODE_THOUGHT else "neutral"
    var path := "%s%s.png" % [PORTRAIT_DIR, expr]
    if not ResourceLoader.exists(path):
        path = "%sneutral.png" % PORTRAIT_DIR
    if not ResourceLoader.exists(path):
        portrait.visible = false
        return
    portrait.texture = load(path)
    portrait.visible = true


## 모드별 스킨(말풍선 배경·글자색·본문 폭·화자색)을 일정하게 적용.
func _apply_mode_skin(mode: int) -> void:
    match mode:
        MODE_THOUGHT:
            bubble.add_theme_stylebox_override("panel", _sb_thought)
            bubble.modulate = Color(0.86, 0.90, 1.0, 1.0)   # 살짝 청먹 틴트 — 속내임을 구분
            text_label.add_theme_color_override("default_color", THOUGHT_TEXT)
            advance_hint.add_theme_color_override("font_color", HINT_COL)
            text_label.custom_minimum_size = Vector2(SPEECH_MIN_W, 24)
        MODE_NARRATION:
            bubble.add_theme_stylebox_override("panel", _sb_narration)
            bubble.modulate = Color(1, 1, 1, 1)
            text_label.add_theme_color_override("default_color", NARR_TEXT)
            advance_hint.add_theme_color_override("font_color", NARR_HINT)
            text_label.custom_minimum_size = Vector2(NARR_MIN_W, 24)
        _:
            bubble.add_theme_stylebox_override("panel", _sb_speech)
            bubble.modulate = Color(1, 1, 1, 1)
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
    portrait.visible = false
    tap_catcher.visible = false
    for child in choices_container.get_children():
        child.queue_free()


# ════════════ 위치 ════════════
## 2026-08-20: 화자 머리 위로 떠다니던 배치를 버리고 고정 레이아웃으로 — 나레이션은 여전히
## 화면 아래쪽 자막 띠, 그 외(말/혼잣말)는 화면 하단 고정 바. 매 프레임 재계산할 이유가 없어
## _process 대신 표시 시점(_on_dialogue_event)에 한 번만 배치한다.
func _place_bar() -> void:
    var vp := get_viewport().get_visible_rect().size
    if _mode == MODE_NARRATION:
        var sz := Vector2(NARR_MIN_W, NARR_HEIGHT)
        bubble.size = sz
        bubble.position = Vector2((vp.x - sz.x) * 0.5, vp.y * 0.76 - sz.y)
    else:
        var bar_w := vp.x - BAR_SIDE_MARGIN * 2.0
        bubble.size = Vector2(bar_w, BAR_HEIGHT)
        bubble.position = Vector2(BAR_SIDE_MARGIN, vp.y - BAR_HEIGHT - BAR_BOTTOM_GAP)
