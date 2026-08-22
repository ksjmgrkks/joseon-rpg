extends SceneTree
## A안 금줄 경계석과 잠긴 무당 생성 원본을 실게임 규격으로 가공한다.
## 생성기는 투명 배경 요청에도 밝은 체크무늬를 RGB로 굽기 때문에,
## 가장자리와 연결된 밝은 중성색만 flood-fill로 실제 알파 처리한다.

const SRC := "res://.art_gen/stage1_reconcept/"
const GATE_OUT := "res://assets/sprites/fx/gate_geumjul_release.png"
const MUDANG_OUT := "res://assets/sprites/enemies/drowned_mudang/"
const FLOOD_OUT := "res://assets/tilesets/"

const GATE_FRAME := Vector2i(192, 208)
const GATE_COUNT := 6
const MUDANG_FRAME := Vector2i(160, 176)
const MUDANG_ANIMS := {
    "idle": {"file": "drowned_mudang_idle_source.png", "frames": 5, "fps": 6, "loop": true},
    "telegraph": {"file": "drowned_mudang_telegraph_source.png", "frames": 5, "fps": 8, "loop": false},
    "attack": {"file": "drowned_mudang_attack_source.png", "frames": 5, "fps": 11, "loop": false},
    "death": {"file": "drowned_mudang_death_source.png", "frames": 6, "fps": 8, "loop": false},
}


func _init() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GATE_OUT.get_base_dir()))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MUDANG_OUT))
    var ok := _build_gate() and _build_mudang() and _build_flood_pools()
    print("[stage1_gate_mudang] gate=%d frames, mudang=%d anims, flood_pools=3" % [GATE_COUNT, MUDANG_ANIMS.size()])
    quit(0 if ok else 1)


func _build_gate() -> bool:
    var src := Image.load_from_file(ProjectSettings.globalize_path(SRC + "geumjul_release_source.png"))
    if src == null or src.is_empty():
        push_error("금줄 원본 로드 실패")
        return false
    _matte_edge_checker(src)
    var frames: Array[Image] = []
    var cell_w := src.get_width() / 3
    var cell_h := src.get_height() / 2
    for i in GATE_COUNT:
        var col := i % 3
        var row := i / 3
        frames.append(src.get_region(Rect2i(col * cell_w, row * cell_h, cell_w, cell_h)))
    var sheet := _pack_frames(frames, GATE_FRAME, 6)
    _clear_enclosed_checker(sheet)
    return sheet.save_png(ProjectSettings.globalize_path(GATE_OUT)) == OK


func _build_mudang() -> bool:
    var all_frames := {}
    var every: Array[Image] = []
    for anim_name in MUDANG_ANIMS:
        var spec: Dictionary = MUDANG_ANIMS[anim_name]
        var src := Image.load_from_file(ProjectSettings.globalize_path(SRC + String(spec["file"])))
        if src == null or src.is_empty():
            push_error("잠긴 무당 원본 로드 실패: %s" % spec["file"])
            return false
        _matte_edge_checker(src)
        var frames: Array[Image] = []
        var count := int(spec["frames"])
        for i in count:
            # 2172/5처럼 셀 폭이 정수가 아닌 출력도 누적 반올림으로 빠짐없이 나눈다.
            var x0 := roundi(float(src.get_width()) * i / count)
            var x1 := roundi(float(src.get_width()) * (i + 1) / count)
            var frame := src.get_region(Rect2i(x0, 0, x1 - x0, src.get_height()))
            frames.append(frame)
            every.append(frame)
        all_frames[anim_name] = frames

    # 모든 애니메이션에 같은 배율을 적용해야 동작 중 몸집이 커졌다 작아지지 않는다.
    var scale := _shared_scale(every, MUDANG_FRAME, 6)
    for anim_name in MUDANG_ANIMS:
        var strip := _pack_frames(all_frames[anim_name], MUDANG_FRAME, 6, scale)
        if strip.save_png(ProjectSettings.globalize_path(MUDANG_OUT + anim_name + ".png")) != OK:
            return false
    var manifest := {"frame_w": MUDANG_FRAME.x, "frame_h": MUDANG_FRAME.y, "anims": {}}
    for anim_name in MUDANG_ANIMS:
        var spec: Dictionary = MUDANG_ANIMS[anim_name]
        manifest["anims"][anim_name] = {
            "frames": int(spec["frames"]),
            "fps": int(spec["fps"]),
            "loop": bool(spec["loop"]),
        }
    var f := FileAccess.open(MUDANG_OUT + "manifest.json", FileAccess.WRITE)
    if f == null:
        return false
    f.store_string(JSON.stringify(manifest, "  "))
    f.close()
    return true


func _build_flood_pools() -> bool:
    var src := Image.load_from_file(ProjectSettings.globalize_path(SRC + "flood_pools_source.png"))
    if src == null or src.is_empty():
        push_error("범람수 원본 로드 실패")
        return false
    _matte_edge_checker(src)
    for i in 3:
        var x0 := roundi(float(src.get_width()) * i / 3.0)
        var x1 := roundi(float(src.get_width()) * (i + 1) / 3.0)
        var frame := src.get_region(Rect2i(x0, 0, x1 - x0, src.get_height()))
        var image := _pack_frames([frame], Vector2i(256, 56), 4)
        var suffix := String.chr(97 + i)
        if image.save_png(ProjectSettings.globalize_path(FLOOD_OUT + "flood_pool_" + suffix + ".png")) != OK:
            return false
    return true


func _pack_frames(frames: Array[Image], frame_size: Vector2i, pad: int, fixed_scale: float = -1.0) -> Image:
    var scale := fixed_scale if fixed_scale > 0.0 else _shared_scale(frames, frame_size, pad)
    var sheet := Image.create(frame_size.x * frames.size(), frame_size.y, false, Image.FORMAT_RGBA8)
    sheet.fill(Color(0, 0, 0, 0))
    for i in frames.size():
        var frame := frames[i]
        var used := frame.get_used_rect()
        if used.size.x <= 0 or used.size.y <= 0:
            continue
        var crop := frame.get_region(used)
        var size := Vector2i(maxi(1, roundi(used.size.x * scale)), maxi(1, roundi(used.size.y * scale)))
        crop.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
        var dst := Vector2i(i * frame_size.x + (frame_size.x - size.x) / 2,
            frame_size.y - pad - size.y)
        sheet.blit_rect(crop, Rect2i(Vector2i.ZERO, size), dst)
    return sheet


func _shared_scale(frames: Array[Image], frame_size: Vector2i, pad: int) -> float:
    var max_w := 1
    var max_h := 1
    for frame in frames:
        var used := frame.get_used_rect()
        max_w = maxi(max_w, used.size.x)
        max_h = maxi(max_h, used.size.y)
    return minf(float(frame_size.x - pad * 2) / max_w, float(frame_size.y - pad * 2) / max_h)


func _matte_edge_checker(img: Image) -> void:
    img.convert(Image.FORMAT_RGBA8)
    var w := img.get_width()
    var h := img.get_height()
    var seen := PackedByteArray()
    seen.resize(w * h)
    var queue: Array[Vector2i] = []
    for x in w:
        _queue_bg(img, Vector2i(x, 0), seen, queue)
        _queue_bg(img, Vector2i(x, h - 1), seen, queue)
    for y in h:
        _queue_bg(img, Vector2i(0, y), seen, queue)
        _queue_bg(img, Vector2i(w - 1, y), seen, queue)
    var head := 0
    while head < queue.size():
        var p := queue[head]
        head += 1
        img.set_pixelv(p, Color(0, 0, 0, 0))
        _queue_bg(img, p + Vector2i.LEFT, seen, queue)
        _queue_bg(img, p + Vector2i.RIGHT, seen, queue)
        _queue_bg(img, p + Vector2i.UP, seen, queue)
        _queue_bg(img, p + Vector2i.DOWN, seen, queue)


## 금줄은 여러 폐곡선을 만들어 내부 체크무늬가 가장자리와 단절된다. 생성 배경의 실측값은
## RGB 235~255 중성색이고 한지 장식의 본색은 그보다 어둡다. 큰 원본이 아닌 최종 시트에서만
## 2차 색키를 돌려 재생성 시간을 짧게 유지한다.
func _clear_enclosed_checker(img: Image) -> void:
    for y in img.get_height():
        for x in img.get_width():
            var c := img.get_pixel(x, y)
            if c.a <= 0.0:
                continue
            var hi := maxf(c.r, maxf(c.g, c.b))
            var lo := minf(c.r, minf(c.g, c.b))
            if lo >= 0.92 and hi - lo <= 0.07:
                img.set_pixel(x, y, Color(0, 0, 0, 0))


func _queue_bg(img: Image, p: Vector2i, seen: PackedByteArray, queue: Array[Vector2i]) -> void:
    if p.x < 0 or p.y < 0 or p.x >= img.get_width() or p.y >= img.get_height():
        return
    var idx := p.y * img.get_width() + p.x
    if seen[idx] != 0:
        return
    seen[idx] = 1
    var c := img.get_pixelv(p)
    var hi := maxf(c.r, maxf(c.g, c.b))
    var lo := minf(c.r, minf(c.g, c.b))
    # 생성기의 흰색/연회색 체크무늬. 어두운 외곽선 안쪽의 흰 무복·한지는 연결되지 않아 보존된다.
    if lo >= 0.80 and hi - lo <= 0.09:
        queue.append(p)
