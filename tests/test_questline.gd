extends Node
##
## A — 본격 퀘스트 라인 헤드리스 테스트.
## 메인 퀘스트(main_tiger_lord)의 단계 전이, 사이드 퀘스트(side_lost_charm),
## 그리고 어르신 대화의 if_quest_stage 조건 분기를 검증.
##

const PASS := "PASS"
const FAIL := "FAIL"

const ELDER_DIALOG := "res://assets/dialogue/village_elder.json"
const WOMAN_DIALOG := "res://assets/dialogue/village_woman.json"


func _ready() -> void:
    print("=== test_questline ===")
    var results: Array[Dictionary] = []
    _reset()
    results.append(_check_main_quest_stages())
    _reset()
    results.append(_check_side_charm_stages())
    _reset()
    results.append(_check_elder_branches())
    _reset()

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _reset() -> void:
    QuestManager.clear()
    Inventory.clear()
    Flags.clear()


# 메인 퀘스트 5단계 + 어금니 보상 흐름
func _check_main_quest_stages() -> Dictionary:
    if not QuestManager.start_quest("main_tiger_lord"):
        return _fail("main_quest_stages", "start_quest failed")
    if not QuestManager.is_stage("main_tiger_lord", "start"):
        return _fail("main_quest_stages", "expected start")
    for s in ["to_forest", "boss_arena", "boss_defeated"]:
        if not QuestManager.set_stage("main_tiger_lord", s):
            return _fail("main_quest_stages", "set_stage %s failed" % s)
        if not QuestManager.is_stage("main_tiger_lord", s):
            return _fail("main_quest_stages", "expected stage %s" % s)
    # 보스 단계까지 가서 어금니 받았다고 가정 + 어르신 대화 outro 가 complete 시키는 시나리오는
    # _check_elder_branches 에서. 여기서는 complete 자체만 확인.
    if not QuestManager.complete_quest("main_tiger_lord"):
        return _fail("main_quest_stages", "complete_quest failed")
    if not QuestManager.is_completed("main_tiger_lord"):
        return _fail("main_quest_stages", "not in completed")
    # 보상 — sword_jade x1, coin_pouch x2
    if Inventory.count("sword_jade") != 1:
        return _fail("main_quest_stages", "sword_jade reward not granted")
    if Inventory.count("coin_pouch") != 2:
        return _fail("main_quest_stages", "coin_pouch reward not granted")
    return _pass("main_quest_stages")


# 사이드 퀘스트(부적): 시작 → found 단계 → 완료 보상
func _check_side_charm_stages() -> Dictionary:
    Dialogue.start(WOMAN_DIALOG)
    Dialogue.choose(0)   # "말씀하시오." → ask_charm (start_quest)
    while Dialogue.is_active():
        Dialogue.advance()
    if not QuestManager.is_active("side_lost_charm"):
        return _fail("side_charm_stages", "quest not started by dialogue")
    # 부적을 주운 셈치고 set_stage("found") + 인벤토리에 charm_lost 직접 추가
    if not QuestManager.set_stage("side_lost_charm", "found"):
        return _fail("side_charm_stages", "set_stage found failed")
    Inventory.add("charm_lost", 1)
    # 아낙에게 돌려주기 — if_quest_stage:side_lost_charm:found 선택지가 보여야 함
    var observed := { "choices_count": -1 }
    var cb := func(_speaker: String, _text: String, choices: Array) -> void:
        if observed.choices_count < 0:
            observed.choices_count = choices.size()
    Dialogue.dialogue_started.connect(cb)
    Dialogue.start(WOMAN_DIALOG)
    Dialogue.dialogue_started.disconnect(cb)
    # 시작 노드에서 3개 선택지(말씀하시오/돌려주기/다음에)가 모두 보여야 함 (start_quest 중복 호출은 무해)
    if observed.choices_count != 3:
        return _fail("side_charm_stages", "expected 3 choices (with return option), got %d" % observed.choices_count)
    # 두 번째 선택지(return)를 골라 보상 받기
    Dialogue.choose(1)
    while Dialogue.is_active():
        Dialogue.advance()
    if not QuestManager.is_completed("side_lost_charm"):
        return _fail("side_charm_stages", "side quest not completed")
    if Inventory.count("potion_minor") != 2:
        return _fail("side_charm_stages", "potion_minor reward not granted")
    return _pass("side_charm_stages")


# 어르신 대화의 if_quest_active / if_quest_stage 조건이 의도대로 동작하는지
func _check_elder_branches() -> Dictionary:
    # 1) 첫 만남: 인사 시작 (선택지 2개만 보여야 — '한양' '길손')
    var first := { "n": -1 }
    var cb1 := func(_s: String, _t: String, choices: Array) -> void:
        if first.n < 0:
            first.n = choices.size()
    Dialogue.dialogue_started.connect(cb1)
    Dialogue.start(ELDER_DIALOG)
    Dialogue.dialogue_started.disconnect(cb1)
    if first.n != 2:
        return _fail("elder_branches", "first meeting expected 2 choices, got %d" % first.n)
    # 한양 분기 따라가 outro_first → tiger_offer → accept
    Dialogue.choose(0)   # from_hanyang
    Dialogue.advance()   # → outro_first
    # outro_first 다음 노드는 tiger_offer 인데 choices 가 있어 dialogue_started 가 아니라 advanced 가 떨어짐.
    # tiger_offer 에서 선택지 두 개 중 첫 번째 (수락).
    Dialogue.choose(0)
    while Dialogue.is_active():
        Dialogue.advance()
    if not QuestManager.is_active("main_tiger_lord"):
        return _fail("elder_branches", "tiger_offer accept didn't start main quest")
    if not QuestManager.is_completed("first_meet_villager"):
        return _fail("elder_branches", "first_meet_villager not completed by outro_first")

    # 2) 재방문: 메인 활성 중 → 'tiger_status' 옵션이 추가돼야 (3 choices)
    var second := { "n": -1 }
    var cb2 := func(_s: String, _t: String, choices: Array) -> void:
        if second.n < 0:
            second.n = choices.size()
    Dialogue.dialogue_started.connect(cb2)
    Dialogue.start(ELDER_DIALOG)
    Dialogue.dialogue_started.disconnect(cb2)
    while Dialogue.is_active():
        Dialogue.advance()
    if second.n != 3:
        return _fail("elder_branches", "second visit expected 3 choices, got %d" % second.n)

    # 3) 보스 처치 후(stage = boss_defeated): tooth_show 옵션도 추가돼야 → 4 choices
    QuestManager.set_stage("main_tiger_lord", "boss_defeated")
    var third := { "n": -1 }
    var cb3 := func(_s: String, _t: String, choices: Array) -> void:
        if third.n < 0:
            third.n = choices.size()
    Dialogue.dialogue_started.connect(cb3)
    Dialogue.start(ELDER_DIALOG)
    Dialogue.dialogue_started.disconnect(cb3)
    if third.n != 4:
        return _fail("elder_branches", "post-boss expected 4 choices, got %d" % third.n)
    # 마지막 옵션(어금니 내밀기)을 골라 complete
    Dialogue.choose(3)
    while Dialogue.is_active():
        Dialogue.advance()
    if not QuestManager.is_completed("main_tiger_lord"):
        return _fail("elder_branches", "tooth_show didn't complete main quest")
    if not Flags.has_flag("tiger_lord_resolved"):
        return _fail("elder_branches", "tiger_lord_resolved flag not set")
    return _pass("elder_branches")


func _pass(name: String) -> Dictionary:
    return { "name": name, "status": PASS, "reason": "" }


func _fail(name: String, reason: String) -> Dictionary:
    return { "name": name, "status": FAIL, "reason": reason }
