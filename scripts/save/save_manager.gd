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

# 슬롯 표시용 한국어 지역명 매핑. 씬 root 이름과 1:1.
const AREA_LABELS := {
    "Village":     "마을",
    "TestLevel":   "들판",
    "Forest":      "숲",
    "ShrineRuins": "산신당 터",
    "BossArena":   "절벽 아레나",
    "MainMenu":    "메인 메뉴",
}


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
    # 요약 메타(슬롯 선택 화면용) — 본문은 안 풀고 빠르게 표시할 수 있도록 한 줄에.
    data["meta"] = {
        "area":  _current_area_name(),
        "level": (PlayerStats.level if PlayerStats else 1),
        "gold":  (PlayerStats.gold  if PlayerStats else 0),
    }

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


## 슬롯별 메타데이터 + 요약 정보(레벨/엽전/지역/저장 시각) 빠른 조회.
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
    var meta: Dictionary = data.get("meta", {})
    return {
        "slot": slot,
        "version": data.get("version", 0),
        "timestamp": data.get("timestamp", 0),
        "iso": data.get("iso", ""),
        "area":  String(meta.get("area", "")),
        "level": int(meta.get("level", 1)),
        "gold":  int(meta.get("gold", 0)),
    }


func _current_area_name() -> String:
    var tree := get_tree()
    if tree == null:
        return ""
    var cur := tree.current_scene
    if cur == null:
        return ""
    var nm := String(cur.name)
    return String(AREA_LABELS.get(nm, nm))
