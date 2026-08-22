extends SceneTree
## Stage 1 생성 원본(.art_gen/stage1)을 실제 게임 규격으로 정리한다.
## - 지면: 256x224, 표면 8변형 + 연속 속재질 256x192
## - 배경: 640px 폭의 원/중/근경 투명 패럴랙스 레이어
## - 소품: 생성 시트 셀을 분리하고 각 게임 캔버스에 바닥 정렬

const SRC := "res://.art_gen/stage1/"
const BG_OUT := "res://assets/sprites/bg/stage1/"
const TILE_OUT := "res://assets/tilesets/side/"
const PROP_OUT := "res://assets/tilesets/"


func _init() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BG_OUT))
    _build_background("mtn_far_source.png", "far.png", Vector2i(640, 180))
    _build_background("mtn_mid_source.png", "mid.png", Vector2i(640, 220))
    _build_background("mtn_near_source.png", "near.png", Vector2i(640, 160))

    _build_terrain("earth_source.png", "earth.png")
    _build_terrain("cliff_source.png", "cliff.png")
    _build_terrain("ruins_source.png", "ruins.png")

    _extract_grid("forest_props_source.png", 3, 3, [
        {"name": "pine.png", "cell": 0, "size": Vector2i(64, 104)},
        {"name": "dead_tree.png", "cell": 1, "size": Vector2i(72, 104)},
        {"name": "dead_tree_tall.png", "cell": 2, "size": Vector2i(72, 120)},
        {"name": "boulder.png", "cell": 3, "size": Vector2i(80, 56)},
        {"name": "boulder_moss.png", "cell": 4, "size": Vector2i(80, 56)},
        {"name": "reed.png", "cell": 5, "size": Vector2i(56, 72)},
        {"name": "driftwood.png", "cell": 6, "size": Vector2i(72, 36)},
    ])
    _extract_grid("ritual_props_source.png", 3, 2, [
        {"name": "jangseung.png", "cell": 0, "size": Vector2i(32, 72)},
        {"name": "sotdae.png", "cell": 1, "size": Vector2i(24, 80)},
        {"name": "shrine_ruin.png", "cell": 2, "size": Vector2i(96, 80)},
        {"name": "seokdeung.png", "cell": 3, "size": Vector2i(40, 72)},
        {"name": "lantern.png", "cell": 4, "size": Vector2i(24, 40)},
        {"name": "mul_deung.png", "cell": 5, "size": Vector2i(64, 48)},
    ])
    print("[Stage1Remaster] terrain 3, backdrop 3, props 13 exported")
    quit()


func _load_rgba(path: String) -> Image:
    var image := Image.load_from_file(path)
    if image == null or image.is_empty():
        push_error("[Stage1Remaster] cannot load %s" % path)
        return Image.create(1, 1, false, Image.FORMAT_RGBA8)
    image.convert(Image.FORMAT_RGBA8)
    _matte_generated_checkerboard(image)
    return image


## 생성기가 알파 대신 넣은 흰/연회색 체크무늬를 실제 투명도로 바꾼다.
## 체크 셀은 RGB 세 채널이 모두 매우 밝고 거의 같은 중성색이다. 한지·석재 하이라이트는
## 채도가 있거나 더 어두워 남기 때문에, 소품 내부 디테일을 지우지 않는다.
func _matte_generated_checkerboard(image: Image) -> void:
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            var c := image.get_pixel(x, y)
            var hi := maxf(c.r, maxf(c.g, c.b))
            var lo := minf(c.r, minf(c.g, c.b))
            if lo >= 0.88 and hi - lo <= 0.045:
                image.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))


func _save(image: Image, path: String) -> void:
    var err := image.save_png(path)
    if err != OK:
        push_error("[Stage1Remaster] cannot save %s: %s" % [path, err])


func _build_background(source_name: String, output_name: String, size: Vector2i) -> void:
    var source := _load_rgba(SRC + source_name)
    var used := source.get_used_rect()
    if used.size.x <= 0 or used.size.y <= 0:
        return
    var cropped := source.get_region(used)
    cropped.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
    _save(cropped, BG_OUT + output_name)


func _build_terrain(source_name: String, output_name: String) -> void:
    var source := _load_rgba(SRC + source_name)
    var used := source.get_used_rect()
    if used.size.x <= 0 or used.size.y <= 0:
        return
    var atlas := Image.create(256, 224, false, Image.FORMAT_RGBA8)
    atlas.fill(Color(0, 0, 0, 0))
    var segment_w: int = maxi(32, source.get_width() / 8)
    var top_y: int = used.position.y
    # 가장 높은 풀잎 위의 여백부터 흙 윗부분까지 담아 표면 실루엣을 살린다.
    var surface_y: int = maxi(0, top_y - segment_w / 4)
    var surface_h: int = mini(source.get_height() - surface_y, segment_w)
    for i in range(8):
        var sx: int = mini(i * segment_w, source.get_width() - segment_w)
        var surface := source.get_region(Rect2i(sx, surface_y, segment_w, surface_h))
        surface.resize(32, 32, Image.INTERPOLATE_NEAREST)
        atlas.blit_rect(surface, Rect2i(0, 0, 32, 32), Vector2i(i * 32, 0))
    # 속재질은 셀 조각을 이어 붙이지 않고 깊은 원본 한 덩어리를 축소한다.
    # 이 방식이면 32px 경계에서 밝기·층리가 끊기지 않는다.
    var fill_start: int = mini(source.get_height() - 192, top_y + segment_w)
    var fill := source.get_region(Rect2i(0, fill_start, source.get_width(), source.get_height() - fill_start))
    fill.resize(256, 192, Image.INTERPOLATE_NEAREST)
    atlas.blit_rect(fill, Rect2i(0, 0, 256, 192), Vector2i(0, 32))
    _save(atlas, TILE_OUT + output_name)


func _extract_grid(source_name: String, cols: int, rows: int, specs: Array) -> void:
    var source := _load_rgba(SRC + source_name)
    var cell_w: int = source.get_width() / cols
    var cell_h: int = source.get_height() / rows
    for spec in specs:
        var index: int = int(spec["cell"])
        var rect := Rect2i((index % cols) * cell_w, (index / cols) * cell_h, cell_w, cell_h)
        var cell := source.get_region(rect)
        _fit_prop(cell, spec["size"], String(spec["name"]))


func _fit_prop(cell: Image, canvas_size: Vector2i, output_name: String) -> void:
    var used := cell.get_used_rect()
    if used.size.x <= 0 or used.size.y <= 0:
        return
    # 희미한 외곽 픽셀이 잘리지 않을 만큼만 여백을 남긴다.
    var padded := used.grow(4).intersection(Rect2i(Vector2i.ZERO, cell.get_size()))
    var cropped := cell.get_region(padded)
    var room := Vector2i(maxi(1, canvas_size.x - 4), maxi(1, canvas_size.y - 4))
    var scale := minf(float(room.x) / cropped.get_width(), float(room.y) / cropped.get_height())
    var fitted := Vector2i(
        maxi(1, int(round(cropped.get_width() * scale))),
        maxi(1, int(round(cropped.get_height() * scale))))
    cropped.resize(fitted.x, fitted.y, Image.INTERPOLATE_NEAREST)
    var canvas := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
    canvas.fill(Color(0, 0, 0, 0))
    var at := Vector2i((canvas_size.x - fitted.x) / 2, canvas_size.y - fitted.y)
    canvas.blit_rect(cropped, Rect2i(Vector2i.ZERO, fitted), at)
    _save(canvas, PROP_OUT + output_name)
