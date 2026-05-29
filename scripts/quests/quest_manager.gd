extends Node
##
## QuestManager autoload — 퀘스트 진행 상태 관리.
##
## 데이터: assets/quests/quests.json
##   { "quests": {
##       "<quest_id>": {
##         "name": "...", "description": "...",
##         "stages": { "<stage_id>": { "title": "...", "description": "..." }, ... },
##         "rewards": { "items": [ { "id": "...", "count": N }, ... ] }   # (선택)
##       }, ... } }
##
## 상태:
##   active: { quest_id -> current_stage_id }
##   completed: [quest_id, ...]
##
## SaveManager 연동. 시그널: quest_changed(quest_id, current_stage, is_completed).
##

signal quest_changed(quest_id: String, current_stage: String, is_completed: bool)

const QUESTS_PATH := "res://assets/quests/quests.json"

var _defs: Dictionary = {}                    # quest_id -> def
var _active: Dictionary = {}                  # quest_id -> stage_id
var _completed: Array = []                    # quest_id 목록


func _ready() -> void:
    _load_defs()
    SaveManager.save_requested.connect(_on_save)
    SaveManager.loaded.connect(_on_load)


func _load_defs() -> void:
    var f := FileAccess.open(QUESTS_PATH, FileAccess.READ)
    if f == null:
        push_error("[Quests] cannot open: %s" % QUESTS_PATH)
        return
    var raw := f.get_as_text()
    f.close()
    var data = JSON.parse_string(raw)
    if not (data is Dictionary):
        return
    _defs = data.get("quests", {})


func get_def(quest_id: String) -> Dictionary:
    var d = _defs.get(quest_id, {})
    return d if d is Dictionary else {}


func get_stage_def(quest_id: String, stage_id: String) -> Dictionary:
    var qd := get_def(quest_id)
    if qd.is_empty():
        return {}
    var stages: Dictionary = qd.get("stages", {})
    var sd = stages.get(stage_id, {})
    return sd if sd is Dictionary else {}


## "start" stage로 시작. 이미 active/completed면 무시.
func start_quest(quest_id: String) -> bool:
    if _active.has(quest_id) or _completed.has(quest_id):
        return false
    var qd := get_def(quest_id)
    if qd.is_empty():
        push_warning("[Quests] unknown quest: %s" % quest_id)
        return false
    _active[quest_id] = "start"
    quest_changed.emit(quest_id, "start", false)
    return true


## 임의 stage로 전환.
func set_stage(quest_id: String, stage_id: String) -> bool:
    if not _active.has(quest_id):
        return false
    if get_stage_def(quest_id, stage_id).is_empty():
        push_warning("[Quests] unknown stage: %s / %s" % [quest_id, stage_id])
        return false
    _active[quest_id] = stage_id
    quest_changed.emit(quest_id, stage_id, false)
    return true


## 퀘스트 완료. rewards.items 가 있으면 Inventory.add 호출.
func complete_quest(quest_id: String) -> bool:
    if not _active.has(quest_id):
        return false
    var stage := String(_active[quest_id])
    _active.erase(quest_id)
    if not _completed.has(quest_id):
        _completed.append(quest_id)
    # 보상 지급
    var qd := get_def(quest_id)
    var rewards: Dictionary = qd.get("rewards", {})
    var items: Array = rewards.get("items", [])
    for r in items:
        if r is Dictionary:
            Inventory.add(String(r.get("id", "")), int(r.get("count", 1)))
    quest_changed.emit(quest_id, stage, true)
    return true


func is_active(quest_id: String) -> bool:
    return _active.has(quest_id)


func is_completed(quest_id: String) -> bool:
    return _completed.has(quest_id)


func is_stage(quest_id: String, stage_id: String) -> bool:
    return _active.has(quest_id) and String(_active[quest_id]) == stage_id


func active_quests() -> Dictionary:
    return _active.duplicate(true)


func completed_quests() -> Array:
    return _completed.duplicate(true)


func clear() -> void:
    _active.clear()
    _completed.clear()


func _on_save(_slot: int, data: Dictionary) -> void:
    data["quests"] = {
        "active": _active.duplicate(true),
        "completed": _completed.duplicate(true),
    }


func _on_load(_slot: int, data: Dictionary) -> void:
    var q: Dictionary = data.get("quests", {})
    _active = q.get("active", {})
    _completed = q.get("completed", [])
    for qid in _active:
        quest_changed.emit(String(qid), String(_active[qid]), false)
