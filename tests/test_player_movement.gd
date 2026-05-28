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
