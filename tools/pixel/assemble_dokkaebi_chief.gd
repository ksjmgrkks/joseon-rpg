extends SceneTree
##
## PixelLab 「도깨비 대장」(3스테이지 보스) 프레임 → Godot 스프라이트 시트 조립.
## tools/pixel/assemble_geuseondae_elder.gd 와 동일 규약(east 방향 프레임 → 가로 스트립 + manifest).
##
## 실행: godot --headless --path . --script res://tools/pixel/assemble_dokkaebi_chief.gd
##
## 입력:  .pl_tmp/dokkaebi_chief/<anim>/<i>.png   (east 방향 프레임)
## 출력:  assets/sprites/enemies/dokkaebi_chief/<anim>.png (가로 스트립) + manifest.json
##

const SRC := "res://.pl_tmp/dokkaebi_chief"
const OUT := "res://assets/sprites/enemies/dokkaebi_chief"
const ANIMS := {
    "idle":      {"frames": 4, "fps": 5,  "loop": true},
    "walk":      {"frames": 6, "fps": 8,  "loop": true},
    "telegraph": {"frames": 5, "fps": 8,  "loop": false},
    "attack":    {"frames": 7, "fps": 13, "loop": false},
    "death":     {"frames": 7, "fps": 8,  "loop": false},
}


func _init() -> void:
    var loaded := {}
    var union := Rect2i()
    var first := true
    for anim in ANIMS:
        var arr: Array[Image] = []
        var n := int(ANIMS[anim]["frames"])
        for i in range(n):
            var path := "%s/%s/%d.png" % [SRC, anim, i]
            var img := Image.load_from_file(ProjectSettings.globalize_path(path))
            if img == null:
                push_error("프레임 없음: " + path)
                continue
            arr.append(img)
            var r := img.get_used_rect()
            if r.size.x <= 0:
                continue
            if first:
                union = r
                first = false
            else:
                union = union.merge(r)
        loaded[anim] = arr
    if first:
        push_error("프레임을 하나도 못 읽음")
        quit(1)
        return
    print("union bbox: ", union)

    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    var out_anims := {}
    for anim in ANIMS:
        var arr: Array = loaded[anim]
        var n := arr.size()
        if n == 0:
            continue
        var strip := Image.create(union.size.x * n, union.size.y, false, Image.FORMAT_RGBA8)
        strip.fill(Color(0, 0, 0, 0))
        for i in range(n):
            var src_img: Image = arr[i]
            strip.blit_rect(src_img, union, Vector2i(i * union.size.x, 0))
        var out_path := "%s/%s.png" % [OUT, anim]
        strip.save_png(ProjectSettings.globalize_path(out_path))
        out_anims[anim] = ANIMS[anim]
        print("  %s.png  %dx%d (%d프레임)" % [anim, strip.get_width(), strip.get_height(), n])

    var manifest := {"frame_w": union.size.x, "frame_h": union.size.y, "anims": out_anims}
    var f := FileAccess.open("%s/manifest.json" % OUT, FileAccess.WRITE)
    f.store_string(JSON.stringify(manifest, "  "))
    f.close()

    if loaded.has("idle") and loaded["idle"].size() > 0:
        var idle0: Image = loaded["idle"][0]
        var r0 := idle0.get_used_rect()
        var foot_in_frame := (r0.position.y + r0.size.y) - union.position.y
        var foot_offset := -(float(union.size.y) - float(foot_in_frame)) - float(union.size.y) * 0.5
        print("frame: %dx%d / 발끝(크롭 기준) y=%d / 권장 foot_offset=%.1f"
            % [union.size.x, union.size.y, foot_in_frame, foot_offset])
    quit(0)
