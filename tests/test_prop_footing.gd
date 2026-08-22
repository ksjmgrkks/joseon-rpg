extends Node
##
## 지형지물(props) '바닥 정렬' 검증 (헤드리스).
## 실행: `godot --headless res://tests/test_prop_footing.tscn`
##
## 2026-08-22부터 stage.gd가 JSON의 옛 수동 offset 대신 Stage.ground_align_offset()으로
## 실제 알파 하단을 계산한다. 이미지 크기가 바뀌는 리마스터 뒤에도 이 런타임 공식으로
## 바닥이 정확히 맞는지, 사고가 잦았던 자연물 5종을 전체 JSON에서 별도로 고정한다.
##

const PASS := "PASS"
const FAIL := "FAIL"
const TOLERANCE := 4.0    # px
const GROUND_TOP := 684.0
# 바닥에 서 있어야 하는 소품 텍스처만 검증 대상으로 삼는다(위 사고 기록 참고).
const GROUNDED_TEX := ["boulder", "boulder_moss", "reed", "driftwood", "seokdeung"]


func _ready() -> void:
    print("=== test_prop_footing ===")
    var textures := {}
    for tex in GROUNDED_TEX:
        var path := "res://assets/tilesets/%s.png" % tex
        if not ResourceLoader.exists(path):
            print("[FAIL] prop_footing\n  reason: %s.png 로드 실패" % tex)
            get_tree().quit(1)
            return
        textures[tex] = load(path)

    var bad: Array[String] = []
    var checked := 0
    var dir := DirAccess.open("res://assets/stages")
    if dir == null:
        print("[FAIL] prop_footing\n  reason: assets/stages 를 열 수 없음")
        get_tree().quit(1)
        return
    for f in dir.get_files():
        if not f.ends_with(".json"):
            continue
        var path := "res://assets/stages/%s" % f
        var text := FileAccess.get_file_as_string(path)
        var data = JSON.parse_string(text)
        if not (data is Dictionary):
            continue
        for p in data.get("props", []):
            if not (p is Dictionary):
                continue
            var tex := String(p.get("tex", ""))
            if not textures.has(tex) or bool(p.get("free_offset", false)):
                continue
            checked += 1
            var texture: Texture2D = textures[tex]
            var used := texture.get_image().get_used_rect()
            var scale := float(p.get("scale", 1.0))
            var off := Stage.ground_align_offset(texture)
            var y := float(p.get("y", GROUND_TOP))
            var bottom := y + scale * (off.y + float(used.position.y + used.size.y))
            var gap := bottom - y
            if absf(gap) > TOLERANCE:
                bad.append("%s: %s(scale %.1f) 바닥이 지면에서 %+.0fpx 어긋남" % [f, tex, scale, gap])

    if checked == 0:
        print("[FAIL] prop_footing\n  reason: 검증 대상 소품이 하나도 없음(스테이지 JSON 확인 필요)")
        get_tree().quit(1)
        return
    if not bad.is_empty():
        print("[FAIL] prop_footing")
        for b in bad:
            print("  reason: %s" % b)
        print("=== 0/1 passed (%d개 검사) ===" % checked)
        get_tree().quit(1)
        return
    print("[PASS] prop_footing (%d개 검사, 전부 지면에 정렬)" % checked)
    print("=== 1/1 passed ===")
    get_tree().quit(0)
