extends SceneTree
##
## PixelLab 주인공(Joseon Spearman f5fd2830) front-flip 텀블링 점프 프레임 →
## protagonist_custom/jump.png 교체.
##
## 실행: godot --headless --path . --script res://tools/pixel/assemble_protagonist_tumble.gd
##
## 입력:  .pl_tmp/protagonist_tumble/<i>.png (east, 92x92, PixelLab CDN)
## 출력:  assets/sprites/protagonist_custom/jump.png (가로 스트립, 6프레임)
##
## protagonist_custom 의 모든 애니는 이미 같은 92x92 캔버스 기준이라(같은 캐릭터에서
## 뽑은 프레임들) union bbox 크롭 없이 그대로 이어붙이면 나머지 애니와 정렬이 맞는다.
##

const SRC := "res://.pl_tmp/protagonist_tumble"
const OUT := "res://assets/sprites/protagonist_custom/jump.png"
const FRAME_COUNT := 6
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
