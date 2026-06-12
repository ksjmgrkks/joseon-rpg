extends Node
##
## 스킬 시스템 헤드리스 테스트 — 해금(레벨/플래그)·쿨다운·호신부 보호막·키 리바인딩.
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_skills ===")
    var results: Array[Dictionary] = []
    _reset()
    results.append(_check_unlock_by_level())
    _reset()
    results.append(_check_unlock_by_flag())
    _reset()
    results.append(_check_cooldown_gate())
    _reset()
    results.append(_check_shield_blocks_once())
    _reset()
    results.append(_check_rebind_and_reset())
    _reset()

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _reset() -> void:
    PlayerStats.reset()
    Flags.clear()
    SkillManager.reset_cooldowns()


func _check_unlock_by_level() -> Dictionary:
    if SkillManager.is_unlocked("ilseom"):
        return _fail("unlock_by_level", "레벨 1인데 일섬이 풀려 있음")
    # 레벨 3 만들기
    while PlayerStats.level < 3:
        PlayerStats.gain_xp(200)
    if not SkillManager.is_unlocked("ilseom"):
        return _fail("unlock_by_level", "레벨 %d인데 일섬 잠김" % PlayerStats.level)
    if PlayerStats.level >= 5:
        return _fail("unlock_by_level", "테스트 전제 깨짐 (이미 레벨 5)")
    if SkillManager.is_unlocked("hoecheon"):
        return _fail("unlock_by_level", "레벨 5 미만인데 회천격이 풀려 있음")
    return _pass("unlock_by_level")


func _check_unlock_by_flag() -> Dictionary:
    if SkillManager.is_unlocked("hosinbu"):
        return _fail("unlock_by_flag", "플래그 없는데 호신부가 풀려 있음")
    Flags.set_flag("charm_blessing", true)
    if not SkillManager.is_unlocked("hosinbu"):
        return _fail("unlock_by_flag", "charm_blessing 셋인데 호신부 잠김")
    return _pass("unlock_by_flag")


func _check_cooldown_gate() -> Dictionary:
    while PlayerStats.level < 3:
        PlayerStats.gain_xp(200)
    if not SkillManager.try_cast("ilseom"):
        return _fail("cooldown_gate", "첫 발동 실패")
    if SkillManager.cooldown_left("ilseom") <= 0.0:
        return _fail("cooldown_gate", "발동 후 쿨다운이 0")
    if SkillManager.try_cast("ilseom"):
        return _fail("cooldown_gate", "쿨다운 중 재발동이 허용됨")
    SkillManager.reset_cooldowns()
    if not SkillManager.try_cast("ilseom"):
        return _fail("cooldown_gate", "쿨다운 초기화 후 발동 실패")
    return _pass("cooldown_gate")


func _check_shield_blocks_once() -> Dictionary:
    var hc := HealthComponent.new()
    hc.max_hp = 50.0
    add_child(hc)
    hc.shield_charges = 1
    var broke := { "v": false }
    hc.shield_broken.connect(func() -> void: broke.v = true)
    hc.take_damage(20.0)
    if not is_equal_approx(hc.hp, 50.0):
        hc.queue_free()
        return _fail("shield_blocks_once", "보호막이 있는데 피해 적용 (hp=%.0f)" % hc.hp)
    if not broke.v:
        hc.queue_free()
        return _fail("shield_blocks_once", "shield_broken 미발신")
    hc.take_damage(20.0)
    var ok := is_equal_approx(hc.hp, 30.0)
    hc.queue_free()
    if not ok:
        return _fail("shield_blocks_once", "두 번째 피해가 막힘 (hp=%.0f)" % hc.hp)
    return _pass("shield_blocks_once")


func _check_rebind_and_reset() -> Dictionary:
    # attack 의 기본 키 확인 후 F 키로 리바인딩 → 다시 기본 복원
    var ev := InputEventKey.new()
    ev.physical_keycode = KEY_F
    ev.pressed = true
    InputConfig.rebind("attack", ev)
    var txt := InputConfig.binding_text("attack")
    if not txt.contains("F"):
        return _fail("rebind_and_reset", "리바인딩 후 표기 이상: %s" % txt)
    var has_f := false
    for e in InputMap.action_get_events("attack"):
        if e is InputEventKey and (e as InputEventKey).physical_keycode == KEY_F:
            has_f = true
    if not has_f:
        return _fail("rebind_and_reset", "InputMap 에 F 미반영")
    InputConfig.reset_to_default()
    var txt2 := InputConfig.binding_text("attack")
    if not txt2.contains("X"):
        return _fail("rebind_and_reset", "기본값 복원 후 X 아님: %s" % txt2)
    return _pass("rebind_and_reset")


func _pass(name_: String) -> Dictionary:
    return { "name": name_, "status": PASS, "reason": "" }


func _fail(name_: String, reason: String) -> Dictionary:
    return { "name": name_, "status": FAIL, "reason": reason }
