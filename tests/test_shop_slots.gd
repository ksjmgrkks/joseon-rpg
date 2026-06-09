extends Node
##
## E2) 슬롯 멀티 + D2) ShopManager 헤드리스 테스트.
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_shop_slots ===")
    var results: Array[Dictionary] = []
    _reset()
    results.append(_check_shop_buy_sell())
    _reset()
    results.append(_check_shop_no_gold())
    _reset()
    results.append(_check_slot_metadata())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _reset() -> void:
    Inventory.clear()
    if Equipment: Equipment.clear()
    PlayerStats.reset()
    for s in range(1, 4):
        SaveManager.delete_save(s)


func _check_shop_buy_sell() -> Dictionary:
    PlayerStats.add_gold(200)
    if not ShopManager.buy("potion_minor", 25):
        return _fail("shop_buy_sell", "buy failed with sufficient gold")
    if Inventory.count("potion_minor") != 1:
        return _fail("shop_buy_sell", "potion_minor not added")
    if PlayerStats.gold != 175:
        return _fail("shop_buy_sell", "gold not deducted (%d)" % PlayerStats.gold)
    # 판매(절반가 = 12)
    if not ShopManager.sell("potion_minor", 12):
        return _fail("shop_buy_sell", "sell failed")
    if Inventory.count("potion_minor") != 0:
        return _fail("shop_buy_sell", "potion not removed on sell")
    if PlayerStats.gold != 187:
        return _fail("shop_buy_sell", "gold not credited (%d)" % PlayerStats.gold)
    return _pass("shop_buy_sell")


func _check_shop_no_gold() -> Dictionary:
    PlayerStats.add_gold(10)
    if ShopManager.buy("armor_brigandine", 320):
        return _fail("shop_no_gold", "purchase succeeded despite insufficient gold")
    if Inventory.count("armor_brigandine") != 0:
        return _fail("shop_no_gold", "armor entered inventory after failed buy")
    if PlayerStats.gold != 10:
        return _fail("shop_no_gold", "gold deducted on failed buy (%d)" % PlayerStats.gold)
    return _pass("shop_no_gold")


func _check_slot_metadata() -> Dictionary:
    PlayerStats.gain_xp(180)   # 레벨 업
    PlayerStats.add_gold(42)
    SaveManager.save(2)
    var info := SaveManager.get_slot_info(2)
    SaveManager.delete_save(2)
    if info.is_empty():
        return _fail("slot_metadata", "get_slot_info empty")
    if int(info.get("level", 0)) < 2:
        return _fail("slot_metadata", "level mismatch (%d)" % int(info.get("level", 0)))
    if int(info.get("gold", 0)) != 42:
        return _fail("slot_metadata", "gold mismatch (%d)" % int(info.get("gold", 0)))
    if int(info.get("slot", -1)) != 2:
        return _fail("slot_metadata", "slot number mismatch")
    return _pass("slot_metadata")


func _pass(name: String) -> Dictionary:
    return { "name": name, "status": PASS, "reason": "" }


func _fail(name: String, reason: String) -> Dictionary:
    return { "name": name, "status": FAIL, "reason": reason }
