extends Node
##
## 헤드리스 대화 시스템 검증.
## 실행: `godot --headless res://tests/test_dialogue.tscn`
##

const PASS := "PASS"
const FAIL := "FAIL"

const SAMPLE := "res://assets/dialogue/sample_villager.json"


func _ready() -> void:
    print("=== test_dialogue ===")
    var results: Array[Dictionary] = []
    results.append(_check_json_loads())
    results.append(_check_start_emits())
    results.append(_check_choice_branches())
    results.append(_check_advance_to_end())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _check_json_loads() -> Dictionary:
    var f := FileAccess.open(SAMPLE, FileAccess.READ)
    if f == null:
        return { "name": "sample_json_opens", "status": FAIL, "reason": "cannot open file" }
    var raw := f.get_as_text()
    f.close()
    var p = JSON.parse_string(raw)
    if not (p is Dictionary) or not p.has("nodes") or not p.has("start"):
        return { "name": "sample_json_opens", "status": FAIL, "reason": "invalid schema" }
    return { "name": "sample_json_opens", "status": PASS, "reason": "" }


func _check_start_emits() -> Dictionary:
    var hit := { "started": false, "speaker": "", "text": "", "choices_size": -1 }
    var cb := func(speaker: String, text: String, choices: Array) -> void:
        hit.started = true
        hit.speaker = speaker
        hit.text = text
        hit.choices_size = choices.size()
    Dialogue.dialogue_started.connect(cb)
    var ok := Dialogue.start(SAMPLE)
    Dialogue.dialogue_started.disconnect(cb)
    if not ok:
        return { "name": "start_emits_event", "status": FAIL, "reason": "Dialogue.start returned false" }
    if not hit.started:
        return { "name": "start_emits_event", "status": FAIL, "reason": "started signal not received" }
    if hit.choices_size != 2:
        return { "name": "start_emits_event", "status": FAIL, "reason": "expected 2 choices, got %d" % hit.choices_size }
    # cleanup state
    Dialogue.choose(0)  # advance past
    while Dialogue.is_active():
        Dialogue.advance()
    return { "name": "start_emits_event", "status": PASS, "reason": "" }


func _check_choice_branches() -> Dictionary:
    var seen: Array[String] = []
    var cb := func(speaker: String, text: String, choices: Array) -> void:
        seen.append(text)
    Dialogue.dialogue_started.connect(cb)
    Dialogue.dialogue_advanced.connect(cb)
    Dialogue.start(SAMPLE)
    Dialogue.choose(1)  # wanderer
    Dialogue.advance()  # to outro
    Dialogue.advance()  # to end
    Dialogue.dialogue_started.disconnect(cb)
    Dialogue.dialogue_advanced.disconnect(cb)
    if seen.size() < 3:
        return { "name": "choice_branches", "status": FAIL, "reason": "expected >=3 lines visited, got %d" % seen.size() }
    var contains_wanderer := false
    for line in seen:
        if line.contains("무사인가"):
            contains_wanderer = true
    if not contains_wanderer:
        return { "name": "choice_branches", "status": FAIL, "reason": "wanderer line not visited" }
    return { "name": "choice_branches", "status": PASS, "reason": "visited %d nodes including wanderer branch" % seen.size() }


func _check_advance_to_end() -> Dictionary:
    var ended := { "v": false }
    var cb := func() -> void: ended.v = true
    Dialogue.dialogue_ended.connect(cb)
    Dialogue.start(SAMPLE)
    Dialogue.choose(0)  # from_hanyang
    Dialogue.advance()  # outro
    Dialogue.advance()  # null → end
    Dialogue.dialogue_ended.disconnect(cb)
    if not ended.v:
        return { "name": "advance_to_end", "status": FAIL, "reason": "ended signal not received" }
    if Dialogue.is_active():
        return { "name": "advance_to_end", "status": FAIL, "reason": "Dialogue still active after end" }
    return { "name": "advance_to_end", "status": PASS, "reason": "" }
