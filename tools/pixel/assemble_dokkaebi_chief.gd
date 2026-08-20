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
## ⚠ 2026-08-20 버그 수정: telegraph/attack 원본이 idle/walk/death와 다른 캔버스 크기(220 vs 160)로
## 나왔는데, 예전 코드는 get_used_rect() 들을 그대로 merge() 해서 "공통 크롭 창"을 만들었다 —
## 서로 다른 캔버스의 좌표를 같은 좌표계인 것처럼 합쳐버려 발끝이 어긋났다(대기=붕 뜸, 공격=파고듦).
## 캐릭터는 모든 원본에서 자기 캔버스 중심에 동일하게 배치돼 있으므로(측정 확인됨), 각 프레임을
## "자기 캔버스 중심"을 기준으로 공통 출력 캔버스(가장 큰 원본 크기) 중앙에 붙이면 애니메이션 간
## 발 위치가 자동으로 맞는다.
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
