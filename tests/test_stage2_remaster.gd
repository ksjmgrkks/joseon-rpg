extends Node
## 2스테이지 리마스터 회귀: 전용 아트/지면/소품, 그슨대 변종, 대사 흐름, 조건부 해원 대사.

const PASS := "PASS"
const FAIL := "FAIL"
const STAGES := ["forest_shadow", "forest_mist", "withered_hollow", "wailing_thicket", "elder_hollow"]
const ROSTER := ["Geuseondae", "GeuseondaeEcho", "GeuseondaeGloom", "Jangseung", "GeuseondaeElder"]
const DIALOGUES := [
    "talisman_hint", "child_cry", "echo_path", "seonang_ruin", "wailing_path", "elder_intro", "elder_release",
]


func _ready() -> void:
    print("=== test_stage2_remaster ===")
    var results: Array[Dictionary] = [
        _check_stage_visual_identity(),
        _check_assets(),
        _check_roster(),
        _check_dialogues(),
        await _check_release_requires_boss_flag(),
    ]
    var failed := 0
    for result in results:
        print("[%s] %s" % [result.status, result.name])
        if result.status == FAIL:
            failed += 1
            print("  reason: %s" % result.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _check_stage_visual_identity() -> Dictionary:
    var bad: Array[String] = []
    for stage_id in STAGES:
        var data := _stage(stage_id)
        var backdrop = data.get("backdrop", {})
        var ground = data.get("ground", {})
        if String(backdrop.get("art_set", "")) != "stage2":
            bad.append("%s: stage2 배경 세트 아님" % stage_id)
        if String(ground.get("tileset", "")) != "shadow_forest":
            bad.append("%s: 전용 지면 아님" % stage_id)
        var props: Array = data.get("props", [])
        if props.size() < 8:
            bad.append("%s: 소품 %d개" % [stage_id, props.size()])
        for prop in props:
            if not String((prop as Dictionary).get("tex", "")).begins_with("stage2/"):
                bad.append("%s: 공용 소품 잔존 %s" % [stage_id, prop.get("tex", "")])
    return _result("다섯_굽이_전용_비주얼_세트", bad)


func _check_assets() -> Dictionary:
    var bad: Array[String] = []
    var expected := {
        "res://assets/sprites/bg/stage2/far.png": Vector2i(640, 180),
        "res://assets/sprites/bg/stage2/mid.png": Vector2i(640, 240),
        "res://assets/sprites/bg/stage2/near.png": Vector2i(640, 180),
        "res://assets/sprites/enemies/geuseondae_shadow/idle.png": Vector2i(440, 112),
        "res://assets/sprites/enemies/jangseung_sealed/idle.png": Vector2i(400, 128),
        "res://assets/tilesets/side/shadow_forest.png": Vector2i(256, 224),
    }
    for path in expected:
        if not FileAccess.file_exists(path):
            bad.append("에셋 없음 %s" % path)
            continue
        var image := Image.load_from_file(path)
        if image.get_size() != expected[path]:
            bad.append("%s: %s (기대 %s)" % [path, image.get_size(), expected[path]])
        if path.contains("/bg/") and (image.get_pixel(0, 0).a > 0.05 or image.get_pixel(image.get_width() - 1, 0).a > 0.05):
            bad.append("%s: 배경 상단 알파 없음" % path)
        if (path.ends_with("/mid.png") or path.ends_with("/near.png")) and _has_tall_edge_pixels(image):
            bad.append("%s: 화면 반복 경계에 잘린 나무가 닿음" % path)
    var prop_dir := DirAccess.open("res://assets/tilesets/stage2")
    var prop_count := 0
    if prop_dir == null:
        bad.append("stage2 소품 폴더 없음")
    else:
        for file in prop_dir.get_files():
            if not file.ends_with(".png"):
                continue
            prop_count += 1
            var image := Image.load_from_file("res://assets/tilesets/stage2/%s" % file)
            if image.get_used_rect().size == Vector2i.ZERO:
                bad.append("빈 소품 %s" % file)
            if image.get_pixel(0, 0).a > 0.05:
                bad.append("%s: 흰 사각 배경 잔존" % file)
        if prop_count != 16:
            bad.append("소품 %d개(기대 16)" % prop_count)
    return _result("전용_배경_지면_소품_규격과_알파", bad)


## 패럴랙스 원본 좌우 경계의 상단 45%에는 나무가 닿지 않아야 한다.
## 낮은 뿌리·덤불은 허용하되, 세로 줄기가 화면 가장자리에서 반쪽으로 잘리는 회귀를 막는다.
func _has_tall_edge_pixels(image: Image) -> bool:
    var edge_width := mini(8, image.get_width())
    var scan_height := int(image.get_height() * 0.45)
    for y in range(scan_height):
        for x in range(edge_width):
            if image.get_pixel(x, y).a > 0.05:
                return true
            if image.get_pixel(image.get_width() - 1 - x, y).a > 0.05:
                return true
    return false


func _check_roster() -> Dictionary:
    var bad: Array[String] = []
    var seen := {}
    for stage_id in STAGES:
        for enemy in _stage(stage_id).get("enemies", []):
            var scene := String((enemy as Dictionary).get("scene", ""))
            seen[scene] = true
            if scene not in ROSTER:
                bad.append("%s: 컨셉 밖 적 %s" % [stage_id, scene])
            if not ResourceLoader.exists("res://scenes/enemies/%s.tscn" % scene):
                bad.append("적 씬 없음 %s" % scene)
    for required in ["Geuseondae", "GeuseondaeEcho", "GeuseondaeGloom", "GeuseondaeElder"]:
        if not seen.has(required):
            bad.append("필수 그슨대 계열 누락 %s" % required)
    return _result("그슨대_계열_전투_변주", bad)


func _check_dialogues() -> Dictionary:
    var bad: Array[String] = []
    var all_text := ""
    for dialogue_id in DIALOGUES:
        var path := "res://assets/dialogue/geuseondae/%s.json" % dialogue_id
        if not FileAccess.file_exists(path):
            bad.append("대사 없음 %s" % dialogue_id)
            continue
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not (parsed is Dictionary) or not (parsed.get("nodes", {}) is Dictionary) or parsed.get("nodes", {}).is_empty():
            bad.append("대사 JSON 오류 %s" % dialogue_id)
            continue
        for node in parsed.get("nodes", {}).values():
            all_text += String((node as Dictionary).get("text", ""))
    if not all_text.contains("찾기 버튼"):
        bad.append("찾기 버튼 직접 안내 없음")
    if not all_text.contains("부적"):
        bad.append("부적 대안 안내 없음")
    if not all_text.contains("이름 없는 혼"):
        bad.append("보스 해원 결말 없음")
    return _result("대사_기승전결과_현행_기믹_일치", bad)


func _check_release_requires_boss_flag() -> Dictionary:
    Flags.clear()
    while Dialogue.is_active():
        Dialogue.advance()
    var trigger := Area2D.new()
    trigger.set_script(load("res://scripts/world/auto_dialogue.gd"))
    trigger.dialogue_path = "res://assets/dialogue/geuseondae/elder_release.json"
    trigger.once_flag = "test_stage2_release_seen"
    trigger.requires_flag = "geuseondae_elder_defeated"
    add_child(trigger)
    await get_tree().process_frame
    var player := Node2D.new()
    player.add_to_group("player")
    add_child(player)
    trigger._on_body_entered(player)
    var blocked := not Dialogue.is_active() and not Flags.has_flag(trigger.once_flag)
    Flags.set_flag(trigger.requires_flag, true)
    trigger._on_body_entered(player)
    var started := Dialogue.is_active() and Flags.has_flag(trigger.once_flag)
    while Dialogue.is_active():
        Dialogue.advance()
    trigger.queue_free()
    player.queue_free()
    var bad: Array[String] = []
    if not blocked:
        bad.append("보스 전 해원 대사가 발동함")
    if not started:
        bad.append("보스 후 해원 대사가 발동하지 않음")
    return _result("보스_처치_뒤에만_해원_대사", bad)


func _stage(stage_id: String) -> Dictionary:
    var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/stages/%s.json" % stage_id))
    return parsed if parsed is Dictionary else {}


func _result(name: String, bad: Array[String]) -> Dictionary:
    return {"name": name, "status": PASS if bad.is_empty() else FAIL, "reason": ", ".join(bad)}
