extends Node2D
## SkillFx 정적 미리보기 — 효과를 한 화면에 스폰해 캡처(개발용).
## 사용: godot --path . res://tools/FxPreview.tscn  (shots/fx_preview.png 저장 후 종료)

func _ready() -> void:
    # current_scene 가 세워질 때까지 양보
    await get_tree().process_frame
    await get_tree().process_frame
    var y := 360.0
    SkillFx.combo(Vector2(170, y), true, 1)
    SkillFx.combo(Vector2(400, y), true, 2)
    SkillFx.combo(Vector2(650, y), true, 3)
    SkillFx.slash(Vector2(870, y), true)
    SkillFx.spin(Vector2(1050, y))
    SkillFx.impact(Vector2(1190, y), true)
    # 효과가 한창일 때 캡처
    await get_tree().create_timer(0.09).timeout
    await RenderingServer.frame_post_draw
    var img := get_viewport().get_texture().get_image()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
    img.save_png(ProjectSettings.globalize_path("res://shots/fx_preview.png"))
    print("[FxPreview] saved shots/fx_preview.png")
    get_tree().quit(0)
