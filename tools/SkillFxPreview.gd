extends Node2D
##
## 스킬 연출 확인용 프리뷰 (헤드리스 아님 — 창이 잠깐 뜬다).
##
## 사용:
##   godot --path . res://tools/SkillFxPreview.tscn -- --skill=ilseom --out=shots/verify/fx_ilseom
##   (--out 뒤에 _0.png, _1.png … 로 여러 시점을 이어서 저장한다)
##
## 실제 플레이어를 세우고 스킬을 발동시킨 뒤 정해진 시점마다 화면을 찍는다.
## 돌진·부양 같은 '움직임'이 들어간 연출은 한 장으로는 안 보이므로 연속 캡처가 필요하다.
##

const PLAYER := "res://scenes/player/Player.tscn"
const ENEMY := "res://scenes/enemies/Dueoksini.tscn"
const GROUND_Y := 470.0

# 스킬별 캡처 시점(초) — 시전/진행/마무리가 각각 담기게.
const SHOTS := {
    "ilseom": [0.18, 0.42, 0.62, 0.85],
    "hoecheon": [0.28, 0.6, 0.85, 1.1],
    "hosinbu": [0.08, 0.3, 0.9],
    "guichang": [0.25, 0.6, 0.82, 1.0],
}


func _ready() -> void:
    var args := {}
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--") and a.contains("="):
            var kv := a.substr(2).split("=", true, 1)
            args[kv[0]] = kv[1]
    var skill := String(args.get("skill", "ilseom"))
    var out := String(args.get("out", "shots/verify/fx"))

    # 연출 자체를 보려는 프리뷰이므로 전역 어둠(WorldTint)·비(Weather)는 끈다.
    if WorldTint and WorldTint.has_method("set_tint"):
        WorldTint.set_tint(Color.WHITE)
    elif WorldTint and "_modulate" in WorldTint and WorldTint._modulate != null:
        WorldTint._modulate.color = Color.WHITE
    if Weather and Weather is CanvasLayer:
        (Weather as CanvasLayer).visible = false

    # 배경 — 밤빛 먹색(이펙트 대비 확인)
    var bg := ColorRect.new()
    bg.color = Color(0.13, 0.13, 0.14)
    bg.position = Vector2(-200, -200)
    bg.size = Vector2(1800, 1200)
    bg.z_index = -50
    add_child(bg)
    # 지면 선
    var ground := ColorRect.new()
    ground.color = Color(0.22, 0.19, 0.17)
    ground.position = Vector2(-200, GROUND_Y)
    ground.size = Vector2(1800, 400)
    ground.z_index = -40
    add_child(ground)
    var body := StaticBody2D.new()
    body.collision_layer = 4
    body.position = Vector2(640, GROUND_Y + 16)
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(2400, 32)
    cs.shape = shape
    body.add_child(cs)
    add_child(body)

    var cam := Camera2D.new()
    cam.position = Vector2(640, 330)
    add_child(cam)
    cam.make_current()

    var player: Node2D = load(PLAYER).instantiate()
    add_child(player)
    player.global_position = Vector2(360, GROUND_Y - 40)

    # 맞을 대상 몇 마리 — 타격 이펙트가 같이 보이게
    for i in range(3):
        var e: Node2D = load(ENEMY).instantiate()
        add_child(e)
        e.global_position = Vector2(560.0 + i * 130.0, GROUND_Y - 40)

    await get_tree().process_frame
    await get_tree().create_timer(0.3).timeout      # 착지 안정

    SkillManager.reset_cooldowns()
    SkillManager.try_cast(skill)

    var times: Array = SHOTS.get(skill, [0.1, 0.3, 0.6])
    var prev := 0.0
    for i in range(times.size()):
        var t := float(times[i])
        await get_tree().create_timer(maxf(0.01, t - prev)).timeout
        prev = t
        await RenderingServer.frame_post_draw
        _save("%s_%d.png" % [out, i])
    get_tree().quit(0)


func _save(path: String) -> void:
    var img := get_viewport().get_texture().get_image()
    var abs_out := path if path.begins_with("res://") else "res://" + path
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://") + abs_out.get_base_dir().trim_prefix("res://"))
    var err := img.save_png(ProjectSettings.globalize_path(abs_out))
    print("[FxShot] %s (err=%d)" % [abs_out, err])
