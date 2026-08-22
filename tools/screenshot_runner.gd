extends Node
##
## 스크린샷 러너 — 비주얼 자체 검증용. (헤드리스 아님 — 창이 잠깐 뜬다)
##
## 사용:
##   godot --path . res://tools/Screenshot.tscn -- --scene=res://scenes/levels/Village.tscn --out=shots/village.png [--wait=0.6] [--night]
##   --dodge 를 더하면 캡처 직전 플레이어의 실제 회피 상태를 시작한다.
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

    # 캡처 프로세스가 시작되는 순간 물리 키가 눌려 있으면 autoload 패널이 토글될 수 있다.
    # 전역 메뉴를 비활성화하고 닫아 결과가 입력 상태에 좌우되지 않게 한다.
    var overlay_panels: Array[CanvasItem] = []
    for overlay_name in [
        "InventoryPanel",
        "ShopPanel",
        "PauseMenu",
        "QuestLog",
        "QuestToast",
        "GameOverScreen",
    ]:
        var overlay_root := get_node_or_null("/root/" + overlay_name)
        if overlay_root:
            overlay_root.process_mode = Node.PROCESS_MODE_DISABLED
            var panel := overlay_root.get_node_or_null("Panel") as CanvasItem
            if panel:
                panel.visible = false
                overlay_panels.append(panel)

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

    # 실제 Player/PlayerVisual 경로로 구르기 애니메이션이 선택되는지 캡처한다.
    if args.has("dodge"):
        # 스폰 직후 공중 자세가 섞이지 않도록 먼저 지면에 안착시킨다.
        for i in range(45):
            await get_tree().physics_frame
        var players := get_tree().get_nodes_in_group("player")
        if not players.is_empty() and players[0].has_method("_start_dodge"):
            players[0].call("_start_dodge")
            print("[Shot] dodge started on %s" % players[0].name)

    # --touch : 데스크톱에서도 모바일 터치 컨트롤을 강제로 켜서 폰 화면을 그대로 확인
    if args.has("touch"):
        await get_tree().process_frame
        _force_touch_ui(get_tree().root)

    await get_tree().create_timer(wait_s).timeout
    # 위 대기 중 늦게 전달된 키 입력까지 정리한다.
    for overlay in overlay_panels:
        if is_instance_valid(overlay):
            overlay.visible = false
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


# 트리에서 MobileControls 를 찾아 강제로 보이게 (캡처용)
func _force_touch_ui(n: Node) -> void:
    if n.name == "MobileControls" and n is CanvasLayer:
        (n as CanvasLayer).visible = true
    # 폰에서는 HUD 스킬 줄이 숨는다(터치 버튼이 대신함) — 캡처도 같은 화면이 되게.
    if n.name == "SkillRow" and n is CanvasItem:
        (n as CanvasItem).visible = false
    for c in n.get_children():
        _force_touch_ui(c)
