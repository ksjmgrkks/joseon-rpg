extends SceneTree
##
## PixelLab 주인공(Joseon Spearman f5fd2830) 기존 "jumping-1" 템플릿 프레임(일반 점프,
## 텀블링 아님) → protagonist_custom/jump.png 교체. 텀블링 모션이 어색하다는 피드백으로
## 되돌림 (2026-08-19).
##
## 실행: godot --headless --path . --script res://tools/pixel/assemble_protagonist_jump_normal.gd
##
## 입력:  .pl_tmp/protagonist_jump_normal/<i>.png (east, 92x92, PixelLab CDN)
## 출력:  assets/sprites/protagonist_custom/jump.png (가로 스트립, 9프레임)
##

const SRC := "res://.pl_tmp/protagonist_jump_normal"
const OUT := "res://assets/sprites/protagonist_custom/jump.png"
const FRAME_COUNT := 9
const FRAME_SIZE := Vector2i(92, 92)


func _init() -> void:
    var strip := Image.create(FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
    strip.fill(Color(0, 0, 0, 0))
    for i in range(FRAME_COUNT):
        var path := "%s/%d.png" % [SRC, i]
        var img := Image.load_from_file(path)
        if img == null:
            push_error("프레임 없음: " + path)
            quit(1)
            return
        if img.get_size() != FRAME_SIZE:
            push_error("프레임 크기 불일치: %s %s" % [path, img.get_size()])
            quit(1)
            return
        strip.blit_rect(img, Rect2i(Vector2i.ZERO, FRAME_SIZE), Vector2i(i * FRAME_SIZE.x, 0))
    strip.save_png(ProjectSettings.globalize_path(OUT))
    print("jump.png 교체 완료: %dx%d (%d프레임)" % [strip.get_width(), strip.get_height(), FRAME_COUNT])
    quit(0)
