extends SceneTree
##
## PixelLab 「골짜기의 수살귀」(수몰 군체 귀) 프레임 → Godot 스프라이트 시트 조립.
##
## 실행: godot --headless --path . --script res://tools/pixel/assemble_floodwraith.gd
##
## 입력:  .pl_tmp/floodwraith/<anim>/<i>.png   (east 방향 프레임, PixelLab CDN 에서 받은 것)
## 출력:  assets/sprites/enemies/flood_wraith/<anim>.png (가로 스트립) + manifest.json
##
## 규약(tools/pixel/AGENT_GUIDE.md §2): 모든 애니가 **같은 프레임 크기**를 써야 하므로
## 전 애니·전 프레임의 불투명 영역을 합집합(union bbox)으로 구해 한 번에 크롭한다.
## 이렇게 해야 애니가 바뀔 때 캐릭터가 튀지 않는다.
##

const SRC := "res://.pl_tmp/floodwraith"
const OUT := "res://assets/sprites/enemies/flood_wraith"
const ANIMS := {
    "idle":      {"frames": 7, "fps": 7,  "loop": true},
    "telegraph": {"frames": 5, "fps": 8,  "loop": true},
    "attack":    {"frames": 5, "fps": 12, "loop": false},
    "death":     {"frames": 7, "fps": 9,  "loop": false},
}


func _init() -> void:
    var loaded := {}
    var union := Rect2i()
    var first := true
    # ① 전부 읽어 union bbox 계산
    for anim in ANIMS:
        var arr: Array[Image] = []
        for i in range(int(ANIMS[anim]["frames"])):
            var path := "%s/%s/%d.png" % [SRC, anim, i]
            var img := Image.load_from_file(path)
            if img == null:
                push_error("프레임 없음: " + path)
                quit(1)
                return
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
    print("union bbox: ", union)

    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    # ② 애니마다 가로 스트립으로 합성
    for anim in ANIMS:
        var arr: Array = loaded[anim]
        var n := arr.size()
        var strip := Image.create(union.size.x * n, union.size.y, false, Image.FORMAT_RGBA8)
        strip.fill(Color(0, 0, 0, 0))
        for i in range(n):
            var src: Image = arr[i]
            strip.blit_rect(src, union, Vector2i(i * union.size.x, 0))
        var out_path := "%s/%s.png" % [OUT, anim]
        strip.save_png(ProjectSettings.globalize_path(out_path))
        print("  %s.png  %dx%d (%d프레임)" % [anim, strip.get_width(), strip.get_height(), n])

    # ③ manifest
    var manifest := {"frame_w": union.size.x, "frame_h": union.size.y, "anims": ANIMS}
    var f := FileAccess.open("%s/manifest.json" % OUT, FileAccess.WRITE)
    f.store_string(JSON.stringify(manifest, "  "))
    f.close()

    # ④ 발 정렬(foot_offset) 산출 — idle 첫 프레임의 최하단 불투명 행 기준.
    #    콜리전 바닥이 y=+16 이므로 offset = -(프레임높이 - 발끝) - 16 이 되도록 안내만 출력.
    var idle0: Image = loaded["idle"][0]
    var r0 := idle0.get_used_rect()
    var foot_in_frame := (r0.position.y + r0.size.y) - union.position.y   # 크롭 후 좌표계의 발끝 y
    var foot_offset := -(float(union.size.y) - float(foot_in_frame)) - float(union.size.y) * 0.5
    print("frame: %dx%d / 발끝(크롭 기준) y=%d / 권장 foot_offset=%.1f"
        % [union.size.x, union.size.y, foot_in_frame, foot_offset])
    quit(0)
