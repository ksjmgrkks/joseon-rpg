extends Node
##
## 스코어 어택 시스템 테스트 (2026-08-15) — 점수 획득/리셋, 최고기록 갱신,
## MM:SS 포맷, 기록 영구 저장(SaveManager.records).
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_score ===")
    var results: Array[Dictionary] = []
    results.append(_check_add_and_reset())
    results.append(_check_best_score())
    results.append(_check_format_time())
    results.append(_check_records_persist())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _p(n: String) -> Dictionary: return { "name": n, "status": PASS, "reason": "" }
func _f(n: String, r: String) -> Dictionary: return { "name": n, "status": FAIL, "reason": r }


func _check_add_and_reset() -> Dictionary:
    ScoreManager.start_run()
    if ScoreManager.score != 0:
        return _f("add_and_reset", "start_run 후 점수 0 아님(%d)" % ScoreManager.score)
    ScoreManager.add_score(150)
    ScoreManager.add_score(50)
    if ScoreManager.score != 200:
        return _f("add_and_reset", "점수 누적 오류(%d, 기대 200)" % ScoreManager.score)
    ScoreManager.add_score(-10)   # 음수 무시
    if ScoreManager.score != 200:
        return _f("add_and_reset", "음수 점수가 반영됨(%d)" % ScoreManager.score)
    ScoreManager.start_run()      # 리셋
    if ScoreManager.score != 0:
        return _f("add_and_reset", "재시작 리셋 실패(%d)" % ScoreManager.score)
    return _p("add_and_reset")


func _check_best_score() -> Dictionary:
    ScoreManager.best_score = 0
    ScoreManager.start_run()
    ScoreManager.add_score(500)
    var res := ScoreManager.register_result(false)
    if not res.get("new_best_score", false):
        return _f("best_score", "첫 기록이 최고 갱신으로 안 잡힘")
    if ScoreManager.best_score != 500:
        return _f("best_score", "best_score %d(기대 500)" % ScoreManager.best_score)
    # 더 낮은 점수는 갱신 안 됨
    ScoreManager.start_run()
    ScoreManager.add_score(300)
    var res2 := ScoreManager.register_result(false)
    if res2.get("new_best_score", false):
        return _f("best_score", "낮은 점수가 최고 갱신됨")
    if ScoreManager.best_score != 500:
        return _f("best_score", "best_score 훼손(%d)" % ScoreManager.best_score)
    return _p("best_score")


func _check_format_time() -> Dictionary:
    if ScoreManager.format_time(0.0) != "00:00":
        return _f("format_time", "0초 -> %s" % ScoreManager.format_time(0.0))
    if ScoreManager.format_time(65.0) != "01:05":
        return _f("format_time", "65초 -> %s" % ScoreManager.format_time(65.0))
    if ScoreManager.format_time(600.0) != "10:00":
        return _f("format_time", "600초 -> %s" % ScoreManager.format_time(600.0))
    return _p("format_time")


func _check_records_persist() -> Dictionary:
    SaveManager.save_records({ "best_score": 1234, "best_time": 42.0 })
    var r := SaveManager.load_records()
    if int(r.get("best_score", 0)) != 1234:
        return _f("records_persist", "best_score 저장/복원 실패(%s)" % str(r))
    if abs(float(r.get("best_time", 0.0)) - 42.0) > 0.001:
        return _f("records_persist", "best_time 저장/복원 실패(%s)" % str(r))
    return _p("records_persist")
