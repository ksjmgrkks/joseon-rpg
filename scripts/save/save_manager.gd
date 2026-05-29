extends Node
##
## SaveManager — autoload. 슬롯 기반 JSON 세이브/로드.
##
## 사용 흐름:
##  - 다른 시스템들은 save_requested 시그널에 연결해 data dict에 자기 영역을 채워 넣고,
##    loaded 시그널에 연결해 자기 영역을 복원합니다 (key 충돌 안 나게 시스템마다 고유 키 사용).
##
## 파일 위치: user://saves/slot_<N>.json  (autosave는 slot 0 약속)
##

signal save_requested(slot: int, data: Dictionary)
signal saved(slot: int, ok: bool)
signal loaded(slot: int, data: Dictionary)

const SAVE_DIR := "user://saves/"
const VERSION := 1


func _ready() -> void:
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _slot_path(slot: int) -> String:
    return "%sslot_%d.json" % [SAVE_DIR, slot]


func has_save(slot: int) -> bool:
    return FileAccess.file_exists(_slot_path(slot))


func save(slot: int) -> bool:
    var data: Dictionary = {
        "version": VERSION,
        "slot": slot,
        "timestamp": Time.get_unix_time_from_system(),
        "iso": Time.get_datetime_string_from_system(true),
    }
    # 다른 시스템들이 data 에 자기 영역을 추가
    save_requested.emit(slot, data)

    var path := _slot_path(slot)
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("[Save] cannot open for write: %s" % path)
        saved.emit(slot, false)
        return false
    file.store_string(JSON.stringify(data, "  "))
    file.close()
    saved.emit(slot, true)
    return true


func load(slot: int) -> bool:
    var path := _slot_path(slot)
    if not FileAccess.file_exists(path):
        push_warning("[Save] no save in slot %d" % slot)
        return false
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("[Save] cannot open for read: %s" % path)
        return false
    var raw := file.get_as_text()
    file.close()
    var parsed = JSON.parse_string(raw)
    if not (parsed is Dictionary):
        push_error("[Save] invalid JSON in %s" % path)
        return false
    loaded.emit(slot, parsed)
    return true


func delete_save(slot: int) -> bool:
    var path := _slot_path(slot)
    if not FileAccess.file_exists(path):
        return false
    var err := DirAccess.remove_absolute(path)
    return err == OK


## 슬롯별 메타데이터(저장 시각·버전) 빠른 조회. 본문 데이터는 안 읽음.
func get_slot_info(slot: int) -> Dictionary:
    if not has_save(slot):
        return {}
    var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
    if file == null:
        return {}
    var raw := file.get_as_text()
    file.close()
    var data = JSON.parse_string(raw)
    if not (data is Dictionary):
        return {}
    return {
        "slot": slot,
        "version": data.get("version", 0),
        "timestamp": data.get("timestamp", 0),
        "iso": data.get("iso", ""),
    }
