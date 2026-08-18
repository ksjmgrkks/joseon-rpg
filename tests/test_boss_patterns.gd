extends Node
##
## 보스 공격 패턴 검증 (헤드리스).
## 실행: `godot --headless res://tests/test_boss_patterns.tscn`
##
## 돌진 하나뿐이던 보스를 5패턴으로 확장했다. 여기서 지키는 것:
##  ① 다섯 패턴이 모두 실제로 뽑히는가 (죽은 패턴 방지)
##  ② 같은 패턴이 연달아 나오지 않는가 (단조로움 방지)
##  ③ 소환은 페이즈 2 에서만 나오는가
##  ④ 물기둥은 **예고 동안 판정이 꺼져 있다가** 분출 때 켜지는가 (피할 시간 보장)
##  ⑤ 밀물의 판정이 낮아 **점프로 넘을 수 있는가** (수직 회피 강제)
##  ⑥ 각 패턴이 실제로 위험물을 만들어 내는가
##

const PASS := "PASS"
const FAIL := "FAIL"
const GROUND_Y := 600.0


func _ready() -> void:
    print("=== test_boss_patterns ===")
    var results: Array[Dictionary] = []
    results.append(_check_all_patterns_reachable())
    results.append(_check_no_immediate_repeat())
    results.append(_check_summon_phase2_only())
    results.append(await _check_pillar_warns_before_damage())
    results.append(_check_wave_is_jumpable())
    results.append(await _check_patterns_spawn_hazards())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _make_boss(phase2: bool = false) -> Node2D:
    var b: Node2D = load("res://scenes/enemies/FloodWraith.tscn").instantiate()
    add_child(b)
    b.global_position = Vector2(600, GROUND_Y)
    if phase2:
        b.set("_phase", 2)
    return b


func _check_all_patterns_reachable() -> Dictionary:
    var b := _make_boss(true)
    var seen := {}
    for i in range(400):
        b.set("_last_pattern", -1)         # 직전 제한 없이 순수 분포만 본다
        seen[int(b.call("_choose_pattern"))] = true
    b.queue_free()
    for p in range(5):                      # DASH..SUMMON
        if not seen.has(p):
            return { "name": "all_patterns_reachable", "status": FAIL, "reason": "패턴 %d 가 한 번도 안 뽑힘" % p }
    return { "name": "all_patterns_reachable", "status": PASS, "reason": "5종" }


func _check_no_immediate_repeat() -> Dictionary:
    var b := _make_boss(true)
    var last := -1
    for i in range(300):
        b.set("_last_pattern", last)
        var pick := int(b.call("_choose_pattern"))
        if pick == last:
            b.queue_free()
            return { "name": "no_immediate_repeat", "status": FAIL, "reason": "패턴 %d 가 연속으로 뽑힘" % pick }
        last = pick
    b.queue_free()
    return { "name": "no_immediate_repeat", "status": PASS, "reason": "" }


func _check_summon_phase2_only() -> Dictionary:
    var b := _make_boss(false)              # 페이즈 1
    for i in range(300):
        b.set("_last_pattern", -1)
        if int(b.call("_choose_pattern")) == 4:     # Pattern.SUMMON
            b.queue_free()
            return { "name": "summon_phase2_only", "status": FAIL, "reason": "페이즈 1 인데 소환이 뽑힘" }
    b.queue_free()
    return { "name": "summon_phase2_only", "status": PASS, "reason": "" }


func _check_pillar_warns_before_damage() -> Dictionary:
    var host := Node2D.new()
    add_child(host)
    var pillar := WaterPillar.spawn(host, Vector2(400, GROUND_Y), 14.0, 0.4, 0.3)
    await get_tree().process_frame
    if pillar == null:
        host.queue_free()
        return { "name": "pillar_warn_then_erupt", "status": FAIL, "reason": "물기둥 생성 실패" }
    var warn_off := not pillar.monitoring          # 예고 동안 판정 꺼짐
    await get_tree().create_timer(0.55).timeout    # 예고(0.4) 지난 직후
    var erupt_on: bool = is_instance_valid(pillar) and pillar.monitoring
    host.queue_free()
    if not warn_off:
        return { "name": "pillar_warn_then_erupt", "status": FAIL, "reason": "예고 중에 이미 판정이 켜져 있음(피할 수 없음)" }
    if not erupt_on:
        return { "name": "pillar_warn_then_erupt", "status": FAIL, "reason": "분출 시점에 판정이 안 켜짐" }
    return { "name": "pillar_warn_then_erupt", "status": PASS, "reason": "" }


func _check_wave_is_jumpable() -> Dictionary:
    var host := Node2D.new()
    add_child(host)
    var wave := TideWave.spawn(host, Vector2(300, GROUND_Y), 1.0, 12.0)
    if wave == null:
        host.queue_free()
        return { "name": "wave_is_jumpable", "status": FAIL, "reason": "밀물 생성 실패" }
    # 판정 사각형의 윗변이 지면에서 충분히 낮아야 점프로 넘을 수 있다.
    var top_above_ground := TideWave.BODY_H
    host.queue_free()
    if top_above_ground > 60.0:
        return { "name": "wave_is_jumpable", "status": FAIL,
            "reason": "밀물 판정 높이 %.0fpx — 점프(약 96px)로 못 넘음" % top_above_ground }
    return { "name": "wave_is_jumpable", "status": PASS, "reason": "높이 %.0fpx" % top_above_ground }


# 각 패턴이 실제로 위험물(투사체·기둥·물결·잡귀)을 만들어 내는가
func _check_patterns_spawn_hazards() -> Dictionary:
    var host := Node2D.new()
    add_child(host)
    var b: Node2D = load("res://scenes/enemies/FloodWraith.tscn").instantiate()
    host.add_child(b)
    b.global_position = Vector2(600, GROUND_Y)
    b.set("_phase", 2)
    # 물기둥은 플레이어 발밑을 노리므로 대역 플레이어가 필요하다.
    var stand_in := Node2D.new()
    stand_in.add_to_group("player")
    host.add_child(stand_in)
    stand_in.global_position = Vector2(400, GROUND_Y)
    await get_tree().process_frame

    var cases := [
        ["_do_volley", "SpiritOrb", "부적 세례"],
        ["_do_pillars", "WaterPillar", "물기둥"],
        ["_do_wave", "TideWave", "밀물"],
    ]
    for c in cases:
        var before := _count_of(host, String(c[1]))
        b.call(String(c[0]))
        await get_tree().process_frame
        var after := _count_of(host, String(c[1]))
        if after <= before:
            host.queue_free()
            return { "name": "patterns_spawn_hazards", "status": FAIL,
                "reason": "%s: %s 가 생성되지 않음" % [c[2], c[1]] }
    # 소환 — 잡귀가 늘어나야 한다
    var minions_before := get_tree().get_nodes_in_group("enemy").size()
    b.call("_do_summon")
    await get_tree().process_frame
    var minions_after := get_tree().get_nodes_in_group("enemy").size()
    host.queue_free()
    if minions_after <= minions_before:
        return { "name": "patterns_spawn_hazards", "status": FAIL, "reason": "소환: 잡귀가 안 늘어남" }
    return { "name": "patterns_spawn_hazards", "status": PASS, "reason": "4패턴" }


func _count_of(root: Node, cls: String) -> int:
    var n := 0
    for c in root.get_children():
        var s: Script = c.get_script()
        if s != null and s.get_global_name() == cls:
            n += 1
        n += _count_of(c, cls)
    return n
