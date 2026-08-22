extends Node
## 3스테이지 리마스터 계약: 전용 시각 세트·굽이별 대사·혼합 로스터·보스 마감 대사를 고정한다.

const PASS := "PASS"
const FAIL := "FAIL"
const STAGES := ["market_ruins", "broken_stalls", "well_court", "lantern_alley", "goblin_court"]
const LEGACY_PROPS := ["house_thatch", "house_tile", "fence", "lantern", "chest", "boulder", "boulder_moss"]
const REMASTER_PROPS := [
    "market_stall_broken", "market_stall_canopy", "market_cart_broken", "market_well",
    "ssireum_ring", "market_goods", "market_scale", "dokkaebi_brazier", "market_banner",
]


func _ready() -> void:
    print("=== test_stage3_remaster ===")
    var results: Array[Dictionary] = [
        _check_visual_identity(),
        _check_dialogue_arc(),
        _check_roster_curve(),
        _check_assets(),
        _check_clear_dialogue_support(),
    ]
    var failed := 0
    for result in results:
        print("[%s] %s" % [result.status, result.name])
        if result.status == FAIL:
            failed += 1
            print("  reason: %s" % result.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _check_visual_identity() -> Dictionary:
    var bad: Array[String] = []
    var seen_props := {}
    for stage_id in STAGES:
        var data := _stage(stage_id)
        if String(data.get("backdrop", {}).get("art_set", "")) != "stage3":
            bad.append("%s: stage3 backdrop 아님" % stage_id)
        if String(data.get("ground", {}).get("tileset", "")) != "market":
            bad.append("%s: market 지면 아님" % stage_id)
        var stage_new := 0
        for prop in data.get("props", []):
            var tex := String(prop.get("tex", ""))
            if tex in LEGACY_PROPS:
                bad.append("%s: 옛 범용 소품 %s 잔존" % [stage_id, tex])
            if tex in REMASTER_PROPS:
                seen_props[tex] = true
                stage_new += 1
        if stage_new < 5:
            bad.append("%s: 전용 소품 %d개(최소 5)" % [stage_id, stage_new])
    if seen_props.size() < 8:
        bad.append("전용 소품 종류 %d개(최소 8)" % seen_props.size())
    return _result("stage3_전용_배경_지면_소품", bad)


func _check_dialogue_arc() -> Dictionary:
    var bad: Array[String] = []
    var dialogue_count := 0
    for stage_id in STAGES:
        var data := _stage(stage_id)
        var autos: Array = data.get("auto_dialogues", [])
        if autos.is_empty():
            bad.append("%s: 진입 대사 없음" % stage_id)
        for auto in autos:
            var path := String(auto.get("dialogue", ""))
            dialogue_count += 1
            _validate_dialogue(path, bad)
    var boss := _stage("goblin_court")
    var clear_path := String(boss.get("clear_dialogue", ""))
    if clear_path == "":
        bad.append("goblin_court: 클리어 대사 없음")
    else:
        _validate_dialogue(clear_path, bad)
    if dialogue_count < 5:
        bad.append("굽이 대사 %d개(최소 5)" % dialogue_count)
    return _result("stage3_대사_도입부터_해방까지", bad)


func _check_roster_curve() -> Dictionary:
    var fire_count := 0
    var brute_count := 0
    var chief_count := 0
    var bad: Array[String] = []
    for stage_id in STAGES:
        for enemy in _stage(stage_id).get("enemies", []):
            match String(enemy.get("scene", "")):
                "DokkaebiFire": fire_count += 1
                "DokkaebiBrute": brute_count += 1
                "DokkaebiChief": chief_count += 1
    if fire_count < 4:
        bad.append("도깨비불 %d기(최소 4)" % fire_count)
    if brute_count != 1:
        bad.append("곤봉 도깨비 %d기(정확히 1)" % brute_count)
    if chief_count != 1:
        bad.append("도깨비 대장 %d기(정확히 1)" % chief_count)
    return _result("stage3_근접_원거리_중간보스_최종보스_곡선", bad)


func _check_assets() -> Dictionary:
    var bad: Array[String] = []
    for path in [
        "res://assets/sprites/bg/stage3/far.png",
        "res://assets/sprites/bg/stage3/mid.png",
        "res://assets/sprites/bg/stage3/near.png",
        "res://assets/tilesets/side/market.png",
        "res://scenes/enemies/DokkaebiFire.tscn",
    ]:
        if not ResourceLoader.exists(path):
            bad.append("에셋 없음: %s" % path)
    for prop in REMASTER_PROPS:
        var path := "res://assets/tilesets/%s.png" % prop
        if not ResourceLoader.exists(path):
            bad.append("소품 없음: %s" % prop)
    for sheet in ["dokkaebi_minion", "dokkaebi_brute", "dokkaebi_fire"]:
        for anim in ["idle", "walk", "telegraph", "attack", "death"]:
            var path := "res://assets/sprites/enemies/%s/%s.png" % [sheet, anim]
            if not ResourceLoader.exists(path):
                bad.append("%s %s 없음" % [sheet, anim])
        if not FileAccess.file_exists("res://assets/sprites/enemies/%s/manifest.json" % sheet):
            bad.append("%s manifest 없음" % sheet)
    if ResourceLoader.exists("res://assets/sprites/enemies/dokkaebi_fire/idle.png"):
        var idle: Texture2D = load("res://assets/sprites/enemies/dokkaebi_fire/idle.png")
        if idle.get_width() != 384 or idle.get_height() != 64:
            bad.append("도깨비불 idle 규격 %dx%d (기대 384x64)" % [idle.get_width(), idle.get_height()])
    var expected_sheets := {
        "res://scenes/enemies/Dokkaebi.tscn": "enemies/dokkaebi_minion",
        "res://scenes/enemies/DokkaebiBrute.tscn": "enemies/dokkaebi_brute",
    }
    for scene_path in expected_sheets:
        var scene_source := FileAccess.get_file_as_string(scene_path)
        var expected: String = expected_sheets[scene_path]
        if not scene_source.contains('sheet = "%s"' % expected):
            bad.append("%s 전용 시트 미연결" % scene_path.get_file())
        if scene_source.contains('sheet = "enemies/goblin"'):
            bad.append("%s 범용 goblin 시트 잔존" % scene_path.get_file())
    return _result("stage3_생성_에셋_존재와_규격", bad)


func _check_clear_dialogue_support() -> Dictionary:
    var source := (load("res://scripts/world/stage.gd") as GDScript).get_source_code()
    var bad: Array[String] = []
    if not source.contains("_play_gameplay_clear_dialogue") or not source.contains("clear_dialogue"):
        bad.append("전투 전용 모드의 클리어 대사 배선 없음")
    return _result("전투_클리어_뒤_마감대사_배선", bad)


func _validate_dialogue(path: String, bad: Array[String]) -> void:
    if path == "" or not FileAccess.file_exists(path):
        bad.append("대사 파일 없음: %s" % path)
        return
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not (parsed is Dictionary):
        bad.append("대사 JSON 오류: %s" % path)
        return
    var nodes: Dictionary = parsed.get("nodes", {})
    var start := String(parsed.get("start", ""))
    if start == "" or not nodes.has(start):
        bad.append("대사 시작 노드 오류: %s" % path)
    for node_id in nodes:
        var next = nodes[node_id].get("next", null)
        if next != null and not nodes.has(String(next)):
            bad.append("%s/%s: 끊긴 next=%s" % [path.get_file(), node_id, next])


func _stage(stage_id: String) -> Dictionary:
    var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/stages/%s.json" % stage_id))
    return parsed if parsed is Dictionary else {}


func _result(name: String, bad: Array[String]) -> Dictionary:
    return {"name": name, "status": PASS if bad.is_empty() else FAIL, "reason": ", ".join(bad)}
