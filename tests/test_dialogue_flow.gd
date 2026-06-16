extends Node
##
## 대화 흐름 회귀 — '선택지가 전부 숨겨진 노드'에서 교착되지 않고 진행/종료되는지.
## (사용자 보고: 대화창이 안 닫히고 계속 떠 있음)
##

const PASS := "PASS"
const FAIL := "FAIL"
const TMP := "user://_test_dialogue_deadlock.json"


func _ready() -> void:
    print("=== test_dialogue_flow ===")
    var results: Array[Dictionary] = []
    results.append(_check_hidden_choices_advances())
    results.append(_check_simple_dialogue_ends())
    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _write(json: Dictionary) -> String:
    var f := FileAccess.open(TMP, FileAccess.WRITE)
    f.store_string(JSON.stringify(json))
    f.close()
    return TMP


# 모든 선택지가 조건으로 숨겨진 노드 → advance() 가 next 로 빠져나가야(교착 X)
func _check_hidden_choices_advances() -> Dictionary:
    Flags.clear()
    var path := _write({
        "id": "t", "start": "a",
        "nodes": {
            "a": {"speaker": "x", "text": "처음", "choices": [
                {"text": "보이지 않는 선택", "next": "b", "if_flag": "never_set"}
            ], "next": "b"},
            "b": {"speaker": "x", "text": "끝", "next": null}
        }
    })
    Dialogue.start(path)
    if not Dialogue.is_active():
        return _fail("hidden_choices_advances", "start 실패")
    Dialogue.advance()   # a 의 보이는 선택지 0 → next(b) 로
    if not Dialogue.is_active():
        return _fail("hidden_choices_advances", "b 도달 전에 종료됨")
    Dialogue.advance()   # b(next null) → 종료
    if Dialogue.is_active():
        return _fail("hidden_choices_advances", "교착: 대화가 끝나지 않음")
    return _pass("hidden_choices_advances")


# 평범한 2노드 대화가 advance 두 번으로 깔끔히 종료
func _check_simple_dialogue_ends() -> Dictionary:
    var path := _write({
        "id": "t2", "start": "a",
        "nodes": {
            "a": {"speaker": "x", "text": "하나", "next": "b"},
            "b": {"speaker": "x", "text": "둘", "next": null}
        }
    })
    Dialogue.start(path)
    Dialogue.advance()
    Dialogue.advance()
    if Dialogue.is_active():
        return _fail("simple_dialogue_ends", "종료 안 됨")
    return _pass("simple_dialogue_ends")


func _pass(n: String) -> Dictionary: return { "name": n, "status": PASS, "reason": "" }
func _fail(n: String, r: String) -> Dictionary: return { "name": n, "status": FAIL, "reason": r }
