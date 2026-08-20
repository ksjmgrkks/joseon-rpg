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
    results.append(await _check_interact_prompt_range())
    results.append(await _check_interact_reveals())

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


func _prompt_visible(g: Node) -> bool:
    var lbl: Label = g._interact_prompt
    return lbl != null and lbl.visible


func _fake_player(pos: Vector2) -> Node2D:
    var p := Node2D.new()
    p.add_to_group("player")
    add_child(p)
    p.global_position = pos
    return p


## 위장 상태 + 조사 사거리 안일 때만 "!" 프롬프트가 뜬다(멀면 안 뜨고, 노출되면 사라짐).
func _check_interact_prompt_range() -> Dictionary:
    var g := _spawn()
    await get_tree().process_frame
    var far := _fake_player(g.global_position + Vector2(500, 0))
    g._physics_process(0.016)
    var hidden_far := not _prompt_visible(g)

    far.global_position = g.global_position + Vector2(g.interact_range * 0.5, 0)
    g._physics_process(0.016)
    var visible_near := _prompt_visible(g)

    var ok := hidden_far and visible_near
    var reason := "" if ok else "hidden_far=%s visible_near=%s" % [hidden_far, visible_near]
    far.queue_free()
    g.queue_free()
    return { "name": "interact_prompt_range", "status": PASS if ok else FAIL, "reason": reason }


## 조사 사거리 안에서 interact 를 누르면(스킬로 맞히지 않아도) 정체가 드러난다.
func _check_interact_reveals() -> Dictionary:
    var g := _spawn()
    await get_tree().process_frame
    var p := _fake_player(g.global_position + Vector2(20, 0))
    g._physics_process(0.016)
    if not g._in_interact_range:
        p.queue_free(); g.queue_free()
        return { "name": "interact_reveals", "status": FAIL, "reason": "테스트 셋업 실패 — 사거리 판정이 안 됨" }

    var ev := InputEventAction.new()
    ev.action = "interact"
    ev.pressed = true
    g._unhandled_input(ev)

    var ok: bool = (g._disguised == false) and not _prompt_visible(g)
    var reason := "" if ok else "disguised=%s prompt_visible=%s" % [g._disguised, _prompt_visible(g)]
    p.queue_free()
    g.queue_free()
    return { "name": "interact_reveals", "status": PASS if ok else FAIL, "reason": reason }
