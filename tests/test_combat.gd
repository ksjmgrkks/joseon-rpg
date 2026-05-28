extends Node
##
## 헤드리스 전투 시스템 검증.
## 실행: `godot --headless res://tests/test_combat.tscn`
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_combat ===")
    var results: Array[Dictionary] = []
    results.append(await _check_take_damage())
    results.append(await _check_hurtbox_to_health_chain())
    results.append(await _check_death_signal())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


# HealthComponent 단독 단위 테스트
func _check_take_damage() -> Dictionary:
    var hc := HealthComponent.new()
    hc.max_hp = 50.0
    add_child(hc)
    await get_tree().process_frame
    hc.take_damage(15.0)
    if not is_equal_approx(hc.hp, 35.0):
        hc.queue_free()
        return { "name": "health_take_damage", "status": FAIL, "reason": "hp=%.1f, expected 35.0" % hc.hp }
    hc.take_damage(50.0)
    if not is_equal_approx(hc.hp, 0.0):
        hc.queue_free()
        return { "name": "health_take_damage", "status": FAIL, "reason": "hp=%.1f, expected 0.0" % hc.hp }
    hc.queue_free()
    return { "name": "health_take_damage", "status": PASS, "reason": "" }


# Hurtbox→hurt 시그널→HealthComponent 체인
func _check_hurtbox_to_health_chain() -> Dictionary:
    var root := Node2D.new()
    add_child(root)

    # Hurtbox 만들기
    var hurt := Hurtbox.new()
    var hurt_shape := CollisionShape2D.new()
    hurt_shape.shape = RectangleShape2D.new()
    (hurt_shape.shape as RectangleShape2D).size = Vector2(20, 20)
    hurt.add_child(hurt_shape)
    root.add_child(hurt)

    var hc := HealthComponent.new()
    hc.max_hp = 30.0
    hc.hurtbox_path = hurt.get_path()
    root.add_child(hc)
    await get_tree().process_frame

    # Hitbox 만들기 (attacker)
    var attacker := Node2D.new()
    add_child(attacker)
    var hit := Hitbox.new()
    hit.damage = 12.0
    var hit_shape := CollisionShape2D.new()
    hit_shape.shape = RectangleShape2D.new()
    (hit_shape.shape as RectangleShape2D).size = Vector2(16, 16)
    hit.add_child(hit_shape)
    attacker.add_child(hit)

    # 같은 위치에 두고 activate → 다음 물리 프레임에 area_entered
    hurt.global_position = Vector2.ZERO
    hit.global_position = Vector2.ZERO
    hit.activate(0.05)
    await get_tree().physics_frame
    await get_tree().physics_frame

    var ok := is_equal_approx(hc.hp, 18.0)
    var reason := "" if ok else "hp=%.1f, expected 18.0" % hc.hp
    root.queue_free()
    attacker.queue_free()
    return { "name": "hurtbox_health_chain", "status": PASS if ok else FAIL, "reason": reason }


# died 시그널
func _check_death_signal() -> Dictionary:
    var hc := HealthComponent.new()
    hc.max_hp = 10.0
    add_child(hc)
    await get_tree().process_frame
    var hit := { "v": false }
    hc.died.connect(func() -> void: hit.v = true)
    hc.take_damage(15.0)
    var ok := hit.v and is_equal_approx(hc.hp, 0.0)
    hc.queue_free()
    return { "name": "death_signal", "status": PASS if ok else FAIL, "reason": "" if ok else "died not emitted or hp wrong" }
