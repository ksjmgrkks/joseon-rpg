extends Node
##
## 낙사 안전망 테스트 — 점프/돌진으로 지면을 벗어나도 플레이어가 무한히 떨어지지 않는지.
##   ① 넓힌 지면 위(시각 흙바닥 전 구간)에서 착지하는지
##   ② 어떤 이유로 지면 아래로 떨어져도 FALL_LIMIT 에서 안전 지점으로 복귀하는지
##

const PASS := "PASS"
const FAIL := "FAIL"

const PLAYER := preload("res://scenes/player/Player.tscn")


func _ready() -> void:
    print("=== test_fall_safety ===")
    var results: Array[Dictionary] = []
    results.append(await _check_lands_on_wide_ground())
    results.append(await _check_recovers_from_void())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


# 들판 씬을 로드해 x=2000(예전엔 지면 충돌 없던 구간) 에서 떨어뜨려 착지하는지
func _check_lands_on_wide_ground() -> Dictionary:
    var level: PackedScene = load("res://scenes/levels/TestLevel.tscn")
    var inst := level.instantiate()
    add_child(inst)
    await get_tree().process_frame
    var player := inst.get_node_or_null("Player") as CharacterBody2D
    if player == null:
        inst.queue_free()
        return _fail("lands_on_wide_ground", "Player 노드 없음")
    # 예전 충돌 경계(1600) 바깥인 x=2000, 공중에서 시작
    player.global_position = Vector2(2000, 300)
    player.velocity = Vector2.ZERO
    var landed := false
    for i in range(180):   # 최대 3초
        await get_tree().physics_frame
        if player.is_on_floor():
            landed = true
            break
    var y := player.global_position.y
    inst.queue_free()
    if not landed:
        return _fail("lands_on_wide_ground", "x=2000 에서 착지 못함 (y=%.0f)" % y)
    if y > 720.0:
        return _fail("lands_on_wide_ground", "착지 y 가 화면 밖 (%.0f)" % y)
    return _pass("lands_on_wide_ground")


# 안전 지점이 설정된 상태에서 구렁에 빠지면 그 지점으로 복귀하는지 (독립 Player 인스턴스)
func _check_recovers_from_void() -> Dictionary:
    var player := PLAYER.instantiate() as CharacterBody2D
    add_child(player)
    await get_tree().physics_frame
    # 안전 지점을 명시적으로 심고 구렁으로 추락
    var safe := Vector2(300, 400)
    player._last_safe_pos = safe
    player._has_safe_pos = true
    player.global_position = Vector2(300, 6000)
    var recovered := false
    for i in range(10):
        await get_tree().physics_frame
        if player.global_position.y <= safe.y + 4.0:
            recovered = true
            break
    var final_y := player.global_position.y
    player.queue_free()
    if not recovered:
        return _fail("recovers_from_void", "복귀 실패 (y=%.0f, 안전 y=%.0f)" % [final_y, safe.y])
    return _pass("recovers_from_void")


func _pass(n: String) -> Dictionary: return { "name": n, "status": PASS, "reason": "" }
func _fail(n: String, r: String) -> Dictionary: return { "name": n, "status": FAIL, "reason": r }
