extends SceneTree
##
## PixelLab 「그슨대 노괴」(보스, 위장=소년/정체=거대 그림자) 프레임 → Godot 스프라이트 시트 조립.
## 두 형태(SRC/OUT 쌍)를 순서대로 처리 — tools/pixel/assemble_geuseondae.gd 와 동일 규약.
##
## 실행: godot --headless --path . --script res://tools/pixel/assemble_geuseondae_elder.gd
##
## 입력:  .pl_tmp/<form>/<anim>/<i>.png   (east 방향 프레임, PixelLab CDN 에서 받은 것)
## 출력:  assets/sprites/enemies/<form>/<anim>.png (가로 스트립) + manifest.json
##

const FORMS := {
    "geuseondae_elder_boy": {
        "src": "res://.pl_tmp/geuseondae_elder_boy",
        "out": "res://assets/sprites/enemies/geuseondae_elder_boy",
        "anims": {
            "idle":   {"frames": 5, "fps": 5,  "loop": true},
            "walk":   {"frames": 5, "fps": 7,  "loop": true},
            "attack": {"frames": 5, "fps": 11, "loop": false},
        },
    },
    "geuseondae_elder_shadow": {
        "src": "res://.pl_tmp/geuseondae_elder_shadow",
        "out": "res://assets/sprites/enemies/geuseondae_elder_shadow",
        "anims": {
            "idle":   {"frames": 5, "fps": 5,  "loop": true},
            "walk":   {"frames": 5, "fps": 7,  "loop": true},
            "attack": {"frames": 5, "fps": 11, "loop": false},
            "death":  {"frames": 5, "fps": 7,  "loop": false},
        },
    },
}


func _init() -> void:
    for form in FORMS:
        _assemble(form, FORMS[form]["src"], FORMS[form]["out"], FORMS[form]["anims"])
    quit(0)


func _assemble(form: String, src: String, out: String, anims: Dictionary) -> void:
    print("=== ", form, " ===")
    var loaded := {}
    var union := Rect2i()
    var first := true
    for anim in anims:
        var arr: Array[Image] = []
        for i in range(int(anims[anim]["frames"])):
            var path := "%s/%s/%d.png" % [src, anim, i]
            var img := Image.load_from_file(path)
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
        push_error("%s: 프레임을 하나도 못 읽음 — 건너뜀" % form)
        return
    print("union bbox: ", union)

    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
    for anim in anims:
        var arr: Array = loaded[anim]
        var n := arr.size()
        if n == 0:
            continue
        var strip := Image.create(union.size.x * n, union.size.y, false, Image.FORMAT_RGBA8)
        strip.fill(Color(0, 0, 0, 0))
        for i in range(n):
            var src_img: Image = arr[i]
            strip.blit_rect(src_img, union, Vector2i(i * union.size.x, 0))
        var out_path := "%s/%s.png" % [out, anim]
        strip.save_png(ProjectSettings.globalize_path(out_path))
        print("  %s.png  %dx%d (%d프레임)" % [anim, strip.get_width(), strip.get_height(), n])

    var manifest := {"frame_w": union.size.x, "frame_h": union.size.y, "anims": anims}
    var f := FileAccess.open("%s/manifest.json" % out, FileAccess.WRITE)
    f.store_string(JSON.stringify(manifest, "  "))
    f.close()

    if loaded.has("idle") and loaded["idle"].size() > 0:
        var idle0: Image = loaded["idle"][0]
        var r0 := idle0.get_used_rect()
        var foot_in_frame := (r0.position.y + r0.size.y) - union.position.y
        var foot_offset := -(float(union.size.y) - float(foot_in_frame)) - float(union.size.y) * 0.5
        print("frame: %dx%d / 발끝(크롭 기준) y=%d / 권장 foot_offset=%.1f"
            % [union.size.x, union.size.y, foot_in_frame, foot_offset])
