extends Node2D
##
## 주인공 점프 텀블링 애니 확인용 프리뷰.
##   DISPLAY=:0 godot --headless --path . res://tools/JumpPreview.tscn -- --out=shots/jump
## 점프 버튼을 코드로 눌렀다 떼고, 체공 중 일정 간격으로 스크린샷을 남긴다.
##

const GROUND_Y := 560.0

func _ready() -> void:
    var args := {}
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--") and a.contains("="):
            var kv := a.substr(2).split("=", true, 1)
            args[kv[0]] = kv[1]
    var out := String(args.get("out", "shots/jump"))

    var ground := ColorRect.new()
    ground.color = Color(0.7, 0.62, 0.45)
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
    cam.position = Vector2(640, 420)
    cam.zoom = Vector2(2.5, 2.5)
    add_child(cam)
    cam.make_current()

    var player: Node2D = load("res://scenes/player/Player.tscn").instantiate()
    add_child(player)
    player.global_position = Vector2(640, GROUND_Y - 16)
    for i in range(6):
        await get_tree().physics_frame

    Input.action_press("jump")
    await get_tree().physics_frame
    Input.action_release("jump")

    var visual: AnimatedSprite2D = player.get_node("Visual")
    var shots := [0.05, 0.15, 0.28, 0.42, 0.56, 0.68]
    var prev := 0.0
    for i in range(shots.size()):
        var t := float(shots[i])
        await get_tree().create_timer(maxf(0.01, t - prev)).timeout
        prev = t
        await RenderingServer.frame_post_draw
        print("[Jump] t=%.2f on_floor=%s anim=%s frame=%d vy=%.1f" % [t, player.is_on_floor(), visual.animation, visual.frame, player.velocity.y])
        var img := get_viewport().get_texture().get_image()
        var p := "res://%s_%d.png" % [out, i]
        DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path("res://") + p.get_base_dir().trim_prefix("res://"))
        img.save_png(ProjectSettings.globalize_path(p))
        print("[Jump] ", p)
    get_tree().quit(0)
