extends Node
##
## 물귀신 붙잡기 — 맞으면 이동이 느려지고, 반드시 되돌아온다.
## 실행: `godot --headless res://tests/test_mulgwisin.tscn`
##
## 되돌리기가 빠지면 스테이지 내내 느린 채로 남는 치명적 버그가 된다(그림자 늪과 같은 훅을 공유).
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_mulgwisin ===")
    var results: Array[Dictionary] = [await _check_grab_slows_then_restores()]
    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _check_grab_slows_then_restores() -> Dictionary:
    var m: Node = load("res://scenes/enemies/Mulgwisin.tscn").instantiate()
    add_child(m)
    m.grab_slow_seconds = 0.15   # 테스트용으로 짧게
    var player: Node2D = load("res://scenes/player/Player.tscn").instantiate()
    add_child(player)
    # 적 AI 가 진짜 공격을 걸어 감속을 재적용하면 복구 검사가 흔들린다 — 사거리 밖으로 치운다.
    player.global_position = Vector2(4000, 0)
    await get_tree().process_frame

    m._on_attack_hit(player)
    await get_tree().process_frame
    var slowed: bool = player.move_speed_mult < 1.0
    await get_tree().create_timer(0.4).timeout
    var restored: bool = is_equal_approx(player.move_speed_mult, 1.0)

    var ok := slowed and restored
    var reason := "" if ok else "직후 배율=%.2f(느려져야 함) / 0.4초 뒤=%.2f(1.0 이어야 함)" % [
        player.move_speed_mult, player.move_speed_mult]
    m.queue_free()
    player.queue_free()
    return { "name": "붙잡기_감속_후_복구", "status": PASS if ok else FAIL, "reason": reason }
