extends Node
## 4스테이지 「끊긴 상여길」 계약: 5굽이·전용 아트·크기 서열·세 종 예고·음악.

const PASS := "PASS"
const FAIL := "FAIL"
const IDS := ["funeral_pass", "kkokdu_road", "frozen_rest", "mourning_ridge", "unfinished_grave"]
const SCENES := ["FuneralPass", "KkokduRoad", "FrozenRest", "MourningRidge", "UnfinishedGrave"]


func _ready() -> void:
    print("=== test_stage4 ===")
    var results: Array[Dictionary] = [
        _check_chain(),
        _check_stage_data(),
        _check_art_alpha(),
        _check_size_ladder(),
        _check_three_bells(),
        _check_audio(),
    ]
    var failed := 0
    for result in results:
        print("[%s] %s" % [result.status, result.name])
        if result.status == FAIL:
            failed += 1
            print("  reason: %s" % result.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _check_chain() -> Dictionary:
    var tail := Stage.CHAIN.slice(Stage.CHAIN.size() - IDS.size())
    var ok := tail == IDS
    for i in range(IDS.size()):
        ok = ok and String(Stage.CHAIN_TSCN.get(IDS[i], "")).ends_with("/%s.tscn" % SCENES[i])
    return {"name": "4스테이지_5굽이_체인", "status": PASS if ok else FAIL,
        "reason": "체인 끝=%s" % str(tail)}


func _check_stage_data() -> Dictionary:
    var bad: Array[String] = []
    for stage_id in IDS:
        var data := _json("res://assets/stages/%s.json" % stage_id)
        if data.is_empty():
            bad.append("%s JSON 없음" % stage_id)
            continue
        if String(data.get("ground", {}).get("tileset", "")) != "snow_pass":
            bad.append("%s 눈길 지면 아님" % stage_id)
        if String(data.get("backdrop", {}).get("art_set", "")) != "stage4":
            bad.append("%s stage4 배경 아님" % stage_id)
        for prop in data.get("props", []):
            var path := "res://assets/tilesets/%s.png" % String(prop.get("tex", ""))
            if not ResourceLoader.exists(path):
                bad.append("%s 소품 없음" % path)
    return {"name": "눈길_배경_소품_데이터", "status": PASS if bad.is_empty() else FAIL,
        "reason": ", ".join(bad)}


func _check_art_alpha() -> Dictionary:
    var bad: Array[String] = []
    for path in [
            "res://assets/sprites/enemies/kkokdu_guide/idle.png",
            "res://assets/sprites/enemies/kkokdu_general/idle.png",
            "res://assets/sprites/enemies/sangyeogwi/idle.png",
            "res://assets/tilesets/snow_pine.png"]:
        var tex := load(path) as Texture2D
        if tex == null or tex.get_image().get_pixel(0, 0).a > 0.01:
            bad.append("%s 모서리 투명도 실패" % path)
    return {"name": "핵심아트_투명배경", "status": PASS if bad.is_empty() else FAIL,
        "reason": ", ".join(bad)}


func _check_size_ladder() -> Dictionary:
    var mob := _screen_height("KkokduGuide")
    var mid := _screen_height("KkokduGeneral")
    var boss := _screen_height("Sangyeogwi")
    var ok := mob > 0.0 and mid > mob * 1.2 and mid < boss * 0.9
    return {"name": "잡몹_중간보스_보스_크기서열", "status": PASS if ok else FAIL,
        "reason": "잡몹=%.1f 중간=%.1f 보스=%.1f" % [mob, mid, boss]}


func _check_three_bells() -> Dictionary:
    var script := load("res://scripts/enemies/sangyeogwi.gd") as GDScript
    var src := script.get_source_code() if script else ""
    var ok := src.contains("range(3)") and src.contains("Sfx.FUNERAL_BELL") and src.contains("[\"一\", \"二\", \"三\"]")
    return {"name": "상여귀_세종_공격예고", "status": PASS if ok else FAIL,
        "reason": "세 번의 종/시각 카운트 구현이 누락됨"}


func _check_audio() -> Dictionary:
    var ok := ResourceLoader.exists("res://assets/audio/bgm/stage4.wav") and ResourceLoader.exists("res://assets/audio/sfx/funeral_bell.wav")
    return {"name": "4스테이지_BGM_상여종", "status": PASS if ok else FAIL,
        "reason": "stage4.wav 또는 funeral_bell.wav 없음"}


func _screen_height(scene_name: String) -> float:
    var packed := load("res://scenes/enemies/%s.tscn" % scene_name) as PackedScene
    if packed == null:
        return 0.0
    var inst := packed.instantiate()
    var sprite := inst.get_node_or_null("Sprite2D")
    if sprite == null:
        inst.free()
        return 0.0
    var manifest := SpriteDb.manifest(String(sprite.get("sheet")))
    var texture := load("res://assets/sprites/%s/idle.png" % String(sprite.get("sheet"))) as Texture2D
    var fw := int(manifest.get("frame_w", 0))
    var fh := int(manifest.get("frame_h", 0))
    var image := Image.create(fw, fh, false, texture.get_image().get_format())
    image.blit_rect(texture.get_image(), Rect2i(0, 0, fw, fh), Vector2i.ZERO)
    var height := float(image.get_used_rect().size.y) * float(sprite.get("sprite_scale"))
    inst.free()
    return height


func _json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    return parsed if parsed is Dictionary else {}
