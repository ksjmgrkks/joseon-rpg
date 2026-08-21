extends Node2D
## SkillFx 정적 미리보기 — 효과를 한 화면에 스폰해 캡처(개발용).
## 사용: godot --path . res://tools/FxPreview.tscn -- --wait=0.09 --out=shots/fx_preview.png

func _ready() -> void:
    var args := {}
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--") and a.contains("="):
            var kv := a.substr(2).split("=", true, 1)
            args[kv[0]] = kv[1]
    var wait_s := float(args.get("wait", "0.09"))
    var out_path := String(args.get("out", "shots/fx_preview.png"))

    # current_scene 가 세워질 때까지 양보
    await get_tree().process_frame
    await get_tree().process_frame
    var y := 300.0
    SkillFx.combo(Vector2(170, y), true, 1)
    SkillFx.combo(Vector2(400, y), true, 2)
    SkillFx.combo(Vector2(650, y), true, 3)
    SkillFx.slash(Vector2(870, y), true, SkillFx.GOLD)
    SkillFx.impact(Vector2(1190, y), true)
    # 진혼(해원) 스킬 4종 — 도혼참 / 진혼등 / 호신부 / 귀창 강림
    SkillFx.river_cleave(Vector2(170, y + 150), true)
    SkillFx.requiem_lantern(Vector2(430, y + 150))
    SkillFx.ward_cast(Vector2(680, y + 150))
    # ultimate() 은 전체화면 섬광(CanvasLayer)을 덮어써서 그리드 프리뷰를 가려버리니
    # --ult=1 일 때만 단독으로 켠다(다른 이펙트와 같이 캡처하지 않음).
    if args.get("ult", "0") == "1":
        SkillFx.ultimate(Vector2(950, y + 150))
    # 전투 마무리 VFX — 차지 오라 / 혼 흩어짐 / 보스 등장
    SkillFx.charge_aura_tick(Vector2(170, y + 300), 1)
    SkillFx.charge_aura_tick(Vector2(400, y + 300), 2)
    SkillFx.death_scatter(Vector2(650, y + 300))
    SkillFx.death_scatter(Vector2(870, y + 300), Color(0.82, 0.84, 0.92), true)
    SkillFx.boss_entrance(Vector2(1100, y + 300))
    # 효과가 한창일 때 캡처
    await get_tree().create_timer(wait_s).timeout
    await RenderingServer.frame_post_draw
    var img := get_viewport().get_texture().get_image()
    var abs_out := out_path if out_path.begins_with("res://") else "res://" + out_path
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(abs_out.get_base_dir()))
    img.save_png(ProjectSettings.globalize_path(abs_out))
    print("[FxPreview] saved %s (wait=%.2f)" % [abs_out, wait_s])
    get_tree().quit(0)
