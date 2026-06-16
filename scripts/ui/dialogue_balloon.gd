extends CanvasLayer
##
## 대화창 UI — Dialogue autoload 시그널에 반응해 표시/숨김.
## Phase 1: 기능 우선. 한지·먹 톤 스킨은 폰트 임포트 후(=주인공 스프라이트 확정 후) 다듬음.
##

@onready var panel: PanelContainer = $Panel
@onready var speaker_label: Label = $Panel/Margin/VBox/HBox/SpeakerLabel
@onready var text_label: RichTextLabel = $Panel/Margin/VBox/TextLabel
@onready var choices_container: VBoxContainer = $Panel/Margin/VBox/ChoicesContainer
@onready var advance_hint: Label = $Panel/Margin/VBox/HBox/AdvanceHint


func _ready() -> void:
    panel.visible = false
    Dialogue.dialogue_started.connect(_on_dialogue_event)
    Dialogue.dialogue_advanced.connect(_on_dialogue_event)
    Dialogue.dialogue_ended.connect(_on_dialogue_ended)


func _unhandled_input(event: InputEvent) -> void:
    if not panel.visible:
        return
    var n := choices_container.get_child_count()
    if n > 0:
        # 선택지 노드 — 키보드로도 고를 수 있게:
        #  · 숫자 1/2/3 = 해당 선택지 즉시 선택
        #  · ↑/↓ 로 포커스 이동, Space/Enter(interact) 로 확정
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
        return
    if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
        Dialogue.advance()
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


func _on_dialogue_event(speaker: String, text: String, choices: Array) -> void:
    panel.visible = true
    speaker_label.text = speaker
    text_label.text = text

    # 기존 선택 버튼 정리
    for child in choices_container.get_children():
        child.queue_free()

    if choices.is_empty():
        advance_hint.text = "[Space] 다음"
        choices_container.visible = false
    else:
        advance_hint.text = "[1~%d/↑↓] 선택  [Space] 확정" % choices.size()
        choices_container.visible = true
        for i in range(choices.size()):
            var btn := Button.new()
            btn.text = "%d. %s" % [i + 1, String(choices[i].get("text", "..."))]
            var idx := i
            btn.pressed.connect(func() -> void: Dialogue.choose(idx))
            choices_container.add_child(btn)
        # 첫 선택지에 포커스 — 키보드 즉시 조작 가능
        var first := choices_container.get_child(0)
        if first is Control:
            (first as Control).call_deferred("grab_focus")


func _on_dialogue_ended() -> void:
    panel.visible = false
    for child in choices_container.get_children():
        child.queue_free()
