extends Node
##
## Flags autoload + Dialogue actions/choice 조건 헤드리스 테스트.
##

const PASS := "PASS"
const FAIL := "FAIL"

const SAMPLE := "res://assets/dialogue/sample_villager.json"


func _ready() -> void:
    print("=== test_flags ===")
    var results: Array[Dictionary] = []
    Flags.clear()
    results.append(_check_set_get_has())
    results.append(_check_save_load_roundtrip())
    Flags.clear()
    results.append(_check_dialogue_set_flag_action())
    Flags.clear()
    results.append(_check_dialogue_if_flag_filtering())
    Flags.clear()

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _check_set_get_has() -> Dictionary:
    Flags.set_flag("met_villager", true)
    if not Flags.has_flag("met_villager"):
        return { "name": "set_get_has", "status": FAIL, "reason": "has_flag false after set true" }
    Flags.set_flag("zero_count", 0)
    if Flags.has_flag("zero_count"):
        return { "name": "set_get_has", "status": FAIL, "reason": "0 is treated truthy" }
    Flags.set_flag("count_3", 3)
    if int(Flags.get_flag("count_3", 0)) != 3:
        return { "name": "set_get_has", "status": FAIL, "reason": "get_flag int mismatch" }
    Flags.set_flag("met_villager", null)  # 제거
    if Flags.has_flag("met_villager"):
        return { "name": "set_get_has", "status": FAIL, "reason": "has_flag true after null erase" }
    return { "name": "set_get_has", "status": PASS, "reason": "" }


func _check_save_load_roundtrip() -> Dictionary:
    var SLOT := 97
    SaveManager.delete_save(SLOT)
    Flags.set_flag("quest_a", "step2")
    Flags.set_flag("villager_count", 4)
    SaveManager.save(SLOT)
    Flags.clear()
    SaveManager.load(SLOT)
    SaveManager.delete_save(SLOT)
    if String(Flags.get_flag("quest_a", "")) != "step2":
        return { "name": "flags_save_load", "status": FAIL, "reason": "quest_a string lost" }
    if int(Flags.get_flag("villager_count", 0)) != 4:
        return { "name": "flags_save_load", "status": FAIL, "reason": "villager_count int lost" }
    return { "name": "flags_save_load", "status": PASS, "reason": "" }


# 대화 노드의 actions: set_flag 가 실행되는지
func _check_dialogue_set_flag_action() -> Dictionary:
    Flags.clear()
    Dialogue.start(SAMPLE)
    Dialogue.choose(0)   # from_hanyang
    Dialogue.advance()   # outro 에 들어가면서 set_flag 실행
    Dialogue.advance()   # 끝
    while Dialogue.is_active():
        Dialogue.advance()
    if not Flags.has_flag("talked_to_villager"):
        return { "name": "dialogue_set_flag_action", "status": FAIL, "reason": "set_flag action not run" }
    return { "name": "dialogue_set_flag_action", "status": PASS, "reason": "" }


# 대화 choices의 if_flag 필터링
func _check_dialogue_if_flag_filtering() -> Dictionary:
    # 1회차: talked_to_villager 없으면 intro 의 '또 뵙습니다.' 가 안 보여야 함
    Flags.clear()
    var first_choices := { "count": -1 }
    var cb1 := func(speaker: String, text: String, choices: Array) -> void:
        if first_choices.count < 0:
            first_choices.count = choices.size()
    Dialogue.dialogue_started.connect(cb1)
    Dialogue.start(SAMPLE)
    Dialogue.dialogue_started.disconnect(cb1)
    # 끝까지 흘려 outro 의 set_flag 실행
    Dialogue.choose(0)
    Dialogue.advance()
    Dialogue.advance()
    while Dialogue.is_active():
        Dialogue.advance()

    # 2회차: talked_to_villager가 true → '또 뵙습니다.' 가 보여야 함 → choices size 1 증가
    var second_choices := { "count": -1 }
    var cb2 := func(speaker: String, text: String, choices: Array) -> void:
        if second_choices.count < 0:
            second_choices.count = choices.size()
    Dialogue.dialogue_started.connect(cb2)
    Dialogue.start(SAMPLE)
    Dialogue.dialogue_started.disconnect(cb2)
    while Dialogue.is_active():
        Dialogue.advance()

    if first_choices.count != 2:
        return { "name": "dialogue_if_flag_filtering", "status": FAIL, "reason": "1회차 choices: %d (expect 2)" % first_choices.count }
    if second_choices.count != 3:
        return { "name": "dialogue_if_flag_filtering", "status": FAIL, "reason": "2회차 choices: %d (expect 3)" % second_choices.count }
    return { "name": "dialogue_if_flag_filtering", "status": PASS, "reason": "" }
