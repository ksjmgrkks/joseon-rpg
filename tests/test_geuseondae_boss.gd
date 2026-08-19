extends Node
##
## 그슨대 노괴 전용 패턴 검증 (헤드리스).
## 실행: `godot --headless res://tests/test_geuseondae_boss.tscn`
##
## 물 보스에게서 물려받은 패턴만 쓰면 이 보스의 정체성(그림자·유인·거대화)이 안 산다.
## 전용 패턴 3종을 넣었으므로 아래를 지킨다:
##  ① 전용 패턴(그림자 늪·갈퀴 훑기·암전 강습)이 실제로 뽑히는가
##  ② 암전 강습은 페이즈 2 에서만 나오는가 (초반부터 시야를 뺏으면 불합리)
##  ③ 각 패턴이 실제 위험물을 만들어 내는가
##  ④ 갈퀴는 **점프로 넘을 수 있는 높이**인가 (수직 회피 강제, 무조건 맞는 패턴 금지)
##  ⑤ 그림자 늪은 예고 동안 판정이 꺼져 있는가 (피할 시간 보장)
##  ⑥ 늪에서 나오면 이동 배율이 반드시 1.0 으로 복구되는가 (영구 감속 = 최악의 회귀)
##

const PASS := "PASS"
const FAIL := "FAIL"
const GROUND_Y := 600.0


func _ready() -> void:
    print("=== test_geuseondae_boss ===")
    var results: Array[Dictionary] = []
    results.append(_check_patterns_reachable())
    results.append(_check_blackout_phase2_only())
    results.append(await _check_hazards_spawn())
    results.append(_check_claw_jumpable())
    results.append(await _check_pool_warns())
    results.append(await _check_pool_releases_slow())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _boss(phase2: bool = true) -> Node2D:
    var b: Node2D = load("res://scenes/enemies/GeuseondaeElder.tscn").instantiate()
    add_child(b)
    b.global_position = Vector2(700, GROUND_Y)
    if phase2:
        b.set("_phase", 2)
    return b


func _check_patterns_reachable() -> Dictionary:
    var b := _boss(true)
    var seen := {}
    for i in range(500):
        b.set("_last_pattern", -1)
        seen[int(b.call("_choose_pattern"))] = true
    var want := {100: "그림자 늪", 101: "갈퀴 훑기", 102: "암전 강습"}
    b.queue_free()
    for k in want:
        if not seen.has(k):
            return { "name": "shadow_patterns_reachable", "status": FAIL, "reason": "%s 가 한 번도 안 뽑힘" % want[k] }
    return { "name": "shadow_patterns_reachable", "status": PASS, "reason": "3종" }


func _check_blackout_phase2_only() -> Dictionary:
    var b := _boss(false)
    for i in range(400):
        b.set("_last_pattern", -1)
        if int(b.call("_choose_pattern")) == 102:
            b.queue_free()
            return { "name": "blackout_phase2_only", "status": FAIL, "reason": "페이즈 1 인데 암전이 뽑힘" }
    b.queue_free()
    return { "name": "blackout_phase2_only", "status": PASS, "reason": "" }


func _check_hazards_spawn() -> Dictionary:
    var host := Node2D.new()
    add_child(host)
    var b: Node2D = load("res://scenes/enemies/GeuseondaeElder.tscn").instantiate()
    host.add_child(b)
    b.global_position = Vector2(700, GROUND_Y)
    b.set("_phase", 2)
    var stand_in := Node2D.new()
    stand_in.add_to_group("player")
    host.add_child(stand_in)
    stand_in.global_position = Vector2(420, GROUND_Y)
    await get_tree().process_frame

    for c in [["_do_shadow_pool", "ShadowPool", "그림자 늪"], ["_do_claw_sweep", "ShadowClaw", "갈퀴 훑기"]]:
        var before := _count(host, String(c[1]))
        b.call(String(c[0]))
        await get_tree().process_frame
        if _count(host, String(c[1])) <= before:
            host.queue_free()
            return { "name": "hazards_spawn", "status": FAIL, "reason": "%s: %s 미생성" % [c[2], c[1]] }
    host.queue_free()
    return { "name": "hazards_spawn", "status": PASS, "reason": "" }


func _check_claw_jumpable() -> Dictionary:
    if ShadowClaw.BODY_H > 60.0:
        return { "name": "claw_is_jumpable", "status": FAIL,
            "reason": "갈퀴 판정 높이 %.0fpx — 점프로 못 넘음" % ShadowClaw.BODY_H }
    return { "name": "claw_is_jumpable", "status": PASS, "reason": "높이 %.0fpx" % ShadowClaw.BODY_H }


func _check_pool_warns() -> Dictionary:
    var host := Node2D.new()
    add_child(host)
    var pool := ShadowPool.spawn(host, Vector2(400, GROUND_Y), 8.0, 0.35, 0.6)
    await get_tree().process_frame
    if pool == null:
        host.queue_free()
        return { "name": "pool_warn_then_active", "status": FAIL, "reason": "웅덩이 생성 실패" }
    var warn_off := not pool.monitoring
    await get_tree().create_timer(0.5).timeout
    var active: bool = is_instance_valid(pool) and pool.monitoring
    host.queue_free()
    if not warn_off:
        return { "name": "pool_warn_then_active", "status": FAIL, "reason": "예고 중에 이미 판정이 켜져 있음" }
    if not active:
        return { "name": "pool_warn_then_active", "status": FAIL, "reason": "예고 후에도 판정이 안 켜짐" }
    return { "name": "pool_warn_then_active", "status": PASS, "reason": "" }


# 늪이 사라진 뒤 감속이 남으면 그 판은 영영 느려진다 — 가장 위험한 회귀.
func _check_pool_releases_slow() -> Dictionary:
    var host := Node2D.new()
    add_child(host)
    var p: Node2D = load("res://scenes/player/Player.tscn").instantiate()
    host.add_child(p)
    p.global_position = Vector2(400, GROUND_Y - 40)
    var pool := ShadowPool.spawn(host, Vector2(400, GROUND_Y), 8.0, 0.2, 0.3)
    await get_tree().create_timer(0.35).timeout
    var slowed: float = float(p.get("move_speed_mult"))
    await get_tree().create_timer(1.0).timeout           # 늪 소멸 + 여유
    var restored: float = float(p.get("move_speed_mult"))
    host.queue_free()
    if not is_equal_approx(restored, 1.0):
        return { "name": "pool_releases_slow", "status": FAIL,
            "reason": "늪이 사라졌는데 이동 배율이 %.2f (1.0 기대)" % restored }
    return { "name": "pool_releases_slow", "status": PASS, "reason": "늪 안 %.2f → 해제 %.2f" % [slowed, restored] }


func _count(root: Node, cls: String) -> int:
    var n := 0
    for c in root.get_children():
        var s: Script = c.get_script()
        if s != null and s.get_global_name() == cls:
            n += 1
        n += _count(c, cls)
    return n
