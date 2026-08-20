extends Node
##
## 1스테이지 강가 물웅덩이 검증 (헤드리스).
## 실행: `godot --headless res://tests/test_water_zone.tscn`
##
## 사용자 피드백: "1스테이지 바닥은 강가인데 벽돌인 게 이상하다. 흙/풀/물이 섞이고
## 물을 밟으면 튀는 효과가 있으면 좋겠다." → ground.tileset 을 rock→earth 로 바꾸고,
## water_pools 구간(WaterZone)을 얹어 밟으면 SkillFx 물보라가 튀도록 했다(피해 없음).
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_water_zone ===")
    var results: Array[Dictionary] = []
    results.append(_check_foothills_ground_is_not_brick())
    results.append(_check_foothills_has_water_pools())
    results.append(await _check_water_zone_spawns_on_enter())
    results.append(await _check_water_zone_splashes_while_walking())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _check_foothills_ground_is_not_brick() -> Dictionary:
    var text := FileAccess.get_file_as_string("res://assets/stages/foothills.json")
    var data = JSON.parse_string(text)
    var tileset := String(data.get("ground", {}).get("tileset", ""))
    var ok := tileset != "rock"
    var reason := "" if ok else "1스테이지 지면이 여전히 rock(벽돌처럼 보임) 타일셋"
    return { "name": "foothills_ground_not_brick", "status": PASS if ok else FAIL, "reason": reason }


func _check_foothills_has_water_pools() -> Dictionary:
    var text := FileAccess.get_file_as_string("res://assets/stages/foothills.json")
    var data = JSON.parse_string(text)
    var pools: Array = data.get("water_pools", [])
    var ok := not pools.is_empty()
    var reason := "" if ok else "water_pools 가 비어 있음 — 강가에 물이 하나도 없음"
    return { "name": "foothills_has_water_pools", "status": PASS if ok else FAIL, "reason": reason }


func _make_player() -> Node2D:
    var p: Node2D = load("res://scenes/player/Player.tscn").instantiate()
    add_child(p)
    p.add_to_group("player")
    return p


## 플레이어가 실제로 밟고 설 수 있는 바닥(월드 레이어)을 깔아 is_on_floor() 를 진짜로 만든다.
func _make_floor(at_y: float) -> StaticBody2D:
    var body := StaticBody2D.new()
    body.collision_layer = 4
    body.position = Vector2(400.0, at_y)
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(800.0, 32.0)
    cs.shape = shape
    body.add_child(cs)
    add_child(body)
    return body


## 물웅덩이에 들어서는 순간 물이 튄다(모트 생성).
func _check_water_zone_spawns_on_enter() -> Dictionary:
    var host := Node2D.new()
    add_child(host)
    var zone := WaterZone.spawn(host, 400.0, 700.0, 200.0)
    if zone == null:
        host.queue_free()
        return { "name": "water_zone_spawns_on_enter", "status": FAIL, "reason": "WaterZone 생성 실패" }
    var player := _make_player()
    player.global_position = Vector2(400.0, 700.0)
    var before := host.get_child_count()
    zone._on_enter(player)
    await get_tree().process_frame
    var after := host.get_child_count()
    player.queue_free()
    host.queue_free()
    var ok := after > before
    var reason := "" if ok else "입장 시 물보라 모트가 생성되지 않음"
    return { "name": "water_zone_spawns_on_enter", "status": PASS if ok else FAIL, "reason": reason }


## 안에서 걷는 동안(속도 있음+접지) 주기적으로 물이 튄다 — 서 있기만 하면 안 튄다.
func _check_water_zone_splashes_while_walking() -> Dictionary:
    var host := Node2D.new()
    add_child(host)
    var floor_body := _make_floor(716.0)
    var zone := WaterZone.spawn(host, 400.0, 700.0, 200.0)
    var player := _make_player()
    player.global_position = Vector2(400.0, 690.0)
    # 실제 물리로 몇 프레임 낙하시켜 진짜 is_on_floor() 를 받는다(가짜로 세팅하지 않음).
    for i in range(20):
        await get_tree().physics_frame
    if not player.is_on_floor():
        player.queue_free(); floor_body.queue_free(); host.queue_free()
        return { "name": "water_zone_splashes_while_walking", "status": FAIL,
            "reason": "테스트 셋업 실패 — 플레이어가 바닥에 안 붙음" }
    zone._inside = player
    # 정지 상태 — 튀지 않아야 한다.
    player.velocity.x = 0.0
    var before_still := host.get_child_count()
    zone._physics_process(0.05)
    await get_tree().process_frame
    var after_still := host.get_child_count()
    # 걷는 상태(수평 속도 O)+접지 — 튀어야 한다.
    player.velocity.x = 120.0
    zone._step_cd = 0.0
    var before_walk := host.get_child_count()
    zone._physics_process(0.05)
    await get_tree().process_frame
    var after_walk := host.get_child_count()
    player.queue_free()
    floor_body.queue_free()
    host.queue_free()
    var still_ok := after_still == before_still
    var walk_ok := after_walk > before_walk
    var ok := still_ok and walk_ok
    var reason := ""
    if not still_ok:
        reason = "가만히 서 있는데도 물이 튐"
    elif not walk_ok:
        reason = "걷는 동안 물이 안 튐"
    return { "name": "water_zone_splashes_while_walking", "status": PASS if ok else FAIL, "reason": reason }
