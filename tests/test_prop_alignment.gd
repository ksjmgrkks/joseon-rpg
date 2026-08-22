extends Node
##
## 소품 바닥 정렬 검증 (2026-08-22 사용자 지적: "오브제가 공중에 뜨거나 바닥을 뚫는다").
## 실행: `godot --headless res://tests/test_prop_alignment.tscn`
##
## 검사식: 소품 스프라이트의 **보이는 부분 아래 끝(월드 y)** 이 JSON 에 적힌 y 와 같아야 한다.
##   보이는 아래 끝 = node.y + (offset.y + 불투명영역_아래끝) * scale.y
## 손으로 적던 offset 을 stage.gd 가 계산하도록 바꾼 뒤로는 항상 0 이어야 한다.
##

const PASS := "PASS"
const FAIL := "FAIL"
const TOLERANCE := 1.0     # px
## 검사할 스테이지(1·2·3스테이지 전 굽이)
const STAGES := [
    "foothills", "forest_deep", "mountain_pass", "ruined_temple", "sacred_altar",
    "forest_shadow", "forest_mist", "withered_hollow", "wailing_thicket", "elder_hollow",
    "market_ruins", "broken_stalls", "well_court", "lantern_alley", "goblin_court",
]


func _ready() -> void:
    print("=== test_prop_alignment ===")
    var bad: Array[String] = []
    var checked := 0
    for stage_id in STAGES:
        var path := "res://assets/stages/%s.json" % stage_id
        if not FileAccess.file_exists(path):
            continue
        var f := FileAccess.open(path, FileAccess.READ)
        var data = JSON.parse_string(f.get_as_text())
        f.close()
        if not (data is Dictionary):
            continue
        for p in data.get("props", []):
            if not (p is Dictionary):
                continue
            if bool(p.get("free_offset", false)):
                continue                     # 의도적으로 띄운 소품은 검사 대상 아님
            var tex_path := "res://assets/tilesets/%s.png" % String(p.get("tex", ""))
            if not ResourceLoader.exists(tex_path):
                bad.append("%s: 텍스처 없음 %s" % [stage_id, p.get("tex", "")])
                continue
            var tex: Texture2D = load(tex_path)
            var img := tex.get_image()
            var used := img.get_used_rect()
            var scale := float(p.get("scale", 1.0))
            var y := float(p.get("y", 684))
            var off := Stage.ground_align_offset(tex)
            # 그려지는 아래 끝의 월드 좌표
            var bottom: float = y + (off.y + float(used.position.y + used.size.y)) * scale
            checked += 1
            if absf(bottom - y) > TOLERANCE:
                bad.append("%s/%s: 바닥이 %.1f px 어긋남" % [stage_id, p.get("tex", ""), bottom - y])
    if bad.is_empty():
        print("[%s] 소품_바닥_정렬 (%d개 검사)" % [PASS, checked])
        print("=== 1/1 passed ===")
        get_tree().quit(0)
        return
    print("[%s] 소품_바닥_정렬" % FAIL)
    for b in bad:
        print("  reason: %s" % b)
    print("=== 0/1 passed ===")
    get_tree().quit(1)
