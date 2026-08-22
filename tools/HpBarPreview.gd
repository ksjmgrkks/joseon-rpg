extends Node2D
##
## 적 HP 바 / 피격 반응 시각 확인용 프리뷰 (헤드리스 아님 — 창이 잠깐 뜬다).
##
## 사용:
##   godot --path . res://tools/HpBarPreview.tscn -- --out=shots/hpbar.png [--wait=0.25]
##
## 적 여러 종을 나란히 세우고 전부 한 대씩 때린 상태를 캡처한다 —
## 바가 각자의 머리 위에 걸리는지, 두께·잔상·휘청임이 보이는지 눈으로 확인.
##

const ENEMIES := [
    "res://scenes/enemies/Dueoksini.tscn",
    "res://scenes/enemies/DrownedChild.tscn",
    "res://scenes/enemies/Mulgwisin.tscn",
    "res://scenes/enemies/Mulgwisin.tscn",
    "res://scenes/enemies/Changgwi.tscn",
    "res://scenes/enemies/DrownedMudang.tscn",
    "res://scenes/enemies/FloodWraith.tscn",
]


func _ready() -> void:
    var args := {}
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--") and a.contains("="):
            var kv := a.substr(2).split("=", true, 1)
            args[kv[0]] = kv[1]

    var out_path := String(args.get("out", "shots/hpbar.png"))
    var wait_s := float(args.get("wait", "0.25"))

    # 배경 — 어두운 먹빛(바 대비 확인용)
    var bg := ColorRect.new()
    bg.color = Color(0.16, 0.15, 0.14)
    bg.size = Vector2(1280, 720)
    bg.position = Vector2(-100, -300)
    bg.z_index = -50
    add_child(bg)

    var cam := Camera2D.new()
    cam.position = Vector2(520, 60)
    add_child(cam)
    cam.make_current()

    var x := 120.0
    var spawned: Array[Node] = []
    for path in ENEMIES:
        var packed: PackedScene = load(path)
        if packed == null:
            continue
        var e := packed.instantiate() as Node2D
        add_child(e)
        e.global_position = Vector2(x, 220)
        spawned.append(e)
        x += 170.0

    await get_tree().process_frame
    await get_tree().process_frame

    # 전부 한 대씩 — HP 바를 띄우고 피격 반응(휘청·squash·잔상)을 만든다.
    for e in spawned:
        var hb := e.get_node_or_null("Hurtbox") as Hurtbox
        var hc := e.get_node_or_null("HealthComponent") as HealthComponent
        if hb:
            hb.hurt.emit(0.0, 260.0, null)
        if hc:
            hc.take_damage(hc.max_hp * 0.45)

    await get_tree().create_timer(wait_s).timeout
    await RenderingServer.frame_post_draw

    var img := get_viewport().get_texture().get_image()
    var abs_out := out_path
    if not abs_out.begins_with("res://") and not abs_out.contains(":"):
        abs_out = "res://" + abs_out
    var dir := abs_out.get_base_dir().trim_prefix("res://")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + dir)
    var err := img.save_png(ProjectSettings.globalize_path(abs_out))
    print("[HpBarPreview] -> %s (err=%d)" % [abs_out, err])
    get_tree().quit(0 if err == OK else 1)
