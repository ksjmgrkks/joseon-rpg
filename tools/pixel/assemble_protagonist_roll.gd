extends SceneTree
##
## PixelLab Pro 주인공 지상 구르기 프레임을 런타임 공통 캔버스에 통합한다.
## 실행: godot --headless --path . --script res://tools/pixel/assemble_protagonist_roll.gd
## 입력: .pl_tmp/dodge_ground_roll_pro/dodge/<i>.png (east, 128x128)
## 출력: assets/sprites/protagonist_custom/dodge.png (143x144, 4프레임)
##
## 각 프레임의 최하단 불투명 픽셀을 기존 주인공 발끝 행(y=141)에 맞춘다.
## 따라서 웅크림→어깨 회전→기상 내내 지면 접촉이 유지되고 공중 텀블링처럼 뜨지 않는다.

const SRC := "res://.pl_tmp/dodge_ground_roll_pro/dodge"
const OUT := "res://assets/sprites/protagonist_custom/dodge.png"
const SOURCE_SIZE := Vector2i(128, 128)
const FRAME_SIZE := Vector2i(143, 144)
const FRAME_COUNT := 4
const GROUND_ROW := 141


func _init() -> void:
    var strip := Image.create(FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
    strip.fill(Color(0, 0, 0, 0))
    for i in range(FRAME_COUNT):
        var path := "%s/%d.png" % [SRC, i]
        var img := Image.load_from_file(path)
        if img == null or img.is_empty():
            push_error("프레임 없음: " + path)
            quit(1)
            return
        img.convert(Image.FORMAT_RGBA8)
        if img.get_size() != SOURCE_SIZE:
            push_error("프레임 크기 불일치: %s %s" % [path, img.get_size()])
            quit(1)
            return
        var used := img.get_used_rect()
        if used.size == Vector2i.ZERO:
            push_error("빈 프레임: " + path)
            quit(1)
            return
        var visible_bottom := used.position.y + used.size.y - 1
        var at := Vector2i((FRAME_SIZE.x - SOURCE_SIZE.x) / 2, GROUND_ROW - visible_bottom)
        strip.blit_rect(img, Rect2i(Vector2i.ZERO, SOURCE_SIZE), Vector2i(i * FRAME_SIZE.x, 0) + at)
        print("roll #%d: used=%s offset=%s" % [i, str(used), str(at)])
    var err := strip.save_png(ProjectSettings.globalize_path(OUT))
    if err != OK:
        push_error("dodge.png 저장 실패: %s" % error_string(err))
        quit(1)
        return
    print("dodge.png 교체 완료: %dx%d (%d프레임, ground y=%d)" % [
        strip.get_width(), strip.get_height(), FRAME_COUNT, GROUND_ROW])
    quit(0)
