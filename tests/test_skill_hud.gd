extends Node
##
## 스킬 HUD 헤드리스 테스트 — 2026-07-10 (#1 스킬 이름→아이콘 개편).
##   · 스킬 슬롯이 skills.json 의 skill 수(4)만큼 아이콘으로 생성되는지
##   · 각 슬롯이 유저 키설정(InputConfig) 을 반영해 키 라벨을 다는지
##   · 궁극기(skill_4=귀창) 슬롯이 존재하고 그 액션이 skill_4 로 배선되는지
##   · 아이콘 텍스처가 실제 로드되는지(에셋 존재)
##
## 렌더 없이 노드 트리·데이터만 검사하므로 헤드리스로 돈다.
##

const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_skill_hud ===")
    var results: Array[Dictionary] = []
    results.append(await _check_slots())
    results.append(await _check_keys_reflect_config())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _make_hud() -> Node:
    # HUD._ready 는 실제 게임 트리(player 그룹 노드)가 있어야 스킬 슬롯을 짓는다.
    # 여기선 슬롯 빌더 로직만 단위 검증하므로, 인스턴스 후 빌더를 직접 호출한다.
    var packed: PackedScene = load("res://scenes/ui/PlayerHud.tscn")
    var hud := packed.instantiate()
    add_child(hud)
    await get_tree().process_frame   # @onready(skill_row) 해석 대기
    hud._build_skill_slots()
    hud._update_skill_keys()
    return hud


func _slots_of(hud: Node) -> Array:
    var row := hud.get_node("Panel/Margin/VBox/SkillRow")
    return row.get_children()


func _check_slots() -> Dictionary:
    var hud := await _make_hud()
    var slots := _slots_of(hud)
    var want := SkillManager.all_ids().size()
    if slots.size() != want:
        hud.queue_free()
        return _fail("hud_slot_count", "슬롯 %d개, 스킬 %d개 기대" % [slots.size(), want])
    # 각 슬롯에 아이콘 텍스처가 실제로 로드됐는지(첫 자식 TextureRect)
    var missing := ""
    for s in slots:
        var icon := s.get_child(0) as TextureRect
        if icon == null or icon.texture == null:
            missing += "%s " % s.name
    hud.queue_free()
    if missing != "":
        return _fail("hud_slot_count", "아이콘 텍스처 없음: %s" % missing)
    return _pass("hud_slot_count")


func _check_keys_reflect_config() -> Dictionary:
    # skill_4(궁극기)의 키를 임의 키로 재설정 → HUD 가 그 키를 표시해야 한다.
    var hud := await _make_hud()
    var ev := InputEventKey.new()
    ev.physical_keycode = KEY_G
    InputConfig.rebind("skill_4", ev)
    await get_tree().process_frame   # bindings_changed → _update_skill_keys
    var expected := InputConfig.binding_text("skill_4").split(",")[0].strip_edges()

    var found_ult := false
    var key_ok := false
    for s in _slots_of(hud):
        # 슬롯 → skill_4 액션 슬롯(궁극기)인지: 마지막 자식 Label(키)로 판별
        var key_lbl := s.get_child(2) as Label
        if key_lbl != null and key_lbl.text == expected:
            found_ult = true
            key_ok = true
    hud.queue_free()
    if not found_ult:
        return _fail("hud_keys_reflect_config", "재설정한 skill_4 키 '%s' 를 표시하는 슬롯이 없음" % expected)
    return _pass("hud_keys_reflect_config") if key_ok else _fail("hud_keys_reflect_config", "키 라벨 불일치")


func _pass(name_: String) -> Dictionary:
    return {"status": "PASS", "name": name_, "reason": ""}


func _fail(name_: String, reason: String) -> Dictionary:
    return {"status": FAIL, "name": name_, "reason": reason}
