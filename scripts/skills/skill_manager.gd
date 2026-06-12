extends Node
##
## SkillManager autoload — 스킬 정의(assets/data/skills.json)·해금·쿨다운 관리.
##
## 해금 조건: {"type":"level","value":N} → PlayerStats.level >= N
##           {"type":"flag","value":"키"} → Flags.has_flag(키)
## 쿨다운은 휘발(저장 안 함) — 해금 상태는 레벨/플래그에서 파생되므로 별도 저장 불필요.
##
## 시그널: skill_cast(id), cooldowns_changed (HUD 갱신용)
##

signal skill_cast(id: String)
signal cooldowns_changed

const SKILLS_PATH := "res://assets/data/skills.json"

var _defs: Dictionary = {}
var _cooldowns: Dictionary = {}   # id -> 남은 초


func _ready() -> void:
    var f := FileAccess.open(SKILLS_PATH, FileAccess.READ)
    if f == null:
        push_error("[Skills] cannot open: %s" % SKILLS_PATH)
        return
    var parsed = JSON.parse_string(f.get_as_text())
    f.close()
    if parsed is Dictionary:
        _defs = parsed.get("skills", {})


func _process(delta: float) -> void:
    if _cooldowns.is_empty():
        return
    var dirty := false
    for id in _cooldowns.keys():
        _cooldowns[id] = maxf(0.0, _cooldowns[id] - delta)
        if _cooldowns[id] <= 0.0:
            _cooldowns.erase(id)
        dirty = true
    if dirty:
        cooldowns_changed.emit()


func get_def(id: String) -> Dictionary:
    var d = _defs.get(id, {})
    return d if d is Dictionary else {}


func all_ids() -> Array:
    var ids := _defs.keys()
    ids.sort_custom(func(a, b): return int(get_def(a).get("slot", 9)) < int(get_def(b).get("slot", 9)))
    return ids


func is_unlocked(id: String) -> bool:
    var unlock: Dictionary = get_def(id).get("unlock", {})
    match String(unlock.get("type", "")):
        "level":
            return PlayerStats.level >= int(unlock.get("value", 99))
        "flag":
            return Flags.has_flag(String(unlock.get("value", "")))
    return false


func cooldown_left(id: String) -> float:
    return float(_cooldowns.get(id, 0.0))


func is_ready(id: String) -> bool:
    return is_unlocked(id) and cooldown_left(id) <= 0.0


## 발동 시도 — 가능하면 쿨다운 시작 + skill_cast 발사 후 true.
## 실제 효과(돌진/타격/보호막)는 player.gd 가 skill_cast 를 받아 수행한다.
func try_cast(id: String) -> bool:
    if not _defs.has(id) or not is_ready(id):
        return false
    _cooldowns[id] = float(get_def(id).get("cooldown", 5.0))
    skill_cast.emit(id)
    cooldowns_changed.emit()
    return true


## 테스트/리스폰용
func reset_cooldowns() -> void:
    _cooldowns.clear()
    cooldowns_changed.emit()
