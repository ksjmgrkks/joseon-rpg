extends SceneTree
##
## 4스테이지 「끊긴 상여길」 생성 원본을 실제 게임 규격으로 정리한다.
## - 일반 적 4종: 4x4 source atlas -> idle/walk/attack/death 단일 프레임 스트립
## - 중간보스/보스: 3x2 source atlas -> 상태별 스트립
## - 설경 패럴랙스: 1x3 source atlas -> far/mid/near
## - 소품: 3x3 source atlas -> 바닥 정렬용 독립 PNG 9종
## - 지면/선택 카드: snow atlas 256x224, card 160x160
##
## 생성기가 투명 요청에도 밝은 체크무늬/흰 배경을 굽는 경우가 있어, 밝고 무채색인
## 외부 배경만 이진 알파로 지운다. 어두운 외곽선으로 둘러싸인 한지·눈의 흰 면은
## flood-fill로 복구해 꽃/상복/적설이 함께 사라지는 문제를 막는다.
##

const SRC := "res://.art_gen/stage4/"
const ENEMY_OUT := "res://assets/sprites/enemies/"
const BG_OUT := "res://assets/sprites/bg/stage4/"
const PROP_OUT := "res://assets/tilesets/"
const TILE_OUT := "res://assets/tilesets/side/snow_pass.png"
const CARD_OUT := "res://assets/ui/stage_cards/stage4_funeral_pass.png"


func _init() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BG_OUT))
    for folder in ["kkokdu_guide", "kkokdu_acrobat", "pallbearer_shadow",
            "paper_flower_spirit", "kkokdu_general", "sangyeogwi"]:
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ENEMY_OUT + folder))

    _build_minions()
    _build_six_pose_sheet("midboss_source.png", "kkokdu_general", Vector2i(192, 160))
    _build_six_pose_sheet("boss_source.png", "sangyeogwi", Vector2i(320, 240))
    _build_backgrounds()
    _build_props()
    _build_terrain()
    _build_card()
    print("[Stage4Art] minions 4, midboss, boss, backdrop 3, props 9, terrain, card exported")
    quit()


func _build_minions() -> void:
    var source := _load_rgba(SRC + "minions_source.png", true)
    var rows := ["kkokdu_guide", "kkokdu_acrobat", "pallbearer_shadow", "paper_flower_spirit"]
    var names := ["idle", "walk", "attack", "death"]
    for row in range(rows.size()):
        for col in range(names.size()):
            var cell := _grid_cell(source, 4, 4, col, row)
            var frame := _fit_frame(cell, Vector2i(96, 96), 4)
            _save(frame, ENEMY_OUT + rows[row] + "/" + names[col] + ".png")


func _build_six_pose_sheet(source_name: String, folder: String, canvas_size: Vector2i) -> void:
    var source := _load_rgba(SRC + source_name, true)
    _save_strip(source, 3, 2, [0], canvas_size, ENEMY_OUT + folder + "/idle.png")
    _save_strip(source, 3, 2, [1], canvas_size, ENEMY_OUT + folder + "/walk.png")
    _save_strip(source, 3, 2, [2, 3, 4], canvas_size, ENEMY_OUT + folder + "/attack.png")
    _save_strip(source, 3, 2, [4], canvas_size, ENEMY_OUT + folder + "/telegraph.png")
    _save_strip(source, 3, 2, [5], canvas_size, ENEMY_OUT + folder + "/death.png")


func _save_strip(source: Image, cols: int, rows: int, cells: Array, canvas_size: Vector2i,
        out_path: String) -> void:
    var strip := Image.create(canvas_size.x * cells.size(), canvas_size.y, false, Image.FORMAT_RGBA8)
    strip.fill(Color(0, 0, 0, 0))
    for i in range(cells.size()):
        var index := int(cells[i])
        var cell := _grid_cell(source, cols, rows, index % cols, index / cols)
        var frame := _fit_frame(cell, canvas_size, 5)
        strip.blit_rect(frame, Rect2i(Vector2i.ZERO, canvas_size), Vector2i(i * canvas_size.x, 0))
    _save(strip, out_path)


func _build_backgrounds() -> void:
    var source := _load_rgba(SRC + "background_source.png", true)
    var specs := [
        {"name": "far.png", "size": Vector2i(640, 180)},
        {"name": "mid.png", "size": Vector2i(640, 220)},
        {"name": "near.png", "size": Vector2i(640, 180)},
    ]
    for row in range(3):
        var cell := _grid_cell(source, 1, 3, 0, row)
        var frame := _fit_frame(cell, specs[row]["size"], 0)
        if row == 0:
            _extract_single_moon(frame)
        # 생성 원본은 좌우 끝에 옅은 안개가 남아 반복 시 직사각형 경계가 보일 수 있다.
        # 레이어 가장자리를 투명하게 감쇠해 미러 타일 이음매를 설경 속으로 녹인다.
        _feather_horizontal(frame, 320)
        _feather_bottom(frame, 36)
        _save(frame, BG_OUT + String(specs[row]["name"]))


func _extract_single_moon(far_layer: Image) -> void:
    # 원경 strip 안의 달을 그대로 반복하면 한 화면에 초승달이 두세 개 뜬다.
    # 달만 별도 고정 레이어로 떼고, 반복되는 원경에서는 제거한다.
    var rect := Rect2i(122, 0, 84, 76).intersection(Rect2i(Vector2i.ZERO, far_layer.get_size()))
    # 원본 달 주변에 산안개가 이어져 있어 그대로 떼면 사각 잔상이 딸려온다.
    # 같은 팔레트의 또렷한 픽셀 초승달을 절차적으로 한 장만 만든다.
    var moon := Image.create(64, 64, false, Image.FORMAT_RGBA8)
    moon.fill(Color(0, 0, 0, 0))
    var center := Vector2(28, 31)
    var cutout := Vector2(36, 26)
    for y in range(64):
        for x in range(64):
            var p := Vector2(x, y)
            var in_outer := p.distance_to(center) <= 19.0
            var in_cutout := p.distance_to(cutout) <= 17.0
            if in_outer and not in_cutout:
                var shade := 0.82 + 0.08 * (1.0 - float(y) / 64.0)
                moon.set_pixel(x, y, Color(shade * 0.9, shade * 0.95, shade, 0.92))
    # 달 표면의 절제된 먹점 — 두세 픽셀만 두어 픽셀아트 질감을 유지한다.
    for point in [Vector2i(18, 24), Vector2i(20, 39), Vector2i(25, 45)]:
        moon.set_pixelv(point, Color(0.5, 0.58, 0.68, 0.72))
    _save(moon, BG_OUT + "moon.png")
    for y in range(rect.position.y, rect.end.y):
        for x in range(rect.position.x, rect.end.x):
            var c := far_layer.get_pixel(x, y)
            c.a = 0.0
            far_layer.set_pixel(x, y, c)


func _build_props() -> void:
    var source := _load_rgba(SRC + "props_source.png", true)
    var specs := [
        {"name": "snow_pine.png", "size": Vector2i(112, 128)},
        {"name": "snow_cairns.png", "size": Vector2i(104, 72)},
        {"name": "seonang_snow.png", "size": Vector2i(112, 128)},
        {"name": "bier_rest.png", "size": Vector2i(136, 76)},
        {"name": "mourning_banner.png", "size": Vector2i(48, 112)},
        {"name": "funeral_bells.png", "size": Vector2i(80, 112)},
        {"name": "unfinished_mound.png", "size": Vector2i(120, 72)},
        {"name": "snow_bridge.png", "size": Vector2i(136, 64)},
        {"name": "funeral_flowers.png", "size": Vector2i(104, 64)},
    ]
    for index in range(specs.size()):
        var cell := _grid_cell(source, 3, 3, index % 3, index / 3)
        var frame := _fit_frame(cell, specs[index]["size"], 3)
        _save(frame, PROP_OUT + String(specs[index]["name"]))


func _build_terrain() -> void:
    var source := _load_rgba(SRC + "terrain_source.png", false)
    var atlas := Image.create(256, 224, false, Image.FORMAT_RGBA8)
    atlas.fill(Color(0, 0, 0, 1))
    # 원본 비율(1672x941)에서 256px 폭은 약 6.5배 축소다. 표면 32px에 해당하는
    # 상단 209px만 잘라 눈·돌·뿌리 실루엣을 보존한다.
    var sy := int(round(source.get_height() * 0.045))
    var sh := int(round(source.get_width() / 8.0))
    sh = mini(sh, source.get_height() - sy)
    var surface := source.get_region(Rect2i(0, sy, source.get_width(), sh))
    surface.resize(256, 32, Image.INTERPOLATE_NEAREST)
    atlas.blit_rect(surface, Rect2i(0, 0, 256, 32), Vector2i.ZERO)
    var fy := sy + sh
    var fill := source.get_region(Rect2i(0, fy, source.get_width(), source.get_height() - fy))
    fill.resize(256, 192, Image.INTERPOLATE_NEAREST)
    atlas.blit_rect(fill, Rect2i(0, 0, 256, 192), Vector2i(0, 32))
    _save(atlas, TILE_OUT)


func _build_card() -> void:
    var card := _load_rgba(SRC + "card_source.png", false)
    card.resize(160, 160, Image.INTERPOLATE_NEAREST)
    _save(card, CARD_OUT)


func _load_rgba(path: String, matte: bool) -> Image:
    var image := Image.load_from_file(path)
    if image == null or image.is_empty():
        push_error("[Stage4Art] cannot load %s" % path)
        return Image.create(1, 1, false, Image.FORMAT_RGBA8)
    image.convert(Image.FORMAT_RGBA8)
    # atlas 전체에서 matte 하면 격자선이 외부 배경을 가로막아 흰 사각형이 복구될 수 있다.
    # 투명화는 아래 _grid_cell 에서 잘린 셀 단위로 한다.
    if matte:
        pass
    return image


func _grid_cell(source: Image, cols: int, rows: int, col: int, row: int) -> Image:
    var x0 := int(floor(float(col) * source.get_width() / float(cols)))
    var x1 := int(floor(float(col + 1) * source.get_width() / float(cols)))
    var y0 := int(floor(float(row) * source.get_height() / float(rows)))
    var y1 := int(floor(float(row + 1) * source.get_height() / float(rows)))
    var cell := source.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))
    _matte_bright_background(cell)
    _restore_enclosed_whites(cell)
    return cell


func _feather_horizontal(image: Image, edge: int) -> void:
    var width := image.get_width()
    var span := maxi(1, mini(edge, width / 2))
    for y in range(image.get_height()):
        for x in range(width):
            var c := image.get_pixel(x, y)
            if c.a <= 0.0:
                continue
            var left := clampf(float(x) / float(span), 0.0, 1.0)
            var right := clampf(float(width - 1 - x) / float(span), 0.0, 1.0)
            c.a *= minf(left, right)
            image.set_pixel(x, y, c)


func _feather_bottom(image: Image, edge: int) -> void:
    var height := image.get_height()
    var span := maxi(1, mini(edge, height))
    for y in range(height - span, height):
        var alpha := clampf(float(height - 1 - y) / float(span), 0.0, 1.0)
        for x in range(image.get_width()):
            var c := image.get_pixel(x, y)
            c.a *= alpha
            image.set_pixel(x, y, c)


func _fit_frame(cell: Image, canvas_size: Vector2i, padding: int) -> Image:
    var used := cell.get_used_rect()
    var canvas := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
    canvas.fill(Color(0, 0, 0, 0))
    if used.size.x <= 0 or used.size.y <= 0:
        return canvas
    var padded := used.grow(2).intersection(Rect2i(Vector2i.ZERO, cell.get_size()))
    var cropped := cell.get_region(padded)
    var room := Vector2i(maxi(1, canvas_size.x - padding * 2), maxi(1, canvas_size.y - padding * 2))
    var scale := minf(float(room.x) / cropped.get_width(), float(room.y) / cropped.get_height())
    var fitted := Vector2i(
        maxi(1, int(round(cropped.get_width() * scale))),
        maxi(1, int(round(cropped.get_height() * scale))))
    cropped.resize(fitted.x, fitted.y, Image.INTERPOLATE_NEAREST)
    var at := Vector2i((canvas_size.x - fitted.x) / 2, canvas_size.y - padding - fitted.y)
    canvas.blit_rect(cropped, Rect2i(Vector2i.ZERO, fitted), at)
    return canvas


func _matte_bright_background(image: Image) -> void:
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            var c := image.get_pixel(x, y)
            var hi := maxf(c.r, maxf(c.g, c.b))
            var lo := minf(c.r, minf(c.g, c.b))
            if lo >= 0.88 and hi - lo <= 0.07:
                image.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))
            else:
                image.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))


## 밝은 배경 제거로 생긴 투명 영역 중 이미지 가장자리와 연결되지 않은 부분은
## 캐릭터/소품 외곽선 안의 한지·눈이므로 다시 불투명하게 복구한다.
func _restore_enclosed_whites(image: Image) -> void:
    var w := image.get_width()
    var h := image.get_height()
    var seen := PackedByteArray()
    seen.resize(w * h)
    var queue: Array[Vector2i] = []
    for x in range(w):
        _queue_transparent(image, Vector2i(x, 0), seen, queue)
        _queue_transparent(image, Vector2i(x, h - 1), seen, queue)
    for y in range(h):
        _queue_transparent(image, Vector2i(0, y), seen, queue)
        _queue_transparent(image, Vector2i(w - 1, y), seen, queue)
    var head := 0
    var dirs := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
    while head < queue.size():
        var p := queue[head]
        head += 1
        for d in dirs:
            _queue_transparent(image, p + d, seen, queue)
    for y in range(h):
        for x in range(w):
            var idx := y * w + x
            var c := image.get_pixel(x, y)
            if c.a < 0.5 and seen[idx] == 0:
                image.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))


func _queue_transparent(image: Image, p: Vector2i, seen: PackedByteArray,
        queue: Array[Vector2i]) -> void:
    if p.x < 0 or p.y < 0 or p.x >= image.get_width() or p.y >= image.get_height():
        return
    var idx := p.y * image.get_width() + p.x
    if seen[idx] != 0 or image.get_pixel(p.x, p.y).a >= 0.5:
        return
    seen[idx] = 1
    queue.append(p)


func _save(image: Image, path: String) -> void:
    var err := image.save_png(ProjectSettings.globalize_path(path))
    if err != OK:
        push_error("[Stage4Art] cannot save %s: %s" % [path, err])
