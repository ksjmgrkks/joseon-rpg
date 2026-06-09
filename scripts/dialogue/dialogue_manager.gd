extends Node
##
## 대화 시스템 매니저 — autoload 'Dialogue'.
## JSON 데이터를 읽어 노드 순서를 진행하고, UI(DialogueBalloon)는 시그널로 갱신.
##
## JSON 스키마:
## {
##   "id": "...",
##   "start": "<노드 id>",
##   "nodes": {
##     "<id>": {
##       "speaker": "...",
##       "text": "...",
##       "actions": [                                # (선택) 노드 진입 시 실행
##         { "type": "set_flag", "key": "...", "value": ... },
##         ...
##       ],
##       "choices": [
##         { "text": "...", "next": "<id 또는 null>",
##           "if_flag": "<key>",                       # (선택) Flags.has_flag(key)일 때만 표시
##           "unless_flag": "<key>" }                  # (선택) Flags.has_flag(key) 아닐 때만
##       ]
##       또는 "next": "<id 또는 null>"
##     }, ...
##   }
## }
##

signal dialogue_started(speaker: String, text: String, choices: Array)
signal dialogue_advanced(speaker: String, text: String, choices: Array)
signal dialogue_ended()

var _data: Dictionary = {}
var _node_id: String = ""
var _active: bool = false


func is_active() -> bool:
    return _active


## 대화 시작. 성공하면 true.
func start(json_path: String) -> bool:
    if _active:
        push_warning("[Dialogue] already active, ignoring start: %s" % json_path)
        return false
    var file := FileAccess.open(json_path, FileAccess.READ)
    if file == null:
        push_error("[Dialogue] cannot open: %s" % json_path)
        return false
    var raw := file.get_as_text()
    file.close()
    var parsed = JSON.parse_string(raw)
    if not (parsed is Dictionary) or not parsed.has("nodes") or not parsed.has("start"):
        push_error("[Dialogue] invalid JSON format: %s" % json_path)
        return false
    _data = parsed
    _node_id = String(parsed.start)
    _active = true
    var node := _current_node()
    if node.is_empty():
        _end()
        return false
    _run_actions(node)
    var visible_choices := _filter_choices(node.get("choices", []))
    dialogue_started.emit(String(node.get("speaker", "")), String(node.get("text", "")), visible_choices)
    return true


## 분기 선택 (현재 노드의 '보이는' choices 인덱스 기준)
func choose(index: int) -> void:
    if not _active:
        return
    var node := _current_node()
    var visible := _filter_choices(node.get("choices", []))
    if index < 0 or index >= visible.size():
        push_warning("[Dialogue] choice index out of range: %d / %d" % [index, visible.size()])
        return
    _advance_to(visible[index].get("next", null))


## choices 없는 노드에서 다음으로 진행 (사용자가 진행 버튼 누름)
func advance() -> void:
    if not _active:
        return
    var node := _current_node()
    if node.has("choices") and (node.choices as Array).size() > 0:
        # choices 있는 노드는 선택만 가능
        return
    _advance_to(node.get("next", null))


func _current_node() -> Dictionary:
    if not _active or _data.is_empty():
        return {}
    var nodes: Dictionary = _data.get("nodes", {})
    var n = nodes.get(_node_id, null)
    return n if n is Dictionary else {}


func _advance_to(next_id: Variant) -> void:
    if next_id == null:
        _end()
        return
    _node_id = String(next_id)
    var node := _current_node()
    if node.is_empty():
        _end()
        return
    _run_actions(node)
    var visible_choices := _filter_choices(node.get("choices", []))
    dialogue_advanced.emit(String(node.get("speaker", "")), String(node.get("text", "")), visible_choices)


## 노드 진입 시 actions 배열을 순서대로 실행.
func _run_actions(node: Dictionary) -> void:
    var actions: Array = node.get("actions", [])
    for a in actions:
        if not (a is Dictionary):
            continue
        var t := String(a.get("type", ""))
        match t:
            "set_flag":
                Flags.set_flag(String(a.get("key", "")), a.get("value", true))
            "start_quest":
                QuestManager.start_quest(String(a.get("quest", "")))
            "set_quest_stage":
                QuestManager.set_stage(String(a.get("quest", "")), String(a.get("stage", "")))
            "complete_quest":
                QuestManager.complete_quest(String(a.get("quest", "")))
            "give_item":
                Inventory.add(String(a.get("item", "")), int(a.get("count", 1)))
            "take_item":
                Inventory.remove(String(a.get("item", "")), int(a.get("count", 1)))
            "open_shop":
                var items: Array = a.get("items", [])
                var stitle := String(a.get("title", "상점"))
                if ShopPanel:
                    ShopPanel.open(items, stitle)
            _:
                push_warning("[Dialogue] unknown action type: %s" % t)


## 조건(if_flag / unless_flag / 퀘스트)에 맞는 choice만 추림.
func _filter_choices(choices: Array) -> Array:
    var out: Array = []
    for c in choices:
        if not (c is Dictionary):
            continue
        if c.has("if_flag") and not Flags.has_flag(String(c.if_flag)):
            continue
        if c.has("unless_flag") and Flags.has_flag(String(c.unless_flag)):
            continue
        if c.has("if_quest_active") and not QuestManager.is_active(String(c.if_quest_active)):
            continue
        if c.has("if_quest_completed") and not QuestManager.is_completed(String(c.if_quest_completed)):
            continue
        if c.has("if_quest_stage"):
            var parts := String(c.if_quest_stage).split(":")
            if parts.size() != 2 or not QuestManager.is_stage(parts[0], parts[1]):
                continue
        if c.has("if_inventory_at_least"):
            # "id:N"  →  Inventory.count(id) >= N
            var inv := String(c.if_inventory_at_least).split(":")
            if inv.size() != 2 or Inventory.count(inv[0]) < int(inv[1]):
                continue
        if c.has("if_has_item"):
            if Inventory.count(String(c.if_has_item)) <= 0:
                continue
        out.append(c)
    return out


func _end() -> void:
    _active = false
    _data = {}
    _node_id = ""
    dialogue_ended.emit()
