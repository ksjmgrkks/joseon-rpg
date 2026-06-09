extends Node
##
## D — Equipment + 소지금 + TimeManager 헤드리스 테스트.
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_equipment ===")
    var results: Array[Dictionary] = []
    _reset()
    results.append(_check_equip_weapon())
    _reset()
    results.append(_check_armor_defense())
    _reset()
    results.append(_check_gold_spend())
    _reset()
    results.append(_check_save_load())
    _reset()
    results.append(_check_time_phase())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _reset() -> void:
    Equipment.clear()
    Inventory.clear()
    PlayerStats.reset()


func _check_equip_weapon() -> Dictionary:
    Inventory.add("sword_iron", 1)
    Inventory.add("sword_jade", 1)
    if not Equipment.equip("sword_iron"):
        return _fail("equip_weapon", "equip iron failed")
    if Equipment.weapon_id != "sword_iron":
        return _fail("equip_weapon", "weapon_id mismatch (%s)" % Equipment.weapon_id)
    # 무기를 갈아끼면 기존 검은 인벤토리로 되돌아가야 함
    Equipment.equip("sword_jade")
    if Equipment.weapon_id != "sword_jade":
        return _fail("equip_weapon", "switch to jade failed")
    if Inventory.count("sword_iron") != 1:
        return _fail("equip_weapon", "old weapon not returned to inventory")
    # current_damage(base) — base 가 무시되고 무기 정의값을 따라야 함
    var d := Equipment.current_damage(7.0)
    if int(d) != 18:
        return _fail("equip_weapon", "current_damage expected 18, got %d" % int(d))
    return _pass("equip_weapon")


func _check_armor_defense() -> Dictionary:
    Inventory.add("armor_brigandine", 1)
    Equipment.equip("armor_brigandine")
    if int(Equipment.current_defense()) != 14:
        return _fail("armor_defense", "current_defense expected 14")
    # 플레이어 그룹 노드 + HealthComponent 시나리오. (간단 시뮬)
    var player := CharacterBody2D.new()
    player.add_to_group("player")
    add_child(player)
    var hc := HealthComponent.new()
    hc.max_hp = 100.0
    player.add_child(hc)
    await get_tree().process_frame
    if hc.hp != 100.0:
        return _fail("armor_defense", "hp init wrong (%.1f)" % hc.hp)
    hc.take_damage(20.0)
    # 14 방어 → 6 만 들어가야 함
    if int(hc.hp) != 94:
        player.queue_free()
        return _fail("armor_defense", "expected 94 hp, got %.1f" % hc.hp)
    # 방어 > 데미지여도 1 은 들어감
    hc.hp = 100.0
    hc.take_damage(5.0)
    if int(hc.hp) != 99:
        player.queue_free()
        return _fail("armor_defense", "min 1 dmg rule broke (%.1f)" % hc.hp)
    player.queue_free()
    return _pass("armor_defense")


func _check_gold_spend() -> Dictionary:
    PlayerStats.add_gold(100)
    if PlayerStats.gold != 100:
        return _fail("gold_spend", "add_gold")
    if PlayerStats.spend_gold(120):
        return _fail("gold_spend", "overdraft allowed")
    if PlayerStats.gold != 100:
        return _fail("gold_spend", "balance changed on failed spend")
    if not PlayerStats.spend_gold(40):
        return _fail("gold_spend", "spend 40 failed")
    if PlayerStats.gold != 60:
        return _fail("gold_spend", "balance after spend wrong (%d)" % PlayerStats.gold)
    return _pass("gold_spend")


func _check_save_load() -> Dictionary:
    var SLOT := 95
    SaveManager.delete_save(SLOT)
    Inventory.add("sword_jade", 1)
    Equipment.equip("sword_jade")
    PlayerStats.add_gold(77)
    SaveManager.save(SLOT)
    Equipment.clear()
    PlayerStats.reset()
    SaveManager.load(SLOT)
    SaveManager.delete_save(SLOT)
    if Equipment.weapon_id != "sword_jade":
        return _fail("save_load", "weapon not restored")
    if PlayerStats.gold != 77:
        return _fail("save_load", "gold not restored (%d)" % PlayerStats.gold)
    return _pass("save_load")


func _check_time_phase() -> Dictionary:
    TimeManager.set_paused(true)
    TimeManager.set_time(0.0)
    if TimeManager.is_night():
        return _fail("time_phase", "expected day at t=0")
    var dr := TimeManager.day_ratio()
    TimeManager.set_time(dr + 0.05)
    if not TimeManager.is_night():
        return _fail("time_phase", "expected night just after day_ratio")
    # 일시정지 + 시간 강제 세팅은 phase_changed 가 발생하지 않을 수 있어 직접 검증.
    TimeManager.set_time(0.0)
    if TimeManager.is_night():
        return _fail("time_phase", "rolled back to day failed")
    return _pass("time_phase")


func _pass(name: String) -> Dictionary:
    return { "name": name, "status": PASS, "reason": "" }


func _fail(name: String, reason: String) -> Dictionary:
    return { "name": name, "status": FAIL, "reason": reason }
