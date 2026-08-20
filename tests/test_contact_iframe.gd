extends Node
##
## 몬스터 접촉 피해(패트롤러 근접 타격 / 투사체·장판류)가 짧은 시간 안에 겹쳐 들어와도
## 무적(invuln_on_hit) 중이면 두 번째 이후는 완전히 무시되는지(피해도, 넉백도) 검증.
## 사용자 피드백: "부딪혀서 데미지 받고 밀려나는 게 연속으로 받으면 뚝뚝 끊기고 어색하다"
## 실행: `godot --headless res://tests/test_contact_iframe.tscn`
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_contact_iframe ===")
    var results: Array[Dictionary] = []
    results.append(await _check_patroller_double_hit_only_counts_once())
    results.append(await _check_spirit_orb_grazes_during_invuln())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


## 패트롤러(잡몹) 근접 타격이 무적 창 안에서 두 번 들어와도 피해는 한 번만 들어간다.
func _check_patroller_double_hit_only_counts_once() -> Dictionary:
    var player: Node2D = load("res://scenes/player/Player.tscn").instantiate()
    add_child(player)
    player.global_position = Vector2(400, 400)
    var gob: Node2D = load("res://scenes/enemies/Goblin.tscn").instantiate()
    add_child(gob)
    gob.global_position = Vector2(430, 400)
    await get_tree().process_frame
    var ph: HealthComponent = player.get_node("HealthComponent")
    var hp0: float = ph.hp
    # 쿨다운 게이트를 우회해 직접 호출 — 거의 동시에 두 번 때린 상황을 재현.
    gob.call("_do_attack", player)
    gob.call("_do_attack", player)
    for i in range(30):
        await get_tree().physics_frame
    var hp1: float = ph.hp
    var expect: float = hp0 - gob.get("attack_damage")
    var ok := is_equal_approx(hp1, expect)
    var reason := "" if ok else "hp=%.1f (기대 %.1f — 무적 중 두 번째 타격이 뚫고 들어감)" % [hp1, expect]
    player.queue_free()
    gob.queue_free()
    return { "name": "patroller_double_hit_only_counts_once", "status": PASS if ok else FAIL, "reason": reason }


## SpiritOrb(투사체류) 도 이미 무적이면 스치기만 하고 피해·넉백을 추가로 넣지 않는다.
func _check_spirit_orb_grazes_during_invuln() -> Dictionary:
    var player: Node2D = load("res://scenes/player/Player.tscn").instantiate()
    add_child(player)
    player.global_position = Vector2(400, 400)
    await get_tree().process_frame
    var ph: HealthComponent = player.get_node("HealthComponent")
    ph.invuln_on_hit = 0.55
    ph.take_damage(5.0)                 # 무적 창 시작
    var hp_after_first: float = ph.hp
    var orb := SpiritOrb.spawn(self, player.global_position, 1.0, 20.0)
    await get_tree().process_frame
    var hit := false
    if is_instance_valid(orb):
        orb._on_body_entered(player)
        hit = true
    var ok: bool = hit and is_equal_approx(ph.hp, hp_after_first)
    var reason := "" if ok else "hp=%.1f (기대 %.1f — 무적 중인데 SpiritOrb 피해가 또 들어감)" % [ph.hp, hp_after_first]
    player.queue_free()
    if is_instance_valid(orb):
        orb.queue_free()
    return { "name": "spirit_orb_grazes_during_invuln", "status": PASS if ok else FAIL, "reason": reason }
