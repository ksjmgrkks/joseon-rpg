extends Node
##
## 메탈슬러그식 통과 판정 테스트 (2026-08-15 스코어어택 개편).
##   ① 플레이어가 적(Dummy) 몸을 그대로 통과해 지나간다 (몸 충돌로 막히지 않음).
##   ② 단순 겹침(접촉)으로는 피해를 입지 않는다 (공격 hitbox/hurtbox 로만 피해).
## 실행: `godot --headless res://tests/test_passthrough.tscn`
##

const PASS := "PASS"
const FAIL := "FAIL"
const PLAYER := preload("res://scenes/player/Player.tscn")
const DUMMY := preload("res://scenes/enemies/Dummy.tscn")

const FLOOR_TOP_Y := 300.0


func _ready() -> void:
    print("=== test_passthrough ===")
    var results: Array[Dictionary] = []
    results.append(await _check_walks_through_enemy())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _make_floor() -> StaticBody2D:
    var body := StaticBody2D.new()
    body.collision_layer = 4   # 월드 레이어 (플레이어·적 mask=4 와 충돌)
    body.position = Vector2(0.0, FLOOR_TOP_Y + 20.0)
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(4000.0, 40.0)
    cs.shape = shape
    body.add_child(cs)
    return body


func _check_walks_through_enemy() -> Dictionary:
    var floor_body := _make_floor()
    add_child(floor_body)
    var player: CharacterBody2D = PLAYER.instantiate()
    add_child(player)
    player.global_position = Vector2(0.0, FLOOR_TOP_Y - 16.0)
    var enemy: CharacterBody2D = DUMMY.instantiate()
    add_child(enemy)
    var enemy_x := 60.0
    enemy.global_position = Vector2(enemy_x, FLOOR_TOP_Y - 16.0)

    # 안정화
    for i in 20:
        await get_tree().physics_frame

    var hc = player.get_node_or_null("HealthComponent")
    var hp_before: float = hc.hp if hc else -1.0

    # 오른쪽으로 달려 적 몸을 통과한다
    Input.action_press("move_right")
    for i in 120:
        await get_tree().physics_frame
        if player.global_position.x > enemy_x + 40.0:
            break
    Input.action_release("move_right")

    var px := player.global_position.x
    var hp_after: float = hc.hp if hc else -1.0
    var enemy_alive := is_instance_valid(enemy)

    player.queue_free()
    if enemy_alive:
        enemy.queue_free()
    floor_body.queue_free()
    await get_tree().physics_frame

    # ① 적 x 를 확실히 지나갔는가 (몸 충돌이면 enemy_x 근처에서 막힘)
    if px <= enemy_x + 30.0:
        return { "name": "walk_through_enemy", "status": FAIL,
            "reason": "적 몸에 막힘 — player.x=%.1f (enemy.x=%.1f)" % [px, enemy_x] }
    # ② 단순 접촉으로 피해 없음
    if hc and hp_after < hp_before - 0.01:
        return { "name": "walk_through_enemy", "status": FAIL,
            "reason": "접촉만으로 피해 발생 %.1f→%.1f" % [hp_before, hp_after] }
    return { "name": "walk_through_enemy", "status": PASS,
        "reason": "통과 x=%.1f, HP %.1f 유지" % [px, hp_after] }
