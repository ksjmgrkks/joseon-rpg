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
    _drain_dialogue()
    if not Flags.has_flag("talked_to_villager"):
        return { "name": "dialogue_set_flag_action", "status": FAIL, "reason": "set_flag action not run" }
    return { "name": "dialogue_set_flag_action", "status": PASS, "reason": "" }


# 대화 choices의 if_flag / unless_flag 필터링.
# sample_villager 의 세 번째 선택지는 Phase 3에서 if_quest_completed 게이트로 바뀌어
# (그건 test_quests 가 검증) 여기선 순수 플래그 게이트인 village_woman 으로 확인한다.
func _check_dialogue_if_flag_filtering() -> Dictionary:
    const WOMAN := "res://assets/dialogue/village_woman.json"
    Flags.clear()
    QuestManager.clear()
    var seen := { "texts": [] }
    var cb := func(_speaker: String, _text: String, choices: Array) -> void:
        var texts: Array = []
        for c in choices:
            texts.append(String(c.get("text", "")))
        seen.texts = texts

    # 1회차 (플래그 없음): '말씀하시오'(unless_flag) + '다음에' 만 보여야 함
    Dialogue.dialogue_started.connect(cb)
    Dialogue.start(WOMAN)
    _drain_dialogue()
    var first: Array = seen.texts
    if first.size() != 2 or not String(first[0]).begins_with("말씀"):
        Dialogue.dialogue_started.disconnect(cb)
        return { "name": "dialogue_if_flag_filtering", "status": FAIL, "reason": "1회차 choices %s (expect [말씀…, 다음에…])" % [first] }

    # 2회차 (asked_charm=true): unless_flag 로 '말씀하시오' 숨고 if_flag 로 '약초' 등장
    Flags.set_flag("asked_charm", true)
    Dialogue.start(WOMAN)
    _drain_dialogue()
    var second: Array = seen.texts
    if second.size() != 2 or not String(second[0]).begins_with("약초"):
        Dialogue.dialogue_started.disconnect(cb)
        return { "name": "dialogue_if_flag_filtering", "status": FAIL, "reason": "2회차 choices %s (expect [약초…, 다음에…])" % [second] }

    # 3회차 (asked_herbs 도 true): '약초'도 숨어 '다음에' 하나만
    Flags.set_flag("asked_herbs", true)
    Dialogue.start(WOMAN)
    Dialogue.dialogue_started.disconnect(cb)
    _drain_dialogue()
    var third: Array = seen.texts
    if third.size() != 1:
        return { "name": "dialogue_if_flag_filtering", "status": FAIL, "reason": "3회차 choices %s (expect 1)" % [third] }
    return { "name": "dialogue_if_flag_filtering", "status": PASS, "reason": "" }


## 대화를 끝까지 흘린다. choices 노드에서 advance() 는 no-op 이라(dialogue_manager 가드)
## 그대로 돌리면 무한 루프 — 첫 선택지를 골라 진행하고 안전 상한을 둔다.
func _drain_dialogue(max_steps: int = 32) -> void:
    var steps := 0
    while Dialogue.is_active() and steps < max_steps:
        Dialogue.advance()
        if Dialogue.is_active():
            Dialogue.choose(0)
        steps += 1
    if Dialogue.is_active():
        push_warning("[test] dialogue still active after %d steps — force end" % max_steps)
        Dialogue._end()
