extends Node
##
## SceneManager + LevelEntry 헤드리스 테스트.
## 헤드리스에서 실 fade tween + change_scene_to_file 까지 돌리면 화면 컨텍스트가
## 변동성이 있으니, 여기서는 _apply_pending_entry 로직만 격리해 검증한다.
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_scene ===")
    var results: Array[Dictionary] = []
    results.append(_check_entry_match())
    results.append(_check_entry_no_match())
    results.append(_check_entry_no_player())
    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


# 매칭되는 LevelEntry 가 있을 때 player가 그 위치로 옮겨지는지
func _check_entry_match() -> Dictionary:
    var player := _make_player(Vector2(50, 50))
    add_child(player)

    var entry := _make_entry("from_field", Vector2(900, 400))
    add_child(entry)

    SceneManager._pending_entry = &"from_field"
    SceneManager._apply_pending_entry()

    var ok := player.global_position.is_equal_approx(Vector2(900, 400))
    var entry_cleared := SceneManager._pending_entry == &""
    player.queue_free()
    entry.queue_free()
    await get_tree().process_frame
    if not ok:
        return { "name": "entry_match", "status": FAIL, "reason": "player at %s expected (900,400)" % player.global_position }
    if not entry_cleared:
        return { "name": "entry_match", "status": FAIL, "reason": "_pending_entry not cleared after apply" }
    return { "name": "entry_match", "status": PASS, "reason": "" }


# 매칭되는 LevelEntry 가 없을 때는 player 위치 유지
func _check_entry_no_match() -> Dictionary:
    var origin := Vector2(123, 456)
    var player := _make_player(origin)
    add_child(player)
    var entry := _make_entry("from_village", Vector2(900, 400))
    add_child(entry)

    SceneManager._pending_entry = &"from_forest"
    SceneManager._apply_pending_entry()

    var unchanged := player.global_position.is_equal_approx(origin)
    var entry_cleared := SceneManager._pending_entry == &""
    player.queue_free()
    entry.queue_free()
    await get_tree().process_frame
    if not unchanged:
        return { "name": "entry_no_match", "status": FAIL, "reason": "player moved to %s" % player.global_position }
    if not entry_cleared:
        return { "name": "entry_no_match", "status": FAIL, "reason": "_pending_entry not cleared after no-match" }
    return { "name": "entry_no_match", "status": PASS, "reason": "" }


# player 가 그룹에 없을 때도 안전하게 종료 + 마커 자체는 매칭되어도 player가 없으면 no-op
func _check_entry_no_player() -> Dictionary:
    var entry := _make_entry("solo", Vector2(900, 400))
    add_child(entry)

    SceneManager._pending_entry = &"solo"
    SceneManager._apply_pending_entry()
    var entry_cleared := SceneManager._pending_entry == &""
    entry.queue_free()
    await get_tree().process_frame
    if not entry_cleared:
        return { "name": "entry_no_player", "status": FAIL, "reason": "_pending_entry not cleared when no player" }
    return { "name": "entry_no_player", "status": PASS, "reason": "" }


# 작은 헬퍼 — 실제 Player 씬을 띄우면 의존성이 너무 많으니 그룹 + Node2D 만으로 충분
func _make_player(pos: Vector2) -> Node2D:
    var p := Node2D.new()
    p.global_position = pos
    p.add_to_group("player")
    return p


func _make_entry(entry_name: String, pos: Vector2) -> Node2D:
    var m := Marker2D.new()
    m.name = entry_name
    m.global_position = pos
    m.add_to_group("level_entry")
    return m
