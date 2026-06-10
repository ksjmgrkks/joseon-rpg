extends Node
##
## QuestManager + 대화 quest action/condition 헤드리스 테스트.
##

const PASS := "PASS"
const FAIL := "FAIL"

const SAMPLE_DIALOG := "res://assets/dialogue/sample_villager.json"


func _ready() -> void:
    print("=== test_quests ===")
    var results: Array[Dictionary] = []
    QuestManager.clear()
    Inventory.clear()
    Flags.clear()
    results.append(_check_start_set_complete())
    results.append(_check_dialogue_action_chain())
    QuestManager.clear()
    Inventory.clear()
    Flags.clear()
    results.append(_check_save_load_roundtrip())
    QuestManager.clear()
    Inventory.clear()
    Flags.clear()

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _check_start_set_complete() -> Dictionary:
    QuestManager.clear()
    if not QuestManager.start_quest("first_meet_villager"):
        return { "name": "start_set_complete", "status": FAIL, "reason": "start_quest returned false" }
    if not QuestManager.is_active("first_meet_villager"):
        return { "name": "start_set_complete", "status": FAIL, "reason": "not active after start" }
    if not QuestManager.is_stage("first_meet_villager", "start"):
        return { "name": "start_set_complete", "status": FAIL, "reason": "stage != start" }
    if not QuestManager.set_stage("first_meet_villager", "greeted"):
        return { "name": "start_set_complete", "status": FAIL, "reason": "set_stage failed" }
    if not QuestManager.is_stage("first_meet_villager", "greeted"):
        return { "name": "start_set_complete", "status": FAIL, "reason": "stage didn't advance" }
    if not QuestManager.complete_quest("first_meet_villager"):
        return { "name": "start_set_complete", "status": FAIL, "reason": "complete_quest failed" }
    if QuestManager.is_active("first_meet_villager"):
        return { "name": "start_set_complete", "status": FAIL, "reason": "still active after complete" }
    if not QuestManager.is_completed("first_meet_villager"):
        return { "name": "start_set_complete", "status": FAIL, "reason": "not in completed list" }
    return { "name": "start_set_complete", "status": PASS, "reason": "" }


# 대화의 start_quest / complete_quest action 작동 + Inventory 보상 지급 + if_quest_completed 필터
func _check_dialogue_action_chain() -> Dictionary:
    QuestManager.clear()
    Inventory.clear()
    Flags.clear()
    Dialogue.start(SAMPLE_DIALOG)
    if not QuestManager.is_active("first_meet_villager"):
        return { "name": "dialogue_action_chain", "status": FAIL, "reason": "start_quest not run on intro" }
    Dialogue.choose(0)   # from_hanyang
    Dialogue.advance()   # outro -> complete + rice_bun x3
    Dialogue.advance()   # null -> end
    _drain_dialogue()

    if not QuestManager.is_completed("first_meet_villager"):
        return { "name": "dialogue_action_chain", "status": FAIL, "reason": "complete_quest action didn't run" }
    if Inventory.count("rice_bun") != 3:
        return { "name": "dialogue_action_chain", "status": FAIL, "reason": "rewards not granted (rice_bun=%d)" % Inventory.count("rice_bun") }

    # 두 번째 회: if_quest_completed 로 '또 뵙습니다' 옵션 추가
    var second_choices := { "count": -1 }
    var cb := func(speaker: String, text: String, choices: Array) -> void:
        if second_choices.count < 0:
            second_choices.count = choices.size()
    Dialogue.dialogue_started.connect(cb)
    Dialogue.start(SAMPLE_DIALOG)
    Dialogue.dialogue_started.disconnect(cb)
    _drain_dialogue()
    if second_choices.count != 3:
        return { "name": "dialogue_action_chain", "status": FAIL, "reason": "expected 3 choices after completion, got %d" % second_choices.count }
    return { "name": "dialogue_action_chain", "status": PASS, "reason": "" }


func _check_save_load_roundtrip() -> Dictionary:
    var SLOT := 96
    SaveManager.delete_save(SLOT)
    QuestManager.clear()
    QuestManager.start_quest("first_meet_villager")
    QuestManager.set_stage("first_meet_villager", "greeted")
    SaveManager.save(SLOT)
    QuestManager.clear()
    SaveManager.load(SLOT)
    SaveManager.delete_save(SLOT)
    if not QuestManager.is_active("first_meet_villager"):
        return { "name": "quest_save_load", "status": FAIL, "reason": "active not restored" }
    if not QuestManager.is_stage("first_meet_villager", "greeted"):
        return { "name": "quest_save_load", "status": FAIL, "reason": "stage not restored" }
    return { "name": "quest_save_load", "status": PASS, "reason": "" }


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
