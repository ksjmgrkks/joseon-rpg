extends Node2D
## 콤보 포즈 + 이펙트 + 잔상 미리보기(개발용).
## 3타 회전 내려찍기 포즈에 combo fx + 애프터이미지 트레일을 함께 캡처.

func _ready() -> void:
    await get_tree().process_frame
    var sf := SpriteDb.frames("protagonist_custom")
    if sf == null:
        push_error("custom frames 없음"); get_tree().quit(1); return
    # 1타·2타·3타 포즈를 가로로 배치
    var specs := [["attack", 7, 320.0], ["attack2", 7, 640.0], ["attack3", 10, 960.0]]
    var steps := [1, 2, 3]
    for i in range(specs.size()):
        var spec: Array = specs[i]
        var spr := AnimatedSprite2D.new()
        spr.sprite_frames = sf
        spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        spr.animation = String(spec[0])
        spr.scale = Vector2(2, 2)
        spr.position = Vector2(float(spec[2]), 380.0)
        spr.frame = int(spec[1])
        spr.pause()
        add_child(spr)
        SkillFx.combo(spr.position + Vector2(0, -32), true, steps[i])
        SkillFx.afterimage_burst(spr, SkillFx.MAGE if steps[i] < 3 else SkillFx.MAGE_HOT, 3, 0.18)
    await get_tree().create_timer(0.10).timeout
    await RenderingServer.frame_post_draw
    var img := get_viewport().get_texture().get_image()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
    img.save_png(ProjectSettings.globalize_path("res://shots/combo_pose.png"))
    print("[ComboPose] saved shots/combo_pose.png")
    get_tree().quit(0)
