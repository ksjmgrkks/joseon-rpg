extends Node
##
## F — Pickup 아이템/골드/퀘스트 자동 진행 + ScreenFx headless 안전성 테스트.
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_pickup_fx ===")
    var results: Array[Dictionary] = []
    _reset()
    results.append(_check_pickup_item())
    _reset()
    results.append(_check_pickup_gold())
    _reset()
    results.append(_check_pickup_quest_gate())
    _reset()
    results.append(await _check_screenfx_no_camera())

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
    QuestManager.clear()
    Flags.clear()
    PlayerStats.reset()


# 일반 아이템 pickup → 인벤토리 +1
func _check_pickup_item() -> Dictionary:
    var player := _spawn_player()
    var pick := _spawn_pickup({
        "item_id": "rice_bun",
        "count": 2,
        "destroy_on_pickup": true,
    })
    pick._on_body_entered(player)
    if Inventory.count("rice_bun") != 2:
        player.queue_free()
        pick.queue_free()
        return _fail("pickup_item", "expected 2 rice_bun, got %d" % Inventory.count("rice_bun"))
    player.queue_free()
    return _pass("pickup_item")


# coin_pouch → gold 환산 (인벤토리에 안 들어감)
func _check_pickup_gold() -> Dictionary:
    var player := _spawn_player()
    var pick := _spawn_pickup({
        "item_id": "coin_pouch",
        "count": 2,            # 50 * 2 = 100
        "destroy_on_pickup": true,
    })
    pick._on_body_entered(player)
    if Inventory.count("coin_pouch") != 0:
        player.queue_free()
        pick.queue_free()
        return _fail("pickup_gold", "coin_pouch entered inventory")
    if PlayerStats.gold != 100:
        player.queue_free()
        pick.queue_free()
        return _fail("pickup_gold", "expected 100 gold, got %d" % PlayerStats.gold)
    player.queue_free()
    return _pass("pickup_gold")


# requires_quest_active 게이트: 퀘스트 비활성이면 아무것도 일어나지 않음
func _check_pickup_quest_gate() -> Dictionary:
    var player := _spawn_player()
    var pick := _spawn_pickup({
        "item_id": "charm_lost",
        "count": 1,
        "quest_id": "side_lost_charm",
        "quest_stage": "found",
        "requires_quest_active": "side_lost_charm",
        "destroy_on_pickup": true,
    })
    pick._on_body_entered(player)
    if Inventory.count("charm_lost") != 0:
        player.queue_free()
        pick.queue_free()
        return _fail("pickup_quest_gate", "charm picked up without active quest")
    # 퀘스트 활성화 후 두 번째 시도
    QuestManager.start_quest("side_lost_charm")
    var pick2 := _spawn_pickup({
        "item_id": "charm_lost",
        "count": 1,
        "quest_id": "side_lost_charm",
        "quest_stage": "found",
        "requires_quest_active": "side_lost_charm",
        "destroy_on_pickup": true,
    })
    pick2._on_body_entered(player)
    if Inventory.count("charm_lost") != 1:
        player.queue_free()
        pick.queue_free()
        pick2.queue_free()
        return _fail("pickup_quest_gate", "charm not received after activation")
    if not QuestManager.is_stage("side_lost_charm", "found"):
        player.queue_free()
        pick.queue_free()
        pick2.queue_free()
        return _fail("pickup_quest_gate", "stage didn't advance to found")
    player.queue_free()
    return _pass("pickup_quest_gate")


# 헤드리스(=카메라 없음) 에서 ScreenFx.shake/hit_stop 호출이 예외 없이 돌아야 함
func _check_screenfx_no_camera() -> Dictionary:
    ScreenFx.shake(8.0, 0.12)
    # hit_stop 은 Engine.time_scale 을 잠깐 만지므로 호출 직후 즉시 복원되도록 await 한 번
    ScreenFx.hit_stop(0.01)
    await get_tree().create_timer(0.05, true, false, true).timeout
    if abs(Engine.time_scale - 1.0) > 0.001:
        return _fail("screenfx_no_camera", "Engine.time_scale not restored (%.3f)" % Engine.time_scale)
    return _pass("screenfx_no_camera")


# === 헬퍼 ===

func _spawn_player() -> Node2D:
    var p := CharacterBody2D.new()
    p.add_to_group("player")
    p.global_position = Vector2.ZERO
    add_child(p)
    return p


func _spawn_pickup(props: Dictionary) -> Pickup:
    var p := Pickup.new()
    if props.has("item_id"): p.item_id = props.item_id
    if props.has("count"): p.count = props.count
    if props.has("quest_id"): p.quest_id = props.quest_id
    if props.has("quest_stage"): p.quest_stage = props.quest_stage
    if props.has("requires_quest_active"): p.requires_quest_active = props.requires_quest_active
    if props.has("destroy_on_pickup"): p.destroy_on_pickup = props.destroy_on_pickup
    add_child(p)
    return p


func _pass(name: String) -> Dictionary:
    return { "name": name, "status": PASS, "reason": "" }


func _fail(name: String, reason: String) -> Dictionary:
    return { "name": name, "status": FAIL, "reason": reason }
