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
    # choices 있는 노드는 버튼 클릭만 받음 (잘못 진행되지 않게)
    if choices_container.get_child_count() > 0:
        return
    if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
        Dialogue.advance()
        get_viewport().set_input_as_handled()


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
        advance_hint.text = ""
        choices_container.visible = true
        for i in range(choices.size()):
            var btn := Button.new()
            btn.text = String(choices[i].get("text", "..."))
            var idx := i
            btn.pressed.connect(func() -> void: Dialogue.choose(idx))
            choices_container.add_child(btn)


func _on_dialogue_ended() -> void:
    panel.visible = false
    for child in choices_container.get_children():
        child.queue_free()
