extends Node
##
## 대화 말풍선 시각 검증용 스크린샷 러너(임시 — 검증 후 삭제 가능).
##   godot --path . res://tools/DlgShot.tscn -- --dialogue=res://...json --adv=2 --erase=4 --out=shots/x.png
## 동작: 베이스 레벨(플레이어+카메라)을 세우고, MemoryLedger 진행도를 erase 만큼 올린 뒤
## 대화를 시작해 adv 번 넘기고, 타이핑을 마친 화면을 PNG 로 저장한다.
##

func _ready() -> void:
    var args := {}
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--") and a.contains("="):
            var kv := a.substr(2).split("=", true, 1)
            args[kv[0]] = kv[1]
        elif a.begins_with("--"):
            args[a.substr(2)] = "true"

    var scene_path := String(args.get("scene", "res://scenes/levels/Haewon1Ferry.tscn"))
    var dlg := String(args.get("dialogue", ""))
    var adv := int(args.get("adv", "0"))
    var erase_n := int(args.get("erase", "0"))
    var out_path := String(args.get("out", "shots/dlg.png"))
    var wait_s := float(args.get("wait", "0.8"))

    if SceneManager:
        SceneManager.autosave_on_scene_change = false

    var packed: PackedScene = load(scene_path)
    if packed == null:
        push_error("[DlgShot] 씬 로드 실패: %s" % scene_path)
        get_tree().quit(2)
        return
    var inst := packed.instantiate()
    await get_tree().process_frame
    get_tree().root.add_child(inst)
    get_tree().current_scene = inst
    await get_tree().create_timer(0.5).timeout    # 스테이지 빌드 + 플레이어 안착

    # 진행도(글자 dissolve 강도)는 레벨 로드 뒤에 세팅 — 로드가 리셋해도 무효화 안 되게.
    if MemoryLedger:
        MemoryLedger.reset()
        for g in range(erase_n):
            MemoryLedger.erase_for_gut(g)

    if dlg != "":
        Dialogue.start(dlg)
        for i in range(adv):
            await get_tree().create_timer(0.25).timeout
            Dialogue.advance()
        await get_tree().create_timer(0.15).timeout
        if DialogueBalloon and DialogueBalloon.has_method("_finish_reveal"):
            DialogueBalloon._finish_reveal()

    await get_tree().create_timer(wait_s).timeout
    await RenderingServer.frame_post_draw

    var img := get_viewport().get_texture().get_image()
    var abs_out := out_path if out_path.begins_with("res://") else "res://" + out_path
    var dir := abs_out.get_base_dir().trim_prefix("res://")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + dir)
    var err := img.save_png(ProjectSettings.globalize_path(abs_out))
    print("[DlgShot] %s + %s adv=%d erase=%d -> %s (err=%d)" % [scene_path, dlg, adv, erase_n, abs_out, err])
    get_tree().quit(0 if err == OK else 1)
