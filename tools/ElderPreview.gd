extends Node2D
## 그슨대 노괴 위장/정체 두 형태를 나란히 렌더(창 모드).
##   godot --path . res://tools/ElderPreview.tscn -- --out=shots/verify/elder
const GROUND_Y := 560.0

func _ready() -> void:
    var out := "shots/verify/elder"
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--out="):
            out = a.substr(6)
    if WorldTint and "_modulate" in WorldTint and WorldTint._modulate != null:
        WorldTint._modulate.color = Color(0.9, 0.92, 0.96)
    var bg := ColorRect.new()
    bg.color = Color(0.10, 0.11, 0.14); bg.position = Vector2(-400, -400); bg.size = Vector2(2400, 1600)
    bg.z_index = -50; add_child(bg)
    var gr := ColorRect.new()
    gr.color = Color(0.20, 0.19, 0.18); gr.position = Vector2(-400, GROUND_Y); gr.size = Vector2(2400, 400)
    gr.z_index = -40; add_child(gr)
    var body := StaticBody2D.new(); body.collision_layer = 4; body.position = Vector2(640, GROUND_Y + 16)
    var cs := CollisionShape2D.new(); var sh := RectangleShape2D.new(); sh.size = Vector2(3000, 32)
    cs.shape = sh; body.add_child(cs); add_child(body)
    var cam := Camera2D.new(); cam.position = Vector2(640, 400); add_child(cam); cam.make_current()

    var player: Node2D = load("res://scenes/player/Player.tscn").instantiate()
    add_child(player); player.global_position = Vector2(300, GROUND_Y - 60)

    # 왼쪽: 위장(소년) / 오른쪽: 정체(거대 그림자)
    var boy: Node2D = load("res://scenes/enemies/GeuseondaeElder.tscn").instantiate()
    add_child(boy); boy.global_position = Vector2(520, GROUND_Y - 29)
    var shadow: Node2D = load("res://scenes/enemies/GeuseondaeElder.tscn").instantiate()
    add_child(shadow); shadow.global_position = Vector2(900, GROUND_Y - 29)
    await get_tree().process_frame
    for i in range(20):
        await get_tree().physics_frame
    shadow.call("_reveal")
    for i in range(30):
        await get_tree().physics_frame
    await get_tree().create_timer(0.6).timeout
    await RenderingServer.frame_post_draw
    var img := get_viewport().get_texture().get_image()
    var p := "res://%s.png" % out
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://") + p.get_base_dir().trim_prefix("res://"))
    img.save_png(ProjectSettings.globalize_path(p))
    print("[Elder] ", p)
    get_tree().quit(0)
