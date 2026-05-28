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
##       "choices": [ { "text": "...", "next": "<id 또는 null>" }, ... ]   # 분기형
##       또는 "next": "<id 또는 null>"                                       # 단순 진행
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
    var choices: Array = node.get("choices", [])
    dialogue_started.emit(String(node.get("speaker", "")), String(node.get("text", "")), choices)
    return true


## 분기 선택 (choices 인덱스 기준)
func choose(index: int) -> void:
    if not _active:
        return
    var node := _current_node()
    var choices: Array = node.get("choices", [])
    if index < 0 or index >= choices.size():
        push_warning("[Dialogue] choice index out of range: %d / %d" % [index, choices.size()])
        return
    _advance_to(choices[index].get("next", null))


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
    var choices: Array = node.get("choices", [])
    dialogue_advanced.emit(String(node.get("speaker", "")), String(node.get("text", "")), choices)


func _end() -> void:
    _active = false
    _data = {}
    _node_id = ""
    dialogue_ended.emit()
