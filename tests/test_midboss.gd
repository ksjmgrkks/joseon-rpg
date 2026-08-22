extends Node
##
## 중간보스 계약 검증 — 크기 서열 + 패턴 풀 격리.
## 실행: `godot --headless res://tests/test_midboss.tscn`
##
## 배경(2026-08-20 사용자 지적): "보스 전에 나오는 약한 보스들은 잡몹과 보스 사이 크기였으면".
## 진짜 원인은 CharacterVisual._ready() 가 노드 scale 을 sprite_scale 로 덮어써서
## .tscn 에 적어둔 확대가 런타임에 통째로 무시된 것 — 그래서 중간보스가 잡몹만 했다.
## 여기서는 '화면에 실제로 보이는 높이'(콘텐츠 높이 × sprite_scale)로 서열을 못박는다.
##

const PASS := "PASS"
const FAIL := "FAIL"

# 1스테이지(물·골짜기) / 2스테이지(그슨대 숲) 각각의 잡몹·중간보스·보스
const LADDER := {
    "1스테이지": {
        "mobs": ["Wraith", "Dueoksini", "DrownedChild", "Changgwi", "Mulgwisin"],
        "mid": "DrownedMudang",
        "boss": "FloodWraith",
    },
    "2스테이지": {
        "mobs": ["Geuseondae"],
        "mid": "Jangseung",
        "boss_sheet": "enemies/geuseondae_elder_shadow",   # 보스는 정체를 드러내야 커진다
    },
    "3스테이지": {
        "mobs": ["Dokkaebi"],
        "mid": "DokkaebiBrute",
        "boss": "DokkaebiChief",
    },
}
# 중간보스가 쓰면 안 되는 패턴 — 물기둥/밀물은 물 스테이지 전용 연출.
const FORBIDDEN := {"Jangseung": ["pillars", "wave"], "DokkaebiBrute": ["pillars", "wave"]}


func _ready() -> void:
    print("=== test_midboss ===")
    var results: Array[Dictionary] = []
    for stage in LADDER:
        results.append(_check_ladder(stage, LADDER[stage]))
    results.append(_check_pattern_pool())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _check_ladder(stage: String, spec: Dictionary) -> Dictionary:
    var biggest_mob := 0.0
    var worst := ""
    for m in spec["mobs"]:
        var h := _screen_height_of_scene(m)
        if h > biggest_mob:
            biggest_mob = h
            worst = m
    var mid := _screen_height_of_scene(spec["mid"])
    var boss := 0.0
    if spec.has("boss"):
        boss = _screen_height_of_scene(spec["boss"])
    else:
        boss = _content_height(String(spec["boss_sheet"]))
    var ok := mid > biggest_mob * 1.2 and mid < boss * 0.9
    var reason := "" if ok else "잡몹 최대 %s=%.0f / 중간보스 %s=%.0f / 보스=%.0f — 사이에 있지 않다" % [
        worst, biggest_mob, spec["mid"], mid, boss]
    return { "name": "%s_크기서열(잡몹<중간보스<보스)" % stage, "status": PASS if ok else FAIL, "reason": reason }


## 중간보스가 다른 스테이지 컨셉의 패턴을 물려받지 않았는지.
func _check_pattern_pool() -> Dictionary:
    var bad: Array[String] = []
    for scene_name in FORBIDDEN:
        var inst: Node = load("res://scenes/enemies/%s.tscn" % scene_name).instantiate()
        var pool: PackedStringArray = inst.pattern_pool
        if pool.is_empty():
            bad.append("%s: pattern_pool 이 비어 기본 물 패턴을 그대로 쓴다" % scene_name)
        for f in FORBIDDEN[scene_name]:
            for nm in pool:
                if String(nm).to_lower() == f:
                    bad.append("%s: 금지 패턴 %s 사용" % [scene_name, f])
        inst.free()
    return {
        "name": "중간보스_패턴풀_격리",
        "status": PASS if bad.is_empty() else FAIL,
        "reason": ", ".join(bad),
    }


## 화면에 실제로 보이는 높이 = idle 첫 프레임의 불투명 높이 × 런타임 실효 스케일.
func _screen_height_of_scene(scene_name: String) -> float:
    var packed: PackedScene = load("res://scenes/enemies/%s.tscn" % scene_name)
    if packed == null:
        return 0.0
    var inst := packed.instantiate()
    var spr := inst.get_node_or_null("Sprite2D")
    if spr == null:
        inst.free()
        return 0.0
    var sheet := String(spr.get("sheet"))
    var sc: float = float(spr.get("sprite_scale"))
    inst.free()
    return _content_height(sheet) * (sc if sc > 0.0 else 1.0)


func _content_height(sheet: String) -> float:
    var man := SpriteDb.manifest(sheet)
    var ipath := "res://assets/sprites/%s/idle.png" % sheet
    if man.is_empty() or not ResourceLoader.exists(ipath):
        return 0.0
    var fw := int(man.get("frame_w", 32))
    var fh := int(man.get("frame_h", 64))
    var img: Image = (load(ipath) as Texture2D).get_image()
    var frame := Image.create(fw, fh, false, img.get_format())
    frame.blit_rect(img, Rect2i(0, 0, fw, fh), Vector2i.ZERO)
    return float(frame.get_used_rect().size.y)
