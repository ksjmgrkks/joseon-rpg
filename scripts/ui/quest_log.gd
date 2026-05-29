extends CanvasLayer
##
## 퀘스트 로그 — 'quest_log' 액션(Q)으로 토글. 진행중 + 완료 목록 표시.
##

@onready var panel: PanelContainer = $Panel
@onready var active_list: VBoxContainer = $Panel/Margin/VBox/ScrollContainer/Lists/ActiveList
@onready var completed_list: VBoxContainer = $Panel/Margin/VBox/ScrollContainer/Lists/CompletedList
@onready var hint: Label = $Panel/Margin/VBox/Hint


func _ready() -> void:
    panel.visible = false
    QuestManager.quest_changed.connect(_on_quest_changed)


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("quest_log"):
        panel.visible = not panel.visible
        if panel.visible:
            _rebuild()
        get_viewport().set_input_as_handled()


func _on_quest_changed(_quest_id: String, _stage: String, _completed: bool) -> void:
    if panel.visible:
        _rebuild()


func _rebuild() -> void:
    for c in active_list.get_children():
        c.queue_free()
    for c in completed_list.get_children():
        c.queue_free()

    var actives := QuestManager.active_quests()
    if actives.is_empty():
        var l := Label.new()
        l.text = "(진행 중 없음)"
        l.modulate = Color(1, 1, 1, 0.6)
        active_list.add_child(l)
    else:
        for qid in actives:
            var qd := QuestManager.get_def(String(qid))
            var stage_id := String(actives[qid])
            var sd := QuestManager.get_stage_def(String(qid), stage_id)
            var name_label := Label.new()
            name_label.text = "● " + String(qd.get("name", qid))
            active_list.add_child(name_label)
            var stage_label := Label.new()
            stage_label.text = "    " + String(sd.get("title", stage_id))
            stage_label.modulate = Color(1, 1, 1, 0.85)
            active_list.add_child(stage_label)
            var desc_label := Label.new()
            desc_label.text = "    " + String(sd.get("description", ""))
            desc_label.modulate = Color(1, 1, 1, 0.55)
            desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            active_list.add_child(desc_label)
            var spacer := Control.new()
            spacer.custom_minimum_size = Vector2(0, 8)
            active_list.add_child(spacer)

    var completed := QuestManager.completed_quests()
    if completed.is_empty():
        var l := Label.new()
        l.text = "(완료된 퀘스트 없음)"
        l.modulate = Color(1, 1, 1, 0.4)
        completed_list.add_child(l)
    else:
        for qid in completed:
            var qd := QuestManager.get_def(String(qid))
            var lbl := Label.new()
            lbl.text = "✓ " + String(qd.get("name", qid))
            lbl.modulate = Color(0.8, 1.0, 0.85, 0.85)
            completed_list.add_child(lbl)

    hint.text = "[Q] 닫기"
