extends Node
##
## 지형지물(props) '바닥 정렬' 검증 (헤드리스).
## 실행: `godot --headless res://tests/test_prop_footing.tscn`
##
## 2026-08-20 사고: 사용자 신고 "지형지물이 바닥을 뚫고 간다". 실측해보니 boulder/boulder_moss
## 소품이 모든 스테이지(12개 JSON, 34곳)에서 offset [-64,-64] 를 그대로 썼는데, 이건 128×128
## "캔버스 절반"일 뿐 실제 그림(get_used_rect)의 바닥과 무관해서 지면선보다 44~82px 더 깊이
## 파묻혀 있었다. offset.y = -(used.y + used.h) 로 바꾸면 스케일에 무관하게 바닥이 y 위치에
## 정확히 맞는다(test_enemy_footing 의 발끝 정렬과 같은 원리, 소품용).
##
## 다른 소품(jangseung/sotdae/well/lantern 등)은 인스턴스마다 offset 이 여러 종류라
## 수작업으로 다르게 배치된 것으로 보여 여기 대상에서 뺐다 — 눈으로 확인 후 필요하면 추가.
##

const PASS := "PASS"
const FAIL := "FAIL"
const TOLERANCE := 4.0    # px
const GROUND_TOP := 684.0
# 바닥에 서 있어야 하는 소품 텍스처만 검증 대상으로 삼는다(위 사고 기록 참고).
const GROUNDED_TEX := ["boulder", "boulder_moss"]


func _ready() -> void:
    print("=== test_prop_footing ===")
    var used_rects := {}
    for tex in GROUNDED_TEX:
        var img := Image.load_from_file("res://assets/tilesets/%s.png" % tex)
        if img == null:
            print("[FAIL] prop_footing\n  reason: %s.png 로드 실패" % tex)
            get_tree().quit(1)
            return
        used_rects[tex] = img.get_used_rect()

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
            if not used_rects.has(tex):
                continue
            checked += 1
            var used: Rect2i = used_rects[tex]
            var scale := float(p.get("scale", 1.0))
            var off = p.get("offset", [0, 0])
            var off_y := float(off[1]) if off is Array and off.size() > 1 else 0.0
            var y := float(p.get("y", GROUND_TOP))
            var bottom := y + scale * (off_y + float(used.position.y + used.size.y))
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
