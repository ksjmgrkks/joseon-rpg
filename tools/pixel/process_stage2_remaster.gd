extends SceneTree
## Stage 2 생성 원본(.art_gen/stage2)을 실제 게임 규격으로 정리한다.
## - 지면: 256x224, 표면 8변형 + 연속 뿌리 속재질
## - 배경: 640px 폭의 원/중/근경 투명 패럴랙스 레이어
## - 소품: 생성 시트 셀을 스테이지 전용 하위 폴더로 분리하고 바닥 정렬

const SRC := "res://.art_gen/stage2/"
const BG_OUT := "res://assets/sprites/bg/stage2/"
const TILE_OUT := "res://assets/tilesets/side/"
const PROP_OUT := "res://assets/tilesets/stage2/"


func _init() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BG_OUT))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PROP_OUT))

    _build_background("mtn_far_source.png", "far.png", Vector2i(640, 180))
    _build_background("mtn_mid_source.png", "mid.png", Vector2i(640, 240))
    _build_background("mtn_near_source.png", "near.png", Vector2i(640, 180))
    _build_terrain("shadow_forest_source.png", "shadow_forest.png")

    _extract_grid("forest_props_source.png", 3, 3, [
        {"name": "pine_crooked.png", "cell": 0, "size": Vector2i(80, 120)},
        {"name": "pine_split.png", "cell": 1, "size": Vector2i(80, 120)},
        {"name": "root_arch.png", "cell": 2, "size": Vector2i(112, 72)},
        {"name": "root_platform.png", "cell": 2, "size": Vector2i(96, 32)},
        {"name": "boulder_slate.png", "cell": 3, "size": Vector2i(80, 72)},
        {"name": "thorn_brush.png", "cell": 4, "size": Vector2i(96, 72)},
        {"name": "shadow_puddle.png", "cell": 5, "size": Vector2i(128, 40)},
        {"name": "sotdae_broken.png", "cell": 6, "size": Vector2i(48, 96)},
        {"name": "jangseung_broken.png", "cell": 7, "size": Vector2i(48, 96)},
        {"name": "backward_footprints.png", "cell": 8, "size": Vector2i(96, 48)},
    ])
    _extract_grid("ritual_props_source.png", 3, 2, [
        {"name": "seonang_cairn.png", "cell": 0, "size": Vector2i(112, 96)},
        {"name": "straw_effigy.png", "cell": 1, "size": Vector2i(64, 104)},
        {"name": "geumjul_ruin.png", "cell": 2, "size": Vector2i(128, 80)},
        {"name": "stone_lantern_unlit.png", "cell": 3, "size": Vector2i(56, 104)},
        {"name": "offering_bowl.png", "cell": 4, "size": Vector2i(80, 48)},
        {"name": "sacred_stump.png", "cell": 5, "size": Vector2i(144, 128)},
    ])
    print("[Stage2Remaster] terrain 1, backdrop 3, props 16 exported")
    quit()


func _load_rgba(path: String, matte_background: bool) -> Image:
    var image := Image.load_from_file(path)
    if image == null or image.is_empty():
        push_error("[Stage2Remaster] cannot load %s" % path)
        return Image.create(1, 1, false, Image.FORMAT_RGBA8)
    image.convert(Image.FORMAT_RGBA8)
    if matte_background:
        _matte_edge_background(image)
    return image


## 생성기가 실제 알파 대신 흰/연회색 체크무늬를 넣었다. 단순 색상 삭제는 소품의
## 한지·삼베까지 지우므로, 이미지 바깥과 이어진 밝은 중성색 영역만 flood-fill로 제거한다.
func _matte_edge_background(image: Image) -> void:
    var w := image.get_width()
    var h := image.get_height()
    var seen := PackedByteArray()
    seen.resize(w * h)
    var queue: Array[Vector2i] = []
    for x in range(w):
        _enqueue_matte(image, Vector2i(x, 0), seen, queue)
        _enqueue_matte(image, Vector2i(x, h - 1), seen, queue)
    for y in range(h):
        _enqueue_matte(image, Vector2i(0, y), seen, queue)
        _enqueue_matte(image, Vector2i(w - 1, y), seen, queue)
    var head := 0
    while head < queue.size():
        var p := queue[head]
        head += 1
        var c := image.get_pixelv(p)
        image.set_pixelv(p, Color(c.r, c.g, c.b, 0.0))
        _enqueue_matte(image, p + Vector2i(1, 0), seen, queue)
        _enqueue_matte(image, p + Vector2i(-1, 0), seen, queue)
        _enqueue_matte(image, p + Vector2i(0, 1), seen, queue)
        _enqueue_matte(image, p + Vector2i(0, -1), seen, queue)


func _enqueue_matte(image: Image, p: Vector2i, seen: PackedByteArray, queue: Array[Vector2i]) -> void:
    var w := image.get_width()
    var h := image.get_height()
    if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
        return
    var idx := p.y * w + p.x
    if seen[idx] != 0:
        return
    seen[idx] = 1
    var c := image.get_pixelv(p)
    var hi := maxf(c.r, maxf(c.g, c.b))
    var lo := minf(c.r, minf(c.g, c.b))
    # gpt-image가 체크무늬 위에 아주 옅은 회색 그라데이션까지 굽는 경우가 있어
    # 흰색만 잡으면 사각 테두리가 남는다. 바깥과 이어진 저채도 밝은색 전체를 배경으로 본다.
    if lo >= 0.72 and hi - lo <= 0.10:
        queue.append(p)


func _save(image: Image, path: String) -> void:
    var err := image.save_png(ProjectSettings.globalize_path(path))
    if err != OK:
        push_error("[Stage2Remaster] cannot save %s: %s" % [path, err])


func _build_background(source_name: String, output_name: String, size: Vector2i) -> void:
    var source := _load_rgba(SRC + source_name, true)
    if source_name != "mtn_far_source.png":
        _remove_light_neutral(source, 0.68, 0.16)
    var used := source.get_used_rect()
    if used.size.x <= 0 or used.size.y <= 0:
        return
    var cropped := source.get_region(used)
    cropped.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
    _save(cropped, BG_OUT + output_name)


func _build_terrain(source_name: String, output_name: String) -> void:
    var source := _load_rgba(SRC + source_name, false)
    var atlas := Image.create(256, 224, false, Image.FORMAT_RGBA8)
    atlas.fill(Color(0, 0, 0, 0))
    var segment_w: int = maxi(32, source.get_width() / 8)
    var surface_y: int = int(source.get_height() * 0.025)
    var surface_h: int = int(source.get_height() * 0.23)
    for i in range(8):
        var sx: int = mini(i * segment_w, source.get_width() - segment_w)
        var surface := source.get_region(Rect2i(sx, surface_y, segment_w, surface_h))
        surface.resize(32, 32, Image.INTERPOLATE_NEAREST)
        atlas.blit_rect(surface, Rect2i(0, 0, 32, 32), Vector2i(i * 32, 0))
    var fill_start: int = int(source.get_height() * 0.20)
    var fill := source.get_region(Rect2i(0, fill_start, source.get_width(), source.get_height() - fill_start))
    fill.resize(256, 192, Image.INTERPOLATE_NEAREST)
    atlas.blit_rect(fill, Rect2i(0, 0, 256, 192), Vector2i(0, 32))
    _save(atlas, TILE_OUT + output_name)


func _extract_grid(source_name: String, cols: int, rows: int, specs: Array) -> void:
    var source := _load_rgba(SRC + source_name, true)
    var cell_w: int = source.get_width() / cols
    var cell_h: int = source.get_height() / rows
    for spec in specs:
        var index: int = int(spec["cell"])
        var rect := Rect2i((index % cols) * cell_w, (index / cols) * cell_h, cell_w, cell_h)
        var cell := source.get_region(rect)
        _matte_edge_background(cell)
        _remove_light_neutral(cell, 0.82, 0.08)
        _fit_prop(cell, spec["size"], String(spec["name"]))


func _remove_light_neutral(image: Image, floor: float, spread: float) -> void:
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            var c := image.get_pixel(x, y)
            var hi := maxf(c.r, maxf(c.g, c.b))
            var lo := minf(c.r, minf(c.g, c.b))
            if lo >= floor and hi - lo <= spread:
                image.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))


func _fit_prop(cell: Image, canvas_size: Vector2i, output_name: String) -> void:
    var used := cell.get_used_rect()
    if used.size.x <= 0 or used.size.y <= 0:
        return
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
