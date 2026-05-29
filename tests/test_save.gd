extends Node
##
## SaveManager 헤드리스 검증.
## 실행: godot --headless res://tests/test_save.tscn
##

const PASS := "PASS"
const FAIL := "FAIL"

const TEST_SLOT := 99  # 통상 사용 슬롯과 충돌 안 나는 값


func _ready() -> void:
    print("=== test_save ===")
    var results: Array[Dictionary] = []

    SaveManager.delete_save(TEST_SLOT)  # clean slate

    results.append(_check_save_load_roundtrip())
    results.append(_check_has_save_state())
    results.append(_check_slot_info())

    SaveManager.delete_save(TEST_SLOT)  # cleanup

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _check_save_load_roundtrip() -> Dictionary:
    var payload := { "value": 42, "name": "양반 무사", "list": [1, 2, 3] }

    # save: 시그널에 연결해 payload를 데이터에 박는다
    var save_cb := func(slot: int, data: Dictionary) -> void:
        data["test"] = payload
    SaveManager.save_requested.connect(save_cb)
    var ok_s := SaveManager.save(TEST_SLOT)
    SaveManager.save_requested.disconnect(save_cb)
    if not ok_s:
        return { "name": "save_load_roundtrip", "status": FAIL, "reason": "save() returned false" }

    # load: 시그널에 연결해 다시 읽음
    var received := { "data": null }
    var load_cb := func(slot: int, data: Dictionary) -> void:
        received.data = data.get("test", null)
    SaveManager.loaded.connect(load_cb)
    var ok_l := SaveManager.load(TEST_SLOT)
    SaveManager.loaded.disconnect(load_cb)
    if not ok_l:
        return { "name": "save_load_roundtrip", "status": FAIL, "reason": "load() returned false" }
    if received.data == null:
        return { "name": "save_load_roundtrip", "status": FAIL, "reason": "no test data restored" }
    if int(received.data.get("value", -1)) != 42:
        return { "name": "save_load_roundtrip", "status": FAIL, "reason": "value mismatch" }
    if String(received.data.get("name", "")) != "양반 무사":
        return { "name": "save_load_roundtrip", "status": FAIL, "reason": "name mismatch (utf-8 check)" }
    return { "name": "save_load_roundtrip", "status": PASS, "reason": "" }


func _check_has_save_state() -> Dictionary:
    if not SaveManager.has_save(TEST_SLOT):
        return { "name": "has_save_after_write", "status": FAIL, "reason": "has_save returns false after save" }
    var deleted := SaveManager.delete_save(TEST_SLOT)
    if not deleted:
        return { "name": "has_save_after_write", "status": FAIL, "reason": "delete_save returned false" }
    if SaveManager.has_save(TEST_SLOT):
        return { "name": "has_save_after_write", "status": FAIL, "reason": "has_save still true after delete" }
    # 다음 케이스를 위해 다시 한 번 저장해둠
    SaveManager.save(TEST_SLOT)
    return { "name": "has_save_after_write", "status": PASS, "reason": "" }


func _check_slot_info() -> Dictionary:
    var info := SaveManager.get_slot_info(TEST_SLOT)
    if info.is_empty():
        return { "name": "slot_info", "status": FAIL, "reason": "empty info" }
    if int(info.get("version", 0)) != SaveManager.VERSION:
        return { "name": "slot_info", "status": FAIL, "reason": "version mismatch" }
    if int(info.get("timestamp", 0)) <= 0:
        return { "name": "slot_info", "status": FAIL, "reason": "timestamp not set" }
    return { "name": "slot_info", "status": PASS, "reason": "" }
