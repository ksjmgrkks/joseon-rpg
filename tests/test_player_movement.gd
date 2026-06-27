extends Node
##
## 헤드리스 자동 테스트 — 플레이어 이동/중력/InputMap 검증.
## 실행: `godot --headless res://tests/test_player_movement.tscn`
## 종료 코드: 0 = 모두 통과, 1 = 실패 1건 이상.
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_player_movement ===")
    var results: Array[Dictionary] = []

    results.append(_check_input_map())
    results.append(_check_player_scene())
    results.append(await _check_player_gravity())
    results.append(await _check_variable_jump())
    results.append(await _check_coyote_jump())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)

    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _check_input_map() -> Dictionary:
    var required := ["move_left", "move_right", "jump", "attack", "interact"]
    for action in required:
        if not InputMap.has_action(action):
            return { "name": "input_map_actions", "status": FAIL, "reason": "missing action: %s" % action }
    return { "name": "input_map_actions", "status": PASS, "reason": "" }


func _check_player_scene() -> Dictionary:
    var scene := load("res://scenes/player/Player.tscn") as PackedScene
    if scene == null:
        return { "name": "player_scene_loads", "status": FAIL, "reason": "scene not found" }
    var inst := scene.instantiate()
    if inst == null:
        return { "name": "player_scene_loads", "status": FAIL, "reason": "instantiate failed" }
    var is_body := inst is CharacterBody2D
    inst.queue_free()
    if not is_body:
        return { "name": "player_scene_loads", "status": FAIL, "reason": "root is not CharacterBody2D" }
    return { "name": "player_scene_loads", "status": PASS, "reason": "" }


func _check_player_gravity() -> Dictionary:
    var scene := load("res://scenes/player/Player.tscn") as PackedScene
    var player: CharacterBody2D = scene.instantiate()
    add_child(player)
    player.position = Vector2(100.0, 0.0)
    var initial_y := player.position.y

    # 1초 정도 물리 프레임 진행 (60fps 가정)
    for i in 60:
        await get_tree().physics_frame

    var moved := player.position.y - initial_y
    player.queue_free()

    if moved <= 0.0:
        return { "name": "player_gravity_falls", "status": FAIL, "reason": "y did not increase (moved=%f)" % moved }
    return { "name": "player_gravity_falls", "status": PASS, "reason": "fell %.1f px" % moved }


# ── 조작 손맛 검증용 헬퍼 ──
const FLOOR_TOP_Y := 300.0

# 넓은 바닥(StaticBody2D) 생성 — 윗면이 FLOOR_TOP_Y. 기본 layer 1 = 플레이어 mask 1 과 충돌.
func _make_floor() -> StaticBody2D:
    var body := StaticBody2D.new()
    body.position = Vector2(0.0, FLOOR_TOP_Y + 20.0)   # 중심; 윗면 = FLOOR_TOP_Y
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(4000.0, 40.0)
    cs.shape = shape
    body.add_child(cs)
    return body

# 바닥 위 플레이어를 만들고 안정화시켜 (player, floor) 반환
func _spawn_on_floor() -> Array:
    var scene := load("res://scenes/player/Player.tscn") as PackedScene
    var player: CharacterBody2D = scene.instantiate()
    var floor_body := _make_floor()
    add_child(floor_body)
    add_child(player)
    player.global_position = Vector2(0.0, FLOOR_TOP_Y - 16.0)   # 충돌 박스(16x32) 발끝이 바닥 윗면
    for i in 18:
        await get_tree().physics_frame
    return [player, floor_body]


# 점프키를 hold_frames 프레임 동안 누르고 있을 때 도달한 최고 높이(px, 위로 양수)
func _jump_peak(hold_frames: int) -> float:
    var pair := await _spawn_on_floor()
    var player: CharacterBody2D = pair[0]
    var floor_body: StaticBody2D = pair[1]
    var rest_y := player.global_position.y
    var min_y := rest_y
    Input.action_press("jump")
    for i in 220:
        await get_tree().physics_frame
        if i == hold_frames:
            Input.action_release("jump")
        min_y = minf(min_y, player.global_position.y)
        if i > hold_frames + 3 and player.is_on_floor() and player.global_position.y >= rest_y - 1.0:
            break
    Input.action_release("jump")
    var peak := rest_y - min_y
    player.queue_free()
    floor_body.queue_free()
    await get_tree().physics_frame
    return peak


# 가변 점프 — 짧게 탭한 점프가 길게 누른 점프보다 낮아야 한다(손맛: 단타/풀점프 구분)
func _check_variable_jump() -> Dictionary:
    var tap := await _jump_peak(1)
    var hold := await _jump_peak(60)
    if tap <= 1.0:
        return { "name": "variable_jump", "status": FAIL, "reason": "tap jump produced no height (%.1f)" % tap }
    if hold <= tap + 6.0:
        return { "name": "variable_jump", "status": FAIL, "reason": "hold(%.1f) not higher than tap(%.1f)" % [hold, tap] }
    return { "name": "variable_jump", "status": PASS, "reason": "tap=%.1f < hold=%.1f" % [tap, hold] }


# 코요테 타임 — 발판을 막 떠난 직후(윈도우 내)에도 점프가 먹어야 한다
func _check_coyote_jump() -> Dictionary:
    var pair := await _spawn_on_floor()
    var player: CharacterBody2D = pair[0]
    var floor_body: StaticBody2D = pair[1]
    # 발판에서 살짝 띄운다(아직 코요테 윈도우 안)
    player.global_position.y -= 28.0
    await get_tree().physics_frame   # 이 프레임 뒤 is_on_floor=false, 코요테 카운트 시작
    Input.action_press("jump")
    var jumped := false
    for i in 4:
        await get_tree().physics_frame
        if player.velocity.y < -100.0:
            jumped = true
            break
    Input.action_release("jump")
    var vy := player.velocity.y
    player.queue_free()
    floor_body.queue_free()
    await get_tree().physics_frame
    if not jumped:
        return { "name": "coyote_jump", "status": FAIL, "reason": "no jump after leaving floor (vy=%.1f)" % vy }
    return { "name": "coyote_jump", "status": PASS, "reason": "coyote jump fired (vy=%.1f)" % vy }
