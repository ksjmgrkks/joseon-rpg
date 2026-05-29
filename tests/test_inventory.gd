extends Node
##
## Inventory autoload 헤드리스 테스트.
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_inventory ===")
    var results: Array[Dictionary] = []
    Inventory.clear()
    results.append(_check_definitions_loaded())
    results.append(_check_add_remove())
    results.append(_check_stacking())
    results.append(_check_save_load_roundtrip())
    Inventory.clear()

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _check_definitions_loaded() -> Dictionary:
    var d := Inventory.get_def("potion_minor")
    if d.is_empty():
        return { "name": "definitions_loaded", "status": FAIL, "reason": "potion_minor missing" }
    if String(d.get("name", "")) != "쾌혈환":
        return { "name": "definitions_loaded", "status": FAIL, "reason": "name mismatch" }
    return { "name": "definitions_loaded", "status": PASS, "reason": "" }


func _check_add_remove() -> Dictionary:
    Inventory.clear()
    var added := Inventory.add("rice_bun", 3)
    if added != 3 or Inventory.count("rice_bun") != 3:
        return { "name": "add_remove", "status": FAIL, "reason": "add count wrong: added=%d count=%d" % [added, Inventory.count("rice_bun")] }
    var removed := Inventory.remove("rice_bun", 2)
    if removed != 2 or Inventory.count("rice_bun") != 1:
        return { "name": "add_remove", "status": FAIL, "reason": "remove count wrong" }
    # 없는 아이템
    if Inventory.add("nonexistent_xyz", 1) != 0:
        return { "name": "add_remove", "status": FAIL, "reason": "unknown id should add 0" }
    return { "name": "add_remove", "status": PASS, "reason": "" }


func _check_stacking() -> Dictionary:
    Inventory.clear()
    # potion_minor 는 max_stack 9
    Inventory.add("potion_minor", 25)
    # 9 + 9 + 7 = 3 슬롯
    var s := Inventory.slots()
    var minor := s.filter(func(x): return x.id == "potion_minor")
    if minor.size() != 3:
        return { "name": "stacking", "status": FAIL, "reason": "expected 3 stacks of potion_minor, got %d" % minor.size() }
    if Inventory.count("potion_minor") != 25:
        return { "name": "stacking", "status": FAIL, "reason": "total count wrong" }
    return { "name": "stacking", "status": PASS, "reason": "" }


func _check_save_load_roundtrip() -> Dictionary:
    var SLOT := 98
    SaveManager.delete_save(SLOT)
    Inventory.clear()
    Inventory.add("sword_iron", 1)
    Inventory.add("rice_bun", 5)
    SaveManager.save(SLOT)

    # 비웠다가 로드해서 복원되는지
    Inventory.clear()
    if Inventory.count("rice_bun") != 0:
        return { "name": "save_load_roundtrip", "status": FAIL, "reason": "clear failed" }
    SaveManager.load(SLOT)
    SaveManager.delete_save(SLOT)

    if Inventory.count("sword_iron") != 1 or Inventory.count("rice_bun") != 5:
        return { "name": "save_load_roundtrip", "status": FAIL, "reason": "restore counts wrong (sword=%d, rice=%d)" % [Inventory.count("sword_iron"), Inventory.count("rice_bun")] }
    return { "name": "save_load_roundtrip", "status": PASS, "reason": "" }
