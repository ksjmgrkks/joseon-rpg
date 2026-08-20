extends Node
##
## 스테이지 배치 데이터 정합성 + 1스테이지 컨셉 게이트.
## 실행: `godot --headless res://tests/test_stage_roster.tscn`
##
## ① 모든 assets/stages/*.json 의 "enemies[].scene" 이 실제 scenes/enemies/*.tscn 로 존재하는가
##    (오타 하나면 그 굽이의 적이 통째로 안 나오는데 조용히 지나간다 — 그걸 막는다)
## ② 1스테이지(음침한 산골짜기+수몰) 굽이에 컨셉 밖 적이 다시 섞여 들어오지 않는가
##    2026-08-20 정리: 저승사자/저승 군주/저승 뱃사공 은 골짜기·수몰 컨셉과 무관해 제외.
##    같은 날, 수몰 원혼과 아트를 그대로 돌려쓰던 「휩쓸린 넋」·「물 먹은 넋」도 제외 —
##    화면에 똑같이 생긴 흰옷 여귀만 늘어서 컨셉이 아니라 변별이 무너졌기 때문.
##

const PASS := "PASS"
const FAIL := "FAIL"
const STAGE1 := ["foothills", "forest_deep", "mountain_pass", "ruined_temple", "sacred_altar"]
const STAGE1_BANNED := ["Reaper", "ReaperLord", "DrownedFerryman", "DrownedSwarm", "DrownedHeavy"]


func _ready() -> void:
    print("=== test_stage_roster ===")
    var results: Array[Dictionary] = [_check_scenes_exist(), _check_stage1_concept()]
    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _check_scenes_exist() -> Dictionary:
    var bad: Array[String] = []
    var dir := DirAccess.open("res://assets/stages")
    for f in dir.get_files():
        if not f.ends_with(".json"):
            continue
        for e in _enemies_of(f.get_basename()):
            var path := "res://scenes/enemies/%s.tscn" % e
            if not ResourceLoader.exists(path):
                bad.append("%s → %s 없음" % [f, e])
    return { "name": "배치된_적_씬이_전부_존재", "status": PASS if bad.is_empty() else FAIL, "reason": ", ".join(bad) }


func _check_stage1_concept() -> Dictionary:
    var bad: Array[String] = []
    for s in STAGE1:
        for e in _enemies_of(s):
            if e in STAGE1_BANNED:
                bad.append("%s 에 컨셉 밖 %s" % [s, e])
    return { "name": "1스테이지_컨셉_밖_적_없음", "status": PASS if bad.is_empty() else FAIL, "reason": ", ".join(bad) }


func _enemies_of(stage_id: String) -> Array:
    var path := "res://assets/stages/%s.json" % stage_id
    if not FileAccess.file_exists(path):
        return []
    var f := FileAccess.open(path, FileAccess.READ)
    var data = JSON.parse_string(f.get_as_text())
    f.close()
    if not (data is Dictionary):
        return []
    var out: Array = []
    for e in data.get("enemies", []):
        out.append(String(e.get("scene", "")))
    return out
