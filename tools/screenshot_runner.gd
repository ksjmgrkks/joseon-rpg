extends Node
##
## 스크린샷 러너 — 비주얼 자체 검증용. (헤드리스 아님 — 창이 잠깐 뜬다)
##
## 사용:
##   godot --path . res://tools/Screenshot.tscn -- --scene=res://scenes/levels/Village.tscn --out=shots/village.png [--wait=0.6] [--night]
##
## 동작: 대상 씬을 로드해 current_scene 으로 세우고, wait 초 + 한 프레임 그린 뒤
## 뷰포트를 PNG 로 저장하고 종료. --night 면 TimeManager 를 밤으로 고정.
##

func _ready() -> void:
    var args := {}
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--") and a.contains("="):
            var kv := a.substr(2).split("=", true, 1)
            args[kv[0]] = kv[1]
        elif a.begins_with("--"):
            args[a.substr(2)] = "true"

    var scene_path := String(args.get("scene", ""))
    var out_path := String(args.get("out", "shots/capture.png"))
    var wait_s := float(args.get("wait", "0.6"))

    if scene_path.is_empty():
        push_error("[Shot] --scene= 이 필요합니다")
        get_tree().quit(2)
        return

    # 자동 저장 등 부작용 차단
    if SceneManager:
        SceneManager.autosave_on_scene_change = false
    if TimeManager:
        TimeManager.set_paused(true)
        TimeManager.set_time(0.85 if args.has("night") else 0.2)
        if WorldTint and WorldTint.has_method("_on_time_changed"):
            WorldTint._on_time_changed(TimeManager.time_of_day)

    var packed: PackedScene = load(scene_path)
    if packed == null:
        push_error("[Shot] 씬 로드 실패: %s" % scene_path)
        get_tree().quit(2)
        return
    var inst := packed.instantiate()
    # _ready 중에는 root 가 자식 셋업 중이라 add_child 가 거부됨 — 한 프레임 양보
    await get_tree().process_frame
    get_tree().root.add_child(inst)
    get_tree().current_scene = inst

    # --cam=x,y : 플레이어(=카메라 부모)를 옮겨 원하는 지점을 프레이밍
    if args.has("cam"):
        var parts := String(args["cam"]).split(",")
        if parts.size() == 2:
            var players := get_tree().get_nodes_in_group("player")
            if not players.is_empty() and players[0] is Node2D:
                (players[0] as Node2D).global_position = Vector2(float(parts[0]), float(parts[1]))

    # 선택: 플레이어를 특정 x 로 옮겨 그 지점을 카메라에 담음
    if args.has("player_x"):
        await get_tree().process_frame
        var players := get_tree().get_nodes_in_group("player")
        if not players.is_empty() and players[0] is Node2D:
            (players[0] as Node2D).global_position.x = float(args["player_x"])

    await get_tree().create_timer(wait_s).timeout
    await RenderingServer.frame_post_draw

    var img := get_viewport().get_texture().get_image()
    var abs_out := out_path
    if not abs_out.begins_with("res://") and not abs_out.begins_with("user://") and not abs_out.contains(":"):
        abs_out = "res://" + abs_out
    # res:// 하위 디렉터리 보장
    if abs_out.begins_with("res://"):
        var dir := abs_out.get_base_dir().trim_prefix("res://")
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + dir)
    var err := img.save_png(ProjectSettings.globalize_path(abs_out))
    print("[Shot] %s -> %s (err=%d)" % [scene_path, abs_out, err])
    get_tree().quit(0 if err == OK else 1)
