extends SceneTree
##
## PixelLab 「도깨비 대장」(3스테이지 보스) 프레임 → Godot 스프라이트 시트 조립.
## tools/pixel/assemble_geuseondae_elder.gd 와 동일 규약(east 방향 프레임 → 가로 스트립 + manifest).
##
## 실행: godot --headless --path . --script res://tools/pixel/assemble_dokkaebi_chief.gd
##
## 입력:  .pl_tmp/dokkaebi_chief_pro/<anim>/<i>.png   (PixelLab Pro east 방향 프레임)
## 출력:  assets/sprites/enemies/dokkaebi_chief/<anim>.png (가로 스트립) + manifest.json
##
## 생성 원본: PixelLab Pro character 6ce3aa1d-576d-4597-ae37-53c9e02e0ec5
## 128x128 / east / 애니메이션당 4프레임. 생성 기록은 docs/PROMPTS_STAGE3_REMASTER.md 참고.
## 모든 프레임은 원본 캔버스 중심을 기준으로 붙여, 애니메이션 간 발 위치를 보존한다.
##

const SRC := "res://.pl_tmp/dokkaebi_chief_pro"
const OUT := "res://assets/sprites/enemies/dokkaebi_chief"
const ANIMS := {
    "idle":      {"frames": 4, "fps": 5,  "loop": true},
    "walk":      {"frames": 4, "fps": 7,  "loop": true},
    "telegraph": {"frames": 4, "fps": 7,  "loop": false},
    "attack":    {"frames": 4, "fps": 11, "loop": false},
    "death":     {"frames": 4, "fps": 7,  "loop": false},
}


func _init() -> void:
    var loaded := {}
    var out_w := 0
    var out_h := 0
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
            out_w = max(out_w, img.get_width())
            out_h = max(out_h, img.get_height())
            first = false
        loaded[anim] = arr
    if first:
        push_error("프레임을 하나도 못 읽음")
        quit(1)
        return
    print("출력 캔버스(원본 중 최대): %dx%d" % [out_w, out_h])

    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    var out_anims := {}
    for anim in ANIMS:
        var arr: Array = loaded[anim]
        var n := arr.size()
        if n == 0:
            continue
        var strip := Image.create(out_w * n, out_h, false, Image.FORMAT_RGBA8)
        strip.fill(Color(0, 0, 0, 0))
        for i in range(n):
            var src_img: Image = arr[i]
            # 각 프레임을 "자기 캔버스 중심 = 출력 캔버스 중심"이 되도록 가운데 정렬해 붙인다
            # (union 크롭 대신 — 서로 다른 원본 캔버스 크기를 섞어도 캐릭터 발 위치가 유지됨).
            var dst := Vector2i(
                i * out_w + (out_w - src_img.get_width()) / 2,
                (out_h - src_img.get_height()) / 2)
            strip.blit_rect(src_img, Rect2i(Vector2i.ZERO, src_img.get_size()), dst)
        var out_path := "%s/%s.png" % [OUT, anim]
        strip.save_png(ProjectSettings.globalize_path(out_path))
        out_anims[anim] = ANIMS[anim]
        print("  %s.png  %dx%d (%d프레임)" % [anim, strip.get_width(), strip.get_height(), n])

    var manifest := {"frame_w": out_w, "frame_h": out_h, "anims": out_anims}
    var f := FileAccess.open("%s/manifest.json" % OUT, FileAccess.WRITE)
    f.store_string(JSON.stringify(manifest, "  "))
    f.close()

    if loaded.has("idle") and loaded["idle"].size() > 0:
        var idle0: Image = loaded["idle"][0]
        var idle0_centered := Image.create(out_w, out_h, false, Image.FORMAT_RGBA8)
        idle0_centered.fill(Color(0, 0, 0, 0))
        var dst0 := Vector2i((out_w - idle0.get_width()) / 2, (out_h - idle0.get_height()) / 2)
        idle0_centered.blit_rect(idle0, Rect2i(Vector2i.ZERO, idle0.get_size()), dst0)
        var r0 := idle0_centered.get_used_rect()
        var foot_row := r0.position.y + r0.size.y     # 캔버스 top=0 기준 발끝 행(exclusive)
        var x_term := float(foot_row) - float(out_h) * 0.5
        print("frame: %dx%d / 발끝(y)=%d / 캔버스중심과의 차(X)=%.1f" % [out_w, out_h, foot_row, x_term])
        print("  → foot_offset = 콜리전 반높이/sprite_scale - X   (character_visual.gd 상단 규약과 동일)")
    quit(0)
