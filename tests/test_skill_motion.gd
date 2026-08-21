extends Node
##
## 스킬 '움직임' 검증 (헤드리스) — 연출이 아니라 위치·상태가 제대로 돌아오는지.
## 실행: `godot --headless res://tests/test_skill_motion.tscn`
##
## 1) 「도혼참」: 시전(windup) 뒤 일직선으로 실제로 멀리 이동하는가, 끝나면 조작이 풀리는가
## 2) 「귀창 강림」: 공중에 떴다가 **반드시 원래 높이로 돌아오는가** (부양 상태가 남으면 중력이
##    꺼진 채 얼어붙는다 — 가장 위험한 회귀)
##

const PASS := "PASS"
const FAIL := "FAIL"
const GROUND_Y := 470.0


func _ready() -> void:
    print("=== test_skill_motion ===")
    var results: Array[Dictionary] = []
    results.append(await _check_ilseom_travels())
    results.append(await _check_ultimate_returns_to_ground())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


# 지면 + 플레이어만 있는 최소 무대
func _stage() -> Node2D:
    var root := Node2D.new()
    add_child(root)
    var body := StaticBody2D.new()
    body.collision_layer = 4
    body.position = Vector2(640, GROUND_Y + 16)
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(3000, 32)
    cs.shape = shape
    body.add_child(cs)
    root.add_child(body)
    return root


func _spawn_player(root: Node2D) -> Node2D:
    var p: Node2D = load("res://scenes/player/Player.tscn").instantiate()
    root.add_child(p)
    p.global_position = Vector2(300, GROUND_Y - 40)
    await get_tree().process_frame
    for i in range(20):
        await get_tree().physics_frame        # 착지 안정
    return p


func _wait(seconds: float) -> void:
    await get_tree().create_timer(seconds).timeout


func _check_ilseom_travels() -> Dictionary:
    var root := _stage()
    var p := await _spawn_player(root)
    SkillManager.reset_cooldowns()
    var x0: float = p.global_position.x
    SkillManager.try_cast("ilseom")
    # windup(0.32) 동안에는 아직 크게 안 움직인다
    await _wait(0.2)
    var x_windup: float = p.global_position.x
    # windup + dash(0.42) + 여유
    await _wait(0.75)
    var x1: float = p.global_position.x
    var moved: float = x1 - x0
    var windup_moved: float = absf(x_windup - x0)
    var attacking: bool = p.get("_attacking")
    root.queue_free()
    if windup_moved > 60.0:
        return { "name": "ilseom_windup_then_dash", "status": FAIL,
            "reason": "시전 중 이미 %.0fpx 이동 (돌진이 먼저 나감)" % windup_moved }
    if moved < 120.0:
        return { "name": "ilseom_windup_then_dash", "status": FAIL,
            "reason": "돌진 거리 %.0fpx (120px 이상 기대)" % moved }
    if attacking:
        return { "name": "ilseom_windup_then_dash", "status": FAIL, "reason": "끝난 뒤에도 _attacking 이 참" }
    return { "name": "ilseom_windup_then_dash", "status": PASS, "reason": "" }


func _check_ultimate_returns_to_ground() -> Dictionary:
    var root := _stage()
    var p := await _spawn_player(root)
    SkillManager.reset_cooldowns()
    var y0: float = p.global_position.y
    SkillManager.try_cast("guichang")
    # 시전 중에는 실제로 떠 있어야 한다
    await _wait(0.4)
    var y_air: float = p.global_position.y
    var hovering: bool = p.get("_hover_lock")
    # charge(0.65) + slam(0.12) + 마무리(0.4) + 여유
    await _wait(1.1)
    var y1: float = p.global_position.y
    var still_hover: bool = p.get("_hover_lock")
    var attacking: bool = p.get("_attacking")
    root.queue_free()
    if not hovering or y_air > y0 - 40.0:
        return { "name": "ultimate_rise_and_land", "status": FAIL,
            "reason": "시전 중 부양 안 함 (y %.0f→%.0f, hover=%s)" % [y0, y_air, str(hovering)] }
    if still_hover:
        return { "name": "ultimate_rise_and_land", "status": FAIL, "reason": "끝난 뒤에도 부양 상태(중력 꺼짐)" }
    if absf(y1 - y0) > 12.0:
        return { "name": "ultimate_rise_and_land", "status": FAIL,
            "reason": "착지 높이가 다름 (%.0f → %.0f)" % [y0, y1] }
    if attacking:
        return { "name": "ultimate_rise_and_land", "status": FAIL, "reason": "끝난 뒤에도 _attacking 이 참" }
    return { "name": "ultimate_rise_and_land", "status": PASS, "reason": "" }
