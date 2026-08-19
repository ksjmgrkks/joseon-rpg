extends Node2D
##
## 보스 패턴 연출 확인용 프리뷰 (창 모드).
##   godot --path . res://tools/BossPatternPreview.tscn -- --pattern=pillars --out=shots/verify/bp
## pattern: dash | volley | pillars | wave | summon
##

const GROUND_Y := 560.0

func _ready() -> void:
    var args := {}
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--") and a.contains("="):
            var kv := a.substr(2).split("=", true, 1)
            args[kv[0]] = kv[1]
    var pattern := String(args.get("pattern", "pillars"))
    var out := String(args.get("out", "shots/verify/bp"))

    if WorldTint and "_modulate" in WorldTint and WorldTint._modulate != null:
        WorldTint._modulate.color = Color(0.85, 0.88, 0.95)
    if Weather and Weather is CanvasLayer:
        (Weather as CanvasLayer).visible = false

    var bg := ColorRect.new()
    bg.color = Color(0.18, 0.2, 0.26)
    bg.position = Vector2(-400, -400)
    bg.size = Vector2(2400, 1600)
    bg.z_index = -50
    add_child(bg)
    var ground := ColorRect.new()
    ground.color = Color(0.26, 0.24, 0.22)
    ground.position = Vector2(-400, GROUND_Y)
    ground.size = Vector2(2400, 400)
    ground.z_index = -40
    add_child(ground)
    var body := StaticBody2D.new()
    body.collision_layer = 4
    body.position = Vector2(640, GROUND_Y + 16)
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(3000, 32)
    cs.shape = shape
    body.add_child(cs)
    add_child(body)

    var cam := Camera2D.new()
    cam.position = Vector2(640, 380)
    add_child(cam)
    cam.make_current()

    var player: Node2D = load("res://scenes/player/Player.tscn").instantiate()
    add_child(player)
    player.global_position = Vector2(360, GROUND_Y - 60)

    var boss: Node2D = load("res://scenes/enemies/FloodWraith.tscn").instantiate()
    add_child(boss)
    boss.global_position = Vector2(900, GROUND_Y - 75)
    boss.set("_phase", 2)
    await get_tree().process_frame
    for i in range(30):
        await get_tree().physics_frame

    if pattern == "entrance":
        # 플레이어를 교전 거리 안으로 옮겨 등장 연출을 유발
        player.global_position = Vector2(760, GROUND_Y - 60)
        for i in range(6):
            await get_tree().physics_frame
        for t in [0.35, 0.9, 1.5, 2.4]:
            await get_tree().create_timer(0.45).timeout
            await RenderingServer.frame_post_draw
            var im := get_viewport().get_texture().get_image()
            var pp := "res://%s_entrance_%.1f.png" % [out, t]
            DirAccess.make_dir_recursive_absolute(
                ProjectSettings.globalize_path("res://") + pp.get_base_dir().trim_prefix("res://"))
            im.save_png(ProjectSettings.globalize_path(pp))
            print("[BP] ", pp)
        get_tree().quit(0)
        return
    match pattern:
        "volley":  boss.call("_do_volley")
        "pillars": boss.call("_do_pillars")
        "wave":    boss.call("_do_wave")
        "summon":  boss.call("_do_summon")
        _:         boss.call("_do_dash")

    var shots := [0.25, 0.7, 1.1]
    var prev := 0.0
    for i in range(shots.size()):
        var t := float(shots[i])
        await get_tree().create_timer(maxf(0.01, t - prev)).timeout
        prev = t
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        var p := "res://%s_%s_%d.png" % [out, pattern, i]
        DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path("res://") + p.get_base_dir().trim_prefix("res://"))
        img.save_png(ProjectSettings.globalize_path(p))
        print("[BP] ", p)
    get_tree().quit(0)


# --pattern=entrance 는 보스에게 접근해 등장 연출을 유발하고 캡처한다.
