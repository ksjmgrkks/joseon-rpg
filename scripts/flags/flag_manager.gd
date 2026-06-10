extends Node
##
## Flags autoload — 게임 진행 상태/퀘스트 플래그 저장소.
##
## 단순 key-value 사전. 직렬화 가능한 값(bool/int/float/String/Array/Dictionary)만 권장.
## SaveManager save_requested/loaded 에 자동 연결.
##
## 사용 예:
##   Flags.set_flag("met_villager", true)
##   if Flags.has_flag("met_villager"): ...
##   var count := int(Flags.get_flag("villager_talks", 0))
##

signal flag_changed(key: String, value)

var _store: Dictionary = {}


func _ready() -> void:
    SaveManager.save_requested.connect(_on_save)
    SaveManager.loaded.connect(_on_load)


## key에 value를 저장. value가 null이면 키 제거.
func set_flag(key: String, value) -> void:
    if value == null:
        _store.erase(key)
    else:
        _store[key] = value
    flag_changed.emit(key, value)


func get_flag(key: String, default = null):
    return _store.get(key, default)


## 키가 존재하고 truthy(true/0이 아닌 숫자/빈 문자열 아님/빈 배열·딕셔너리 아님)이면 true.
## Variant 교차 타입 ==(bool vs int 등)는 Godot 4.4+에서 런타임 에러라 타입별로 분기.
func has_flag(key: String) -> bool:
    if not _store.has(key):
        return false
    var v = _store[key]
    if v == null:
        return false
    if v is bool:
        return v
    if v is int:
        return v != 0
    if v is float:
        return v != 0.0
    if v is String:
        return not (v as String).is_empty()
    if v is Array:
        return not (v as Array).is_empty()
    if v is Dictionary:
        return not (v as Dictionary).is_empty()
    return true


func clear() -> void:
    _store.clear()


func all() -> Dictionary:
    return _store.duplicate(true)


func _on_save(_slot: int, data: Dictionary) -> void:
    data["flags"] = _store.duplicate(true)


func _on_load(_slot: int, data: Dictionary) -> void:
    _store.clear()
    var loaded_flags = data.get("flags", {})
    if loaded_flags is Dictionary:
        for k in loaded_flags:
            _store[String(k)] = loaded_flags[k]
            flag_changed.emit(String(k), loaded_flags[k])
