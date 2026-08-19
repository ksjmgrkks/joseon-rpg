extends SceneTree
##
## PixelLab 주인공 v2(보라 창, v3 커스텀 애니) 프레임 → protagonist_custom/<anim>.png 교체.
## 사용자 요청(2026-08-19): 크기/퀄리티 개선 + 창을 화려한 보라색으로.
##
## 실행: godot --headless --path . --script res://tools/pixel/assemble_protagonist_v2.gd -- --anim=idle --frames=4 --size=256
##
## 입력:  .pl_tmp/protagonist_v2_<anim>/<i>.png (east)
## 출력:  assets/sprites/protagonist_custom/<anim>.png (가로 스트립)
##

func _init() -> void:
    var args := {}
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--") and a.contains("="):
            var kv := a.substr(2).split("=", true, 1)
            args[kv[0]] = kv[1]
    var anim := String(args.get("anim", ""))
    var frame_count := int(args.get("frames", "0"))
    var size := int(args.get("size", "256"))
    if anim.is_empty() or frame_count <= 0:
        push_error("usage: --anim=<name> --frames=<n> [--size=256]")
        quit(1)
        return

    var src := "res://.pl_tmp/protagonist_v2_%s" % anim
    var out := "res://assets/sprites/protagonist_custom/%s.png" % anim
    var frame_size := Vector2i(size, size)

    var strip := Image.create(frame_size.x * frame_count, frame_size.y, false, Image.FORMAT_RGBA8)
    strip.fill(Color(0, 0, 0, 0))
    for i in range(frame_count):
        var path := "%s/%d.png" % [src, i]
        var img := Image.load_from_file(path)
        if img == null:
            push_error("프레임 없음: " + path)
            quit(1)
            return
        if img.get_size() == frame_size:
            strip.blit_rect(img, Rect2i(Vector2i.ZERO, frame_size), Vector2i(i * frame_size.x, 0))
        elif img.get_size().x <= frame_size.x and img.get_size().y <= frame_size.y:
            # 작은 프레임은 중앙 정렬로 패딩 (발 정렬 계산이 대칭 패딩을 전제함)
            var pad := Vector2i((frame_size.x - img.get_size().x) / 2.0, (frame_size.y - img.get_size().y) / 2.0)
            strip.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(i * frame_size.x, 0) + pad)
        else:
            push_error("프레임이 목표보다 큼: %s %s (목표 %s)" % [path, img.get_size(), frame_size])
            quit(1)
            return
    strip.save_png(ProjectSettings.globalize_path(out))
    print("%s.png 교체 완료: %dx%d (%d프레임)" % [anim, strip.get_width(), strip.get_height(), frame_count])
    quit(0)
