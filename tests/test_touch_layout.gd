extends Node
##
## 터치 버튼 위치 커스텀(드래그 편집) 검증 (헤드리스).
## 실행: `godot --headless res://tests/test_touch_layout.tscn`
##
## 1) TouchLayoutConfig 가 위치를 저장·복원하는가 (정규화 비율 round-trip)
## 2) MobileControls._layout() 이 커스텀 위치를 기본식보다 우선하는가
## 3) 초기화하면 기본 배치로 돌아가는가
## 4) 커스텀이 없는 액션은 기본식 그대로 유지되는가(다른 버튼에 영향 없음)
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_touch_layout ===")
    # 이 프로세스의 다른 테스트/실행에 영향받지 않도록 시작 전 초기화.
    TouchLayoutConfig.reset_all()

    var results: Array[Dictionary] = []
    results.append(await _check_roundtrip())
    results.append(await _check_override_applied())
    results.append(await _check_reset_restores_default())
    results.append(await _check_untouched_action_unaffected())

    TouchLayoutConfig.reset_all()   # 다른 테스트에 영향 주지 않도록 원복

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _spawn_controls() -> CanvasLayer:
    var mc: CanvasLayer = load("res://scenes/ui/MobileControls.tscn").instantiate()
    add_child(mc)
    await get_tree().process_frame
    return mc


func _find_button(mc: CanvasLayer, action: String) -> TouchScreenButton:
    for c in mc.get_children():
        if c is TouchScreenButton and (c as TouchScreenButton).action == action:
            return c as TouchScreenButton
    return null


func _check_roundtrip() -> Dictionary:
    TouchLayoutConfig.reset_all()
    var origin := Vector2(10, 20)
    var size := Vector2(1000, 600)
    var center := origin + size * Vector2(0.3, 0.7)
    TouchLayoutConfig.set_position("attack", center, origin, size)
    TouchLayoutConfig.commit()

    if not TouchLayoutConfig.has_custom("attack"):
        return { "name": "roundtrip_has_custom", "status": FAIL, "reason": "저장 후 has_custom=false" }

    var back := TouchLayoutConfig.get_position("attack", origin, size)
    if back.distance_to(center) > 1.0:
        return { "name": "roundtrip_has_custom", "status": FAIL,
            "reason": "저장 전 %s ≠ 복원 후 %s" % [str(center), str(back)] }
    return { "name": "roundtrip_has_custom", "status": PASS, "reason": "" }


func _check_override_applied() -> Dictionary:
    TouchLayoutConfig.reset_all()
    var mc := await _spawn_controls()
    var origin: Vector2 = mc.get("_layout_origin")
    var size: Vector2 = mc.get("_layout_size")
    mc.queue_free()

    # 화면 정중앙으로 커스텀 위치 지정 — 기본식 결과와는 확실히 다른 좌표.
    var custom_center: Vector2 = origin + size * 0.5
    TouchLayoutConfig.set_position("attack", custom_center, origin, size)
    TouchLayoutConfig.commit()

    var mc2 := await _spawn_controls()
    var btn := _find_button(mc2, "attack")
    if btn == null:
        mc2.queue_free()
        return { "name": "override_applied", "status": FAIL, "reason": "attack 버튼을 못 찾음" }
    var r: float = btn.get_meta("radius", 40.0)
    var actual_center: Vector2 = btn.position + Vector2(r, r)
    mc2.queue_free()

    if actual_center.distance_to(custom_center) > 2.0:
        return { "name": "override_applied", "status": FAIL,
            "reason": "커스텀 %s 인데 실제 %s (기본식이 우선 적용됨)" % [str(custom_center), str(actual_center)] }
    return { "name": "override_applied", "status": PASS, "reason": "" }


func _check_reset_restores_default() -> Dictionary:
    TouchLayoutConfig.reset_all()
    var mc_default := await _spawn_controls()
    var btn_default := _find_button(mc_default, "jump")
    var r0: float = btn_default.get_meta("radius", 40.0)
    var default_center: Vector2 = btn_default.position + Vector2(r0, r0)
    var origin: Vector2 = mc_default.get("_layout_origin")
    var size: Vector2 = mc_default.get("_layout_size")
    mc_default.queue_free()

    TouchLayoutConfig.set_position("jump", origin + size * 0.1, origin, size)
    TouchLayoutConfig.commit()
    TouchLayoutConfig.reset_all()

    var mc_after := await _spawn_controls()
    var btn_after := _find_button(mc_after, "jump")
    var r1: float = btn_after.get_meta("radius", 40.0)
    var after_center: Vector2 = btn_after.position + Vector2(r1, r1)
    mc_after.queue_free()

    if after_center.distance_to(default_center) > 1.0:
        return { "name": "reset_restores_default", "status": FAIL,
            "reason": "초기화 후 %s ≠ 원래 기본값 %s" % [str(after_center), str(default_center)] }
    return { "name": "reset_restores_default", "status": PASS, "reason": "" }


func _check_untouched_action_unaffected() -> Dictionary:
    TouchLayoutConfig.reset_all()
    var mc_default := await _spawn_controls()
    var btn_default := _find_button(mc_default, "dodge")
    var r0: float = btn_default.get_meta("radius", 40.0)
    var default_center: Vector2 = btn_default.position + Vector2(r0, r0)
    var origin: Vector2 = mc_default.get("_layout_origin")
    var size: Vector2 = mc_default.get("_layout_size")
    mc_default.queue_free()

    # 다른 액션(attack)만 커스텀 — dodge 는 손대지 않음.
    TouchLayoutConfig.set_position("attack", origin + size * 0.2, origin, size)
    TouchLayoutConfig.commit()

    var mc2 := await _spawn_controls()
    var btn2 := _find_button(mc2, "dodge")
    var r1: float = btn2.get_meta("radius", 40.0)
    var dodge_center: Vector2 = btn2.position + Vector2(r1, r1)
    mc2.queue_free()

    if dodge_center.distance_to(default_center) > 1.0:
        return { "name": "untouched_action_unaffected", "status": FAIL,
            "reason": "attack 만 바꿨는데 dodge 도 이동함: %s ≠ %s" % [str(dodge_center), str(default_center)] }
    return { "name": "untouched_action_unaffected", "status": PASS, "reason": "" }
