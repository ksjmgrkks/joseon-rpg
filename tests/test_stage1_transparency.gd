extends Node
## 1스테이지 런타임 아트의 알파 품질 게이트.
## 생성기의 흰 배경/체크무늬가 다시 들어오거나, 프레임 전체가 불투명해지는 회귀를 막는다.

const PASS := "PASS"
const FAIL := "FAIL"

const SHEETS := [
    "protagonist_custom",
    "enemies/wraith",
    "enemies/dueoksini",
    "enemies/changgwi",
    "enemies/mulgwisin",
    "enemies/drowned_mudang",
    "enemies/flood_wraith",
]

const CUTOUTS := [
    ["res://assets/sprites/fx/gate_geumjul_release.png", 192, 208, 6],
    ["res://assets/sprites/fx/boss_geyser_spire.png", 0, 0, 1],
    ["res://assets/sprites/fx/water_pillar.png", 0, 0, 1],
    ["res://assets/sprites/fx/water_pillar_swirl.png", 0, 0, 1],
    ["res://assets/sprites/fx/tide_crest.png", 0, 0, 1],
    ["res://assets/tilesets/flood_pool_a.png", 0, 0, 1],
    ["res://assets/tilesets/flood_pool_b.png", 0, 0, 1],
    ["res://assets/tilesets/flood_pool_c.png", 0, 0, 1],
    ["res://assets/tilesets/pine.png", 0, 0, 1],
    ["res://assets/tilesets/dead_tree.png", 0, 0, 1],
    ["res://assets/tilesets/dead_tree_tall.png", 0, 0, 1],
    ["res://assets/tilesets/boulder.png", 0, 0, 1],
    ["res://assets/tilesets/boulder_moss.png", 0, 0, 1],
    ["res://assets/tilesets/reed.png", 0, 0, 1],
    ["res://assets/tilesets/driftwood.png", 0, 0, 1],
    ["res://assets/tilesets/jangseung.png", 0, 0, 1],
    ["res://assets/tilesets/sotdae.png", 0, 0, 1],
    ["res://assets/tilesets/shrine_ruin.png", 0, 0, 1],
    ["res://assets/tilesets/seokdeung.png", 0, 0, 1],
    ["res://assets/tilesets/lantern.png", 0, 0, 1],
    ["res://assets/tilesets/mul_deung.png", 0, 0, 1],
]

const MAP_LAYERS := [
    "res://assets/sprites/bg/stage1/far.png",
    "res://assets/sprites/bg/stage1/mid.png",
    "res://assets/sprites/bg/stage1/near.png",
    "res://assets/tilesets/side/earth.png",
    "res://assets/tilesets/side/cliff.png",
    "res://assets/tilesets/side/ruins.png",
]


func _ready() -> void:
    print("=== test_stage1_transparency ===")
    var issues: Array[String] = []
    for sheet in SHEETS:
        _check_sheet(sheet, issues)
    for spec in CUTOUTS:
        _check_cutout(String(spec[0]), int(spec[1]), int(spec[2]), int(spec[3]), issues)
    for path in MAP_LAYERS:
        _check_map_layer(path, issues)
    var status := PASS if issues.is_empty() else FAIL
    print("[%s] 1스테이지_알파_무결성" % status)
    for issue in issues:
        print("  reason: %s" % issue)
    print("=== %d/1 passed ===" % (1 if issues.is_empty() else 0))
    get_tree().quit(0 if issues.is_empty() else 1)


func _check_sheet(sheet: String, issues: Array[String]) -> void:
    var dir := "res://assets/sprites/%s" % sheet
    var manifest := SpriteDb.manifest(sheet)
    if manifest.is_empty():
        issues.append("매니페스트 없음: %s" % sheet)
        return
    var fw := int(manifest.get("frame_w", 0))
    var fh := int(manifest.get("frame_h", 0))
    for anim_name in (manifest.get("anims", {}) as Dictionary):
        var meta: Dictionary = manifest["anims"][anim_name]
        _check_cutout("%s/%s.png" % [dir, anim_name], fw, fh, int(meta.get("frames", 0)), issues)


func _check_cutout(path: String, frame_w: int, frame_h: int, frame_count: int,
        issues: Array[String]) -> void:
    var image := Image.load_from_file(ProjectSettings.globalize_path(path))
    if image == null or image.is_empty():
        issues.append("이미지 없음: %s" % path)
        return
    image.convert(Image.FORMAT_RGBA8)
    if frame_w <= 0:
        frame_w = image.get_width()
    if frame_h <= 0:
        frame_h = image.get_height()
    if frame_count <= 0 or image.get_width() != frame_w * frame_count or image.get_height() != frame_h:
        issues.append("프레임 규격 불일치: %s (%dx%d, %dx%dx%d 기대)" % [
            path, image.get_width(), image.get_height(), frame_w, frame_h, frame_count])
        return
    var transparent := 0
    var visible := 0
    var fractional := 0
    for y in image.get_height():
        for x in image.get_width():
            var alpha := image.get_pixel(x, y).a
            if alpha <= 0.001:
                transparent += 1
            else:
                visible += 1
                if alpha < 0.999:
                    fractional += 1
    if transparent == 0 or visible == 0:
        issues.append("투명/불투명 영역이 함께 있지 않음: %s" % path)
    # 이 프로젝트의 픽셀 컷아웃은 이진 알파다. 반투명 흰 매트 테두리를 허용하지 않는다.
    if fractional > 0:
        issues.append("반투명 매트 픽셀 %d개: %s" % [fractional, path])
    for i in frame_count:
        var x0 := i * frame_w
        var corners := [
            Vector2i(x0, 0), Vector2i(x0 + frame_w - 1, 0),
            Vector2i(x0, frame_h - 1), Vector2i(x0 + frame_w - 1, frame_h - 1),
        ]
        for corner in corners:
            if image.get_pixelv(corner).a > 0.001:
                issues.append("프레임 모서리가 불투명: %s #%d @ %s" % [path, i, str(corner)])
                break


func _check_map_layer(path: String, issues: Array[String]) -> void:
    var image := Image.load_from_file(ProjectSettings.globalize_path(path))
    if image == null or image.is_empty():
        issues.append("맵 레이어 없음: %s" % path)
        return
    image.convert(Image.FORMAT_RGBA8)
    var transparent := 0
    var visible := 0
    for y in image.get_height():
        for x in image.get_width():
            if image.get_pixel(x, y).a <= 0.001:
                transparent += 1
            else:
                visible += 1
    if transparent == 0 or visible == 0:
        issues.append("맵 레이어 알파가 단색임: %s" % path)
