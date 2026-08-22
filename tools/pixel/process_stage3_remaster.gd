extends SceneTree
## 3스테이지 생성 원본(.art_gen/stage3)을 게임 규격으로 정리한다.
## - 전용 저잣거리 패럴랙스 3겹
## - 짚·기왓장·수레바퀴 자국이 섞인 256x224 지면 atlas
## - 3x3 소품 atlas 분리
## - 도깨비불 6프레임을 일반 적 SpriteDb 규약으로 조립

const SRC := "res://.art_gen/stage3/"
const BG_OUT := "res://assets/sprites/bg/stage3/"
const TILE_OUT := "res://assets/tilesets/side/"
const PROP_OUT := "res://assets/tilesets/"
const FIRE_OUT := "res://assets/sprites/enemies/dokkaebi_fire/"
const MINION_OUT := "res://assets/sprites/enemies/dokkaebi_minion/"
const BRUTE_OUT := "res://assets/sprites/enemies/dokkaebi_brute/"


func _init() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BG_OUT))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FIRE_OUT))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MINION_OUT))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BRUTE_OUT))
    _build_background("market_far_source.png", "far.png", Vector2i(640, 190))
    _build_background("market_mid_source.png", "mid.png", Vector2i(640, 220))
    _build_background("market_near_source.png", "near.png", Vector2i(640, 150))
    _build_terrain("market_ground_source.png", "market.png")
    _extract_grid("market_props_source.png", 3, 3, [
        {"name": "market_stall_broken.png", "cell": 0, "size": Vector2i(112, 92)},
        {"name": "market_stall_canopy.png", "cell": 1, "size": Vector2i(112, 92)},
        {"name": "market_cart_broken.png", "cell": 2, "size": Vector2i(112, 84)},
        {"name": "market_well.png", "cell": 3, "size": Vector2i(88, 88)},
        {"name": "ssireum_ring.png", "cell": 4, "size": Vector2i(120, 52)},
        {"name": "market_goods.png", "cell": 5, "size": Vector2i(88, 84)},
        {"name": "market_scale.png", "cell": 6, "size": Vector2i(96, 76)},
        {"name": "dokkaebi_brazier.png", "cell": 7, "size": Vector2i(72, 88)},
        {"name": "market_banner.png", "cell": 8, "size": Vector2i(48, 104)},
    ])
    _build_dokkaebi_fire("dokkaebi_fire_source.png")
    _build_pose_character("dokkaebi_minion_source.png", MINION_OUT, 80, Vector2i(68, 74))
    _build_pose_character("dokkaebi_brute_source.png", BRUTE_OUT, 128, Vector2i(116, 120))
    print("[Stage3Remaster] backdrop 3, terrain 1, props 9, enemy sheets 3 exported")
    quit()


func _load_rgba(path: String) -> Image:
    var image := Image.load_from_file(path)
    if image == null or image.is_empty():
        push_error("[Stage3Remaster] cannot load %s" % path)
        return Image.create(1, 1, false, Image.FORMAT_RGBA8)
    image.convert(Image.FORMAT_RGBA8)
    _matte_generated_checkerboard(image)
    return image


## 이미지 생성기가 알파 대신 그린 흰/연회색 체크무늬를 투명도로 바꾼다.
## 차가운 청색 불꽃의 밝은 외곽은 B 채널 우세라 보존된다.
func _matte_generated_checkerboard(image: Image) -> void:
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            var c := image.get_pixel(x, y)
            var hi := maxf(c.r, maxf(c.g, c.b))
            var lo := minf(c.r, minf(c.g, c.b))
            if lo >= 0.875 and hi - lo <= 0.05:
                image.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))


func _save(image: Image, path: String) -> void:
    var err := image.save_png(path)
    if err != OK:
        push_error("[Stage3Remaster] cannot save %s: %s" % [path, err])


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
    var surface_y: int = maxi(0, top_y - segment_w / 4)
    var surface_h: int = mini(source.get_height() - surface_y, segment_w)
    for i in range(8):
        var sx: int = mini(i * segment_w, source.get_width() - segment_w)
        var surface := source.get_region(Rect2i(sx, surface_y, segment_w, surface_h))
        surface.resize(32, 32, Image.INTERPOLATE_NEAREST)
        atlas.blit_rect(surface, Rect2i(0, 0, 32, 32), Vector2i(i * 32, 0))
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
        _fit_prop(source.get_region(rect), spec["size"], String(spec["name"]))


func _fit_prop(cell: Image, canvas_size: Vector2i, output_name: String) -> void:
    var fitted := _fit_cell(cell, canvas_size, Vector2i(canvas_size.x - 4, canvas_size.y - 4))
    _save(fitted, PROP_OUT + output_name)


func _fit_cell(cell: Image, canvas_size: Vector2i, content_room: Vector2i, scale_mult: float = 1.0) -> Image:
    var used := cell.get_used_rect()
    var canvas := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
    canvas.fill(Color(0, 0, 0, 0))
    if used.size.x <= 0 or used.size.y <= 0:
        return canvas
    var padded := used.grow(4).intersection(Rect2i(Vector2i.ZERO, cell.get_size()))
    var cropped := cell.get_region(padded)
    var scale := minf(float(content_room.x) / cropped.get_width(), float(content_room.y) / cropped.get_height()) * scale_mult
    var size := Vector2i(
        maxi(1, int(round(cropped.get_width() * scale))),
        maxi(1, int(round(cropped.get_height() * scale))))
    cropped.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
    var at := Vector2i((canvas_size.x - size.x) / 2, canvas_size.y - size.y)
    canvas.blit_rect(cropped, Rect2i(Vector2i.ZERO, size), at)
    return canvas


func _build_dokkaebi_fire(source_name: String) -> void:
    var source := _load_rgba(SRC + source_name)
    var cells: Array[Image] = []
    var cell_w: int = source.get_width() / 3
    var cell_h: int = source.get_height() / 2
    for index in range(6):
        var rect := Rect2i((index % 3) * cell_w, (index / 3) * cell_h, cell_w, cell_h)
        cells.append(source.get_region(rect))
    _save_strip("idle.png", cells, Vector2i(46, 52), 1.0, false)
    _save_strip("walk.png", cells, Vector2i(48, 54), 1.0, false)
    _save_strip("telegraph.png", [cells[0], cells[2], cells[4]], Vector2i(52, 58), 1.0, false)
    _save_strip("attack.png", cells, Vector2i(58, 62), 1.0, false)
    var death_cells: Array[Image] = []
    for i in range(6):
        death_cells.append(cells[5 - i])
    _save_strip("death.png", death_cells, Vector2i(48, 54), 1.0, true)
    var manifest := {
        "frame_w": 64,
        "frame_h": 64,
        "anims": {
            "idle": {"frames": 6, "fps": 8, "loop": true},
            "walk": {"frames": 6, "fps": 11, "loop": true},
            "telegraph": {"frames": 3, "fps": 8, "loop": true},
            "attack": {"frames": 6, "fps": 14, "loop": false},
            "death": {"frames": 6, "fps": 12, "loop": false},
        },
    }
    var file := FileAccess.open(FIRE_OUT + "manifest.json", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(manifest, "  "))
        file.close()


func _save_strip(output_name: String, cells: Array[Image], content_room: Vector2i,
        scale_mult: float, fade: bool) -> void:
    var strip := Image.create(64 * cells.size(), 64, false, Image.FORMAT_RGBA8)
    strip.fill(Color(0, 0, 0, 0))
    for i in range(cells.size()):
        var frame_scale := scale_mult * (1.0 - 0.11 * i if fade else 1.0)
        var frame := _fit_cell(cells[i], Vector2i(64, 64), content_room, frame_scale)
        if fade:
            _multiply_alpha(frame, 1.0 - 0.14 * i)
        strip.blit_rect(frame, Rect2i(0, 0, 64, 64), Vector2i(i * 64, 0))
    _save(strip, FIRE_OUT + output_name)


func _multiply_alpha(image: Image, mult: float) -> void:
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            var c := image.get_pixel(x, y)
            if c.a > 0.0:
                c.a *= mult
                image.set_pixel(x, y, c)


## 3x3 포즈 atlas(3 idle / 3 walk / warn / attack / death)를 SpriteDb 가 읽는 가로 strip으로 바꾼다.
## 모든 포즈에 같은 기준 스케일을 써서, 방망이가 옆으로 뻗는 공격 프레임만 작아지는 일을 막는다.
func _build_pose_character(source_name: String, output_dir: String, frame_size: int,
        content_room: Vector2i) -> void:
    var source := _load_rgba(SRC + source_name)
    var cells: Array[Image] = []
    var cell_w: int = source.get_width() / 3
    var cell_h: int = source.get_height() / 3
    var reference := Vector2i.ONE
    for index in range(9):
        var rect := Rect2i((index % 3) * cell_w, (index / 3) * cell_h, cell_w, cell_h)
        var cell := source.get_region(rect)
        cells.append(cell)
        var used := cell.get_used_rect().grow(4).intersection(Rect2i(Vector2i.ZERO, cell.get_size()))
        reference.x = maxi(reference.x, used.size.x)
        reference.y = maxi(reference.y, used.size.y)
    _save_pose_strip(output_dir + "idle.png", cells, [0, 1, 2, 1], frame_size, content_room, reference)
    _save_pose_strip(output_dir + "walk.png", cells, [3, 4, 5, 4, 3, 5], frame_size, content_room, reference)
    _save_pose_strip(output_dir + "telegraph.png", cells, [6, 6, 0], frame_size, content_room, reference)
    _save_pose_strip(output_dir + "attack.png", cells, [6, 7, 7, 1], frame_size, content_room, reference)
    _save_pose_strip(output_dir + "death.png", cells, [0, 8, 8, 8], frame_size, content_room, reference)
    var manifest := {
        "frame_w": frame_size,
        "frame_h": frame_size,
        "anims": {
            "idle": {"frames": 4, "fps": 5, "loop": true},
            "walk": {"frames": 6, "fps": 10, "loop": true},
            "telegraph": {"frames": 3, "fps": 7, "loop": true},
            "attack": {"frames": 4, "fps": 12, "loop": false},
            "death": {"frames": 4, "fps": 8, "loop": false},
        },
    }
    var file := FileAccess.open(output_dir + "manifest.json", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(manifest, "  "))
        file.close()


func _save_pose_strip(path: String, cells: Array[Image], sequence: Array, frame_size: int,
        content_room: Vector2i, reference: Vector2i) -> void:
    var strip := Image.create(frame_size * sequence.size(), frame_size, false, Image.FORMAT_RGBA8)
    strip.fill(Color(0, 0, 0, 0))
    for i in range(sequence.size()):
        var cell: Image = cells[int(sequence[i])]
        var frame := _fit_pose(cell, frame_size, content_room, reference)
        strip.blit_rect(frame, Rect2i(0, 0, frame_size, frame_size), Vector2i(i * frame_size, 0))
    _save(strip, path)


func _fit_pose(cell: Image, frame_size: int, content_room: Vector2i, reference: Vector2i) -> Image:
    var canvas := Image.create(frame_size, frame_size, false, Image.FORMAT_RGBA8)
    canvas.fill(Color(0, 0, 0, 0))
    var used := cell.get_used_rect().grow(4).intersection(Rect2i(Vector2i.ZERO, cell.get_size()))
    if used.size.x <= 0 or used.size.y <= 0:
        return canvas
    var cropped := cell.get_region(used)
    var scale := minf(float(content_room.x) / reference.x, float(content_room.y) / reference.y)
    var size := Vector2i(maxi(1, int(round(cropped.get_width() * scale))),
        maxi(1, int(round(cropped.get_height() * scale))))
    cropped.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
    var at := Vector2i((frame_size - size.x) / 2, frame_size - size.y)
    canvas.blit_rect(cropped, Rect2i(Vector2i.ZERO, size), at)
    return canvas
