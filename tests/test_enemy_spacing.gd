extends Node
##
## 적 간격 유지 + 어그로 검증 (2026-08-22 피드백 3건).
## 실행: `godot --headless res://tests/test_enemy_spacing.tscn`
##
##  ① 몬스터가 플레이어 몸에 파고들지 않고 일정 거리에서 선다
##     ("계속 바로 옆에 붙어 있어 버벅거린다")
##  ② 여럿이 붙어도 같은 좌표에 겹치지 않는다("뭉쳐 있을 때 특히")
##  ③ 시야 밖에서 맞으면 어그로가 걸려 쫓아온다("멀리서 부적만 던져도 됐다")
##

const PASS := "PASS"
const FAIL := "FAIL"
const MOB := "res://scenes/enemies/Dueoksini.tscn"


func _ready() -> void:
    print("=== test_enemy_spacing ===")
    var results: Array[Dictionary] = [
        _check_standoff_inside_reach(),
        _check_slots_differ(),
        await _check_aggro_on_ranged_hit(),
    ]
    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _chase_of(mob: Node) -> Node:
    return mob.get_node_or_null("StateMachine/Chase")


## 설 자리는 '자기 공격 사거리 안'이어야 한다 — 밖이면 영원히 못 때린다.
func _check_standoff_inside_reach() -> Dictionary:
    var bad: Array[String] = []
    for path in ["res://scenes/enemies/Dueoksini.tscn", "res://scenes/enemies/Wraith.tscn",
                 "res://scenes/enemies/Mulgwisin.tscn", "res://scenes/enemies/Changgwi.tscn"]:
        var mob: Node = load(path).instantiate()
        add_child(mob)
        var chase := _chase_of(mob)
        if chase == null:
            bad.append("%s: Chase 상태 없음" % path.get_file())
            mob.queue_free()
            continue
        chase.enter(mob)
        var reach: float = float(mob.attack_range)
        if chase._standoff > reach:
            bad.append("%s: standoff %.1f > 사거리 %.1f" % [path.get_file(), chase._standoff, reach])
        if chase._standoff < 20.0:
            bad.append("%s: standoff %.1f — 너무 붙는다" % [path.get_file(), chase._standoff])
        mob.queue_free()
    return {"name": "설자리가_사거리_안", "status": PASS if bad.is_empty() else FAIL, "reason": ", ".join(bad)}


## 같은 종류를 여럿 세워도 설 자리가 전부 같으면 한 점에 겹친다.
func _check_slots_differ() -> Dictionary:
    var seen: Array[float] = []
    var mobs: Array[Node] = []
    for i in range(6):
        var mob: Node = load(MOB).instantiate()
        add_child(mob)
        mobs.append(mob)
        var chase := _chase_of(mob)
        chase.enter(mob)
        seen.append(chase._standoff)
    for m in mobs:
        m.queue_free()
    var uniq := {}
    for v in seen:
        uniq[snappedf(v, 0.5)] = true
    var ok := uniq.size() >= 3
    return {"name": "여럿이면_설자리가_흩어짐", "status": PASS if ok else FAIL,
        "reason": "" if ok else "6기 중 서로 다른 자리 %d개뿐: %s" % [uniq.size(), seen]}


## 시야 밖이어도 맞으면 쫓아온다.
func _check_aggro_on_ranged_hit() -> Dictionary:
    var mob: Node = load(MOB).instantiate()
    add_child(mob)
    var player: Node2D = load("res://scenes/player/Player.tscn").instantiate()
    add_child(player)
    await get_tree().process_frame
    # 시야(detect_range)의 3배 밖에 세운다
    player.global_position = mob.global_position + Vector2(float(mob.detect_range) * 3.0, 0)
    var before: bool = mob.can_see_player()
    # 원거리 피격 — 투사체가 쓰는 것과 같은 경로
    Hurtbox.deal(mob, 5.0, 100.0, player)
    await get_tree().process_frame
    var after: bool = mob.can_see_player()
    var ok: bool = (not before) and after and bool(mob.aggro)
    var reason := "" if ok else "피격 전 시야=%s / 피격 후 시야=%s / aggro=%s" % [before, after, mob.aggro]
    mob.queue_free()
    player.queue_free()
    return {"name": "원거리_피격시_어그로", "status": PASS if ok else FAIL, "reason": reason}
