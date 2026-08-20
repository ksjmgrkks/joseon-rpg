extends Node
##
## 스테이지 선택 화면 검증 (헤드리스).
## 실행: `godot --headless res://tests/test_stage_select.tscn`
##
## "새로 시작"이 1/2/3스테이지 중 하나를 고르는 화면으로 이어지고,
## 각 카드가 정확한 체인 시작 씬으로 연결되는지 확인한다.
##

const PASS := "PASS"
const FAIL := "FAIL"
const SELECT_SCENE := preload("res://scenes/ui/StageSelect.tscn")

const EXPECTED_SCENES := [
    "res://scenes/levels/Foothills.tscn",
    "res://scenes/levels/ForestShadow.tscn",
    "res://scenes/levels/MarketRuins.tscn",
]


func _ready() -> void:
    print("=== test_stage_select ===")
    var results: Array[Dictionary] = []
    results.append(_check_main_menu_opens_select())
    results.append(await _check_cards_built())
    results.append(await _check_pick_emits_scene())
    results.append(_check_art_assets_present())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _check_main_menu_opens_select() -> Dictionary:
    var mm_script: GDScript = load("res://scripts/ui/main_menu.gd")
    var src := mm_script.get_source_code()
    if not src.contains("STAGE_SELECT_SCENE"):
        return { "name": "main_menu_wires_stage_select", "status": FAIL,
            "reason": "main_menu.gd 에 STAGE_SELECT_SCENE 참조 없음 — '새로 시작'이 선택 화면을 안 엶" }
    if not src.contains("_on_stage_picked"):
        return { "name": "main_menu_wires_stage_select", "status": FAIL,
            "reason": "stage_chosen 신호 핸들러(_on_stage_picked) 없음" }
    return { "name": "main_menu_wires_stage_select", "status": PASS, "reason": "" }


func _check_cards_built() -> Dictionary:
    var inst := SELECT_SCENE.instantiate()
    add_child(inst)
    await get_tree().process_frame
    var cards: VBoxContainer = inst.get_node("Margin/VBox/Cards")
    var count := cards.get_child_count()
    inst.queue_free()
    if count != 3:
        return { "name": "three_stage_cards", "status": FAIL,
            "reason": "카드 %d개 생성됨 (기대: 3)" % count }
    return { "name": "three_stage_cards", "status": PASS, "reason": "" }


func _check_pick_emits_scene() -> Dictionary:
    var inst := SELECT_SCENE.instantiate()
    add_child(inst)
    await get_tree().process_frame
    var stages: Array = inst.STAGES
    if stages.size() != EXPECTED_SCENES.size():
        inst.queue_free()
        return { "name": "stage_scene_paths", "status": FAIL,
            "reason": "STAGES 개수 %d (기대 %d)" % [stages.size(), EXPECTED_SCENES.size()] }
    for i in range(stages.size()):
        var got := String(stages[i].get("scene", ""))
        if got != EXPECTED_SCENES[i]:
            inst.queue_free()
            return { "name": "stage_scene_paths", "status": FAIL,
                "reason": "슬롯 %d 씬 경로 불일치: %s (기대 %s)" % [i, got, EXPECTED_SCENES[i]] }
    var picked := [""]   # 배열로 감싸야 람다가 참조로 캡처(GDScript 람다는 값 캡처)
    inst.stage_chosen.connect(func(p: String) -> void: picked[0] = p)
    var cards: VBoxContainer = inst.get_node("Margin/VBox/Cards")
    (cards.get_child(1) as BaseButton).pressed.emit()
    inst.queue_free()
    if picked[0] != EXPECTED_SCENES[1]:
        return { "name": "pick_emits_stage_chosen", "status": FAIL,
            "reason": "2번 카드 클릭 시 emit 경로 %s (기대 %s)" % [picked[0], EXPECTED_SCENES[1]] }
    return { "name": "pick_emits_stage_chosen", "status": PASS, "reason": "" }


func _check_art_assets_present() -> Dictionary:
    for p in ["res://assets/ui/stage_select_window.png", "res://assets/ui/stage_select_button.png"]:
        if not ResourceLoader.exists(p):
            return { "name": "pixellab_art_present", "status": FAIL,
                "reason": "%s 없음 — 플레이스홀더로 폴백" % p }
    return { "name": "pixellab_art_present", "status": PASS, "reason": "" }
