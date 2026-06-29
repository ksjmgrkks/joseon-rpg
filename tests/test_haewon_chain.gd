extends Node
##
## 「해원」 스토리 체인 검증:
##  ① 7개 굽이 스테이지가 빌드되고(플레이어/배경) 전진 출구가 다음 굽이로 이어짐
##  ② 전투 굽이엔 적+결계(CombatGate) 가 있음
##  ③ 결계가 열리면(진혼 완료) MemoryLedger 가 그 굽이의 기억을 지움  ← 시그니처 배선
##  ④ 전투 없는 굽이(빈 고을)는 진입 직후 그 굽이 기억이 지워짐
##

const PASS := "PASS"
const FAIL := "FAIL"

# src → 기대 전진 타깃
const CHAIN := {
    "res://scenes/levels/Haewon0Prologue.tscn": "res://scenes/levels/Haewon1Ferry.tscn",
    "res://scenes/levels/Haewon1Ferry.tscn": "res://scenes/levels/Haewon2Market.tscn",
    "res://scenes/levels/Haewon2Market.tscn": "res://scenes/levels/Haewon3Village.tscn",
    "res://scenes/levels/Haewon3Village.tscn": "res://scenes/levels/Haewon4Watergate.tscn",
    "res://scenes/levels/Haewon4Watergate.tscn": "res://scenes/levels/Haewon5EmptyTown.tscn",
    "res://scenes/levels/Haewon5EmptyTown.tscn": "res://scenes/levels/Haewon6Yunseul.tscn",
    "res://scenes/levels/Haewon6Yunseul.tscn": "res://scenes/ui/Clear.tscn",
}


func _ready() -> void:
    print("=== test_haewon_chain ===")
    var results: Array = []
    for src in CHAIN:
        results.append(await _check_stage(src, CHAIN[src]))
    results.append(await _check_gate_erases_memory())
    results.append(await _check_no_combat_gut_erases())

    var passed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            print("  reason: %s" % r.reason)
        else:
            passed += 1
    print("=== %d/%d passed ===" % [passed, results.size()])
    get_tree().quit(0 if passed == results.size() else 1)


func _find(node: Node, cls: String) -> Array:
    var out: Array = []
    for c in node.get_children():
        if c.get_script() != null and (c as Object).get_script().get_global_name() == cls:
            out.append(c)
        out.append_array(_find(c, cls))
    return out


# 각 굽이: 빌드 + 전진 출구가 기대 타깃을 가리킴 + (적 있으면) 결계 존재.
func _check_stage(src: String, expect_target: String) -> Dictionary:
    Flags.clear()
    MemoryLedger.reset()
    var nm := src.get_file().get_basename()
    var s: Node = load(src).instantiate()
    add_child(s)
    await get_tree().process_frame
    await get_tree().process_frame
    var enemies := get_tree().get_nodes_in_group("enemy").size()
    var exits := _find(s, "LevelExit")
    var gates := _find(s, "CombatGate")
    var fwd_ok := false
    for e in exits:
        if String(e.target_scene) == expect_target:
            fwd_ok = true
    s.queue_free()
    await get_tree().process_frame
    if not fwd_ok:
        return {"name": nm, "status": FAIL, "reason": "전진 출구 target!=%s (exits=%d)" % [expect_target, exits.size()]}
    if enemies > 0 and gates.size() <= 0:
        return {"name": nm, "status": FAIL, "reason": "적은 있는데 결계 없음"}
    return {"name": nm, "status": PASS, "reason": ""}


# 결계가 열리면 그 굽이 기억이 지워진다(프롤로그 = gut 0 = 'a_face').
func _check_gate_erases_memory() -> Dictionary:
    Flags.clear()
    MemoryLedger.reset()
    var s: Node = load("res://scenes/levels/Haewon0Prologue.tscn").instantiate()
    add_child(s)
    await get_tree().process_frame
    await get_tree().process_frame
    var gates := _find(s, "CombatGate")
    if gates.is_empty():
        s.queue_free()
        return {"name": "gate_erases_memory", "status": FAIL, "reason": "결계 미생성"}
    if MemoryLedger.is_erased("a_face"):
        s.queue_free()
        return {"name": "gate_erases_memory", "status": FAIL, "reason": "결계 열기 전에 이미 소거됨"}
    gates[0].opened.emit()   # 진혼 완료 시뮬레이트(소거는 await 이전에 동기 실행)
    var ok := MemoryLedger.is_erased("a_face")
    s.queue_free()
    await get_tree().process_frame
    if not ok:
        return {"name": "gate_erases_memory", "status": FAIL, "reason": "결계 개방에도 a_face 미소거"}
    return {"name": "gate_erases_memory", "status": PASS, "reason": ""}


# 전투 없는 굽이(빈 고을 = gut 5)는 진입 직후 'almost_all' 이 지워진다(타이머 0.6s 후).
func _check_no_combat_gut_erases() -> Dictionary:
    Flags.clear()
    MemoryLedger.reset()
    var s: Node = load("res://scenes/levels/Haewon5EmptyTown.tscn").instantiate()
    add_child(s)
    await get_tree().process_frame
    var gates := _find(s, "CombatGate")
    await get_tree().create_timer(0.9).timeout
    var ok := MemoryLedger.is_erased("almost_all")
    var no_gate := gates.is_empty()
    s.queue_free()
    await get_tree().process_frame
    if not no_gate:
        return {"name": "no_combat_gut_erases", "status": FAIL, "reason": "빈 고을에 결계가 생김(적 없어야 함)"}
    if not ok:
        return {"name": "no_combat_gut_erases", "status": FAIL, "reason": "진입 후에도 almost_all 미소거"}
    return {"name": "no_combat_gut_erases", "status": PASS, "reason": ""}
