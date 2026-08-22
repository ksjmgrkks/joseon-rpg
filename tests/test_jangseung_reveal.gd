extends Node
## 2스테이지 중간보스가 평범한 장승 위장 → 찾기 → 걷는 괴물 정체로 전환되는지 검증.

const PASS := "PASS"
const FAIL := "FAIL"
const SCENE := preload("res://scenes/enemies/Jangseung.tscn")


func _ready() -> void:
    print("=== test_jangseung_reveal ===")
    var results: Array[Dictionary] = [
        await _check_find_reveals_distinct_form(),
        await _check_talisman_also_reveals(),
    ]
    var failed := 0
    for result in results:
        print("[%s] %s" % [result.status, result.name])
        if result.status == FAIL:
            failed += 1
            print("  reason: %s" % result.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _check_find_reveals_distinct_form() -> Dictionary:
    var boss = SCENE.instantiate()
    add_child(boss)
    await get_tree().process_frame
    var before_ok: bool = boss._disguised \
        and boss.sprite.sheet == "enemies/jangseung_sealed" \
        and is_zero_approx(boss.attack_damage)
    var player := _fake_player(boss.global_position + Vector2(20, 0))
    boss._physics_process(0.016)
    var prompt_ok: bool = boss._interact_prompt.visible and boss._interact_prompt.text == "찾기"
    var event := InputEventAction.new()
    event.action = "interact"
    event.pressed = true
    boss._unhandled_input(event)
    var after_ok: bool = not boss._disguised \
        and boss.sprite.sheet == "enemies/jangseung_awakened" \
        and is_equal_approx(boss.attack_damage, boss.revealed_attack_damage) \
        and boss.health.shield_charges == 0 \
        and boss.sprite.scale.x > 1.0 \
        and (boss.get_node("Hurtbox/HurtboxShape").shape as RectangleShape2D).size.y >= 132.0
    var ok := before_ok and prompt_ok and after_ok
    var reason := "" if ok else "before=%s prompt=%s after=%s sheet=%s" % [
        before_ok, prompt_ok, after_ok, boss.sprite.sheet]
    player.queue_free()
    boss.queue_free()
    return {"name": "찾기_전후_장승_형태_분리", "status": PASS if ok else FAIL, "reason": reason}


func _check_talisman_also_reveals() -> Dictionary:
    var boss = SCENE.instantiate()
    add_child(boss)
    await get_tree().process_frame
    var accepted: bool = boss._on_talisman_hit(1.0, self)
    var hp_before: float = boss.health.hp
    var damaged: bool = boss._on_talisman_hit(7.0, self)
    var ok: bool = accepted and not boss._disguised \
        and boss.sprite.sheet == "enemies/jangseung_awakened" \
        and damaged and boss.health.hp < hp_before
    var reason := "" if ok else "accepted=%s disguised=%s sheet=%s damaged=%s hp=%.1f/%.1f" % [
        accepted, boss._disguised, boss.sprite.sheet, damaged, boss.health.hp, hp_before]
    boss.queue_free()
    return {"name": "부적불_대체_발견", "status": PASS if ok else FAIL, "reason": reason}


func _fake_player(pos: Vector2) -> Node2D:
    var player := Node2D.new()
    player.add_to_group("player")
    add_child(player)
    player.global_position = pos
    return player
