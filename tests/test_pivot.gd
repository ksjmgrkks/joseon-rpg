extends Node
##
## 스코어어택 피벗 가드 (2026-08-15) — 라이브 플레이 루프에서 스토리 제거가
## 회귀하지 않도록 잠금.
##   ① '새로 시작'이 「해원」 스토리 프롤로그가 아니라 첫 전투 스테이지로 진입한다.
##   ② stage.gd 가 전투-클리어 전용(GAMEPLAY_ONLY) 모드다.
##   ③ 전투 체인 스테이지 JSON 에 스토리("gut") 키가 없다.
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_pivot ===")
    var results: Array[Dictionary] = []
    results.append(_check_new_game_target())
    results.append(_check_gameplay_only())
    results.append(_check_chain_no_story())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _check_new_game_target() -> Dictionary:
    var mm: GDScript = load("res://scripts/ui/main_menu.gd")
    var path: String = mm.START_LEVEL_PATH
    if "Haewon" in path or "Prologue" in path:
        return { "name": "new_game_starts_combat", "status": FAIL,
            "reason": "새 게임이 스토리 씬으로 진입: %s" % path }
    if not path.ends_with("Foothills.tscn"):
        return { "name": "new_game_starts_combat", "status": FAIL,
            "reason": "새 게임 진입이 첫 전투 스테이지가 아님: %s" % path }
    return { "name": "new_game_starts_combat", "status": PASS, "reason": path }


func _check_gameplay_only() -> Dictionary:
    var st: GDScript = load("res://scripts/world/stage.gd")
    if not bool(st.GAMEPLAY_ONLY):
        return { "name": "gameplay_only_mode", "status": FAIL, "reason": "GAMEPLAY_ONLY 가 false" }
    return { "name": "gameplay_only_mode", "status": PASS, "reason": "" }


func _check_chain_no_story() -> Dictionary:
    var chain := ["foothills", "forest_deep", "mountain_pass", "ruined_temple", "sacred_altar"]
    for id in chain:
        var p := "res://assets/stages/%s.json" % id
        if not FileAccess.file_exists(p):
            continue
        var raw := FileAccess.get_file_as_string(p)
        var data = JSON.parse_string(raw)
        if data is Dictionary and data.has("gut"):
            return { "name": "chain_no_story", "status": FAIL,
                "reason": "%s 에 스토리 'gut' 키가 있음" % id }
    return { "name": "chain_no_story", "status": PASS, "reason": "" }
