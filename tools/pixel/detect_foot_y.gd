extends SceneTree
##
## PNG 프레임에서 가장 아래쪽 불투명 픽셀 y좌표(발바닥)를 찾는다.
## foot_offset 계산용: foot_offset = -(canvas_h/2 - collision_half_h - foot_y_from_top)
## 실행: godot --headless --script res://tools/pixel/detect_foot_y.gd -- --path=<png>
##

func _init() -> void:
    var args := {}
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--") and a.contains("="):
            var kv := a.substr(2).split("=", true, 1)
            args[kv[0]] = kv[1]
    var path := String(args.get("path", ""))
    var img := Image.load_from_file(path)
    if img == null:
        push_error("load failed: " + path)
        quit(1)
        return
    var h := img.get_height()
    var w := img.get_width()
    var foot_y := -1
    for y in range(h - 1, -1, -1):
        for x in range(w):
            if img.get_pixel(x, y).a > 0.05:
                foot_y = y
                break
        if foot_y != -1:
            break
    print("size=%dx%d foot_y=%d" % [w, h, foot_y])
    quit(0)
