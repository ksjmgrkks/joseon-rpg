extends Node
##
## 그슨대(2스테이지 슬라이스) — 위장 상태 무적+성장, 부적 피격 시 정체 노출 검증.
## 실행: `godot --headless res://tests/test_geuseondae.tscn`
##

const PASS := "PASS"
const FAIL := "FAIL"
const GEUSEONDAE_SCENE := "res://scenes/enemies/Geuseondae.tscn"


func _ready() -> void:
    print("=== test_geuseondae ===")
    var results: Array[Dictionary] = []
    results.append(await _check_disguised_blocks_damage_and_grows())
    results.append(await _check_talisman_reveals())
    results.append(await _check_revealed_takes_real_damage())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _spawn() -> Node:
    var inst: Node = load(GEUSEONDAE_SCENE).instantiate()
    add_child(inst)
    return inst


## 위장 상태에서 근접(Hitbox→Hurtbox) 피격 — 데미지가 안 들어가고 대신 커진다(_threat 증가).
func _check_disguised_blocks_damage_and_grows() -> Dictionary:
    var g := _spawn()
    await get_tree().process_frame
    var hp_before: float = g.health.hp
    g.health._on_hurt(20.0, 100.0, self)   # HealthComponent 가 hurtbox.hurt 에서 받는 것과 동일 경로
    var ok: bool = is_equal_approx(g.health.hp, hp_before) and g._disguised == true and g._threat == 1
    var reason := "" if ok else "hp=%.1f(기대 %.1f) disguised=%s threat=%d" % [g.health.hp, hp_before, g._disguised, g._threat]
    g.queue_free()
    return { "name": "disguised_blocks_damage_and_grows", "status": PASS if ok else FAIL, "reason": reason }


## 위장 상태에서 여러 번 맞아도(칼) 절대 죽지 않는다 — shield_charges 가 매번 재충전됨.
func _check_talisman_reveals() -> Dictionary:
    var g := _spawn()
    await get_tree().process_frame
    for i in range(5):
        g.health._on_hurt(9999.0, 50.0, self)   # 아무리 세게 맞아도
    var still_alive_and_disguised: bool = g.health.hp > 0.0 and g._disguised == true
    g._on_talisman_hit(0.0, self)   # 부적(빛)에 맞음 — 정체 드러남
    var revealed: bool = g._disguised == false and g.health.shield_charges == 0
    var ok: bool = still_alive_and_disguised and revealed
    var reason := "" if ok else "alive_disguised=%s revealed=%s shield=%d" % [still_alive_and_disguised, g._disguised == false, g.health.shield_charges]
    g.queue_free()
    return { "name": "talisman_reveals_and_disguised_is_unkillable", "status": PASS if ok else FAIL, "reason": reason }


## 정체가 드러난 뒤엔 보통 적처럼 실제 데미지가 들어간다.
func _check_revealed_takes_real_damage() -> Dictionary:
    var g := _spawn()
    await get_tree().process_frame
    g._on_talisman_hit(0.0, self)
    var hp_before: float = g.health.hp
    g.health._on_hurt(20.0, 100.0, self)
    var ok := is_equal_approx(g.health.hp, hp_before - 20.0)
    var reason := "" if ok else "hp=%.1f, expected %.1f" % [g.health.hp, hp_before - 20.0]
    g.queue_free()
    return { "name": "revealed_takes_real_damage", "status": PASS if ok else FAIL, "reason": reason }
