extends Node
##
## 모바일 터치 UI 검증 (헤드리스).
## 실행: `godot --headless res://tests/test_mobile_ui.tscn`
##
## 1) 필요한 액션 버튼이 모두 있는가 (스킬 4개 포함 — 예전엔 궁극기 버튼이 없었다)
## 2) 모든 버튼이 화면 안에 있는가 (잘려서 못 누르는 버튼 방지)
## 3) 버튼끼리 겹치지 않는가 (오폭 방지)
## 4) 손가락에 맞는 크기인가 (지름 64px 이상)
## 5) 진동 설정이 파일에 남는가
##

const PASS := "PASS"
const FAIL := "FAIL"
const REQUIRED := ["move_left", "move_right", "jump", "attack", "dodge", "interact",
    "skill_1", "skill_2", "skill_3", "skill_4"]

var _controls: CanvasLayer = null


func _ready() -> void:
    print("=== test_mobile_ui ===")
    _controls = load("res://scenes/ui/MobileControls.tscn").instantiate()
    add_child(_controls)
    await get_tree().process_frame

    var results: Array[Dictionary] = []
    results.append(_check_actions())
    results.append(_check_inside_viewport())
    results.append(_check_no_overlap())
    results.append(_check_touch_size())
    results.append(_check_haptics_persist())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _btns() -> Array[TouchScreenButton]:
    var out: Array[TouchScreenButton] = []
    for c in _controls.get_children():
        if c is TouchScreenButton:
            out.append(c as TouchScreenButton)
    return out


func _radius(b: TouchScreenButton) -> float:
    return float(b.get_meta("radius", 40.0))


func _center(b: TouchScreenButton) -> Vector2:
    return b.position + Vector2(_radius(b), _radius(b))


func _check_actions() -> Dictionary:
    var have: Array[String] = []
    for b in _btns():
        have.append(String(b.action))
    var missing: Array[String] = []
    for a in REQUIRED:
        if not have.has(a):
            missing.append(a)
    if not missing.is_empty():
        return { "name": "all_actions_present", "status": FAIL, "reason": "없는 버튼: %s" % str(missing) }
    return { "name": "all_actions_present", "status": PASS, "reason": "" }


func _check_inside_viewport() -> Dictionary:
    var vp := get_viewport().get_visible_rect().size
    for b in _btns():
        var c := _center(b)
        var r := _radius(b)
        if c.x - r < 0.0 or c.y - r < 0.0 or c.x + r > vp.x or c.y + r > vp.y:
            return { "name": "buttons_inside_viewport", "status": FAIL,
                "reason": "%s 가 화면 밖 (center=%s r=%.0f vp=%s)" % [b.action, str(c), r, str(vp)] }
    return { "name": "buttons_inside_viewport", "status": PASS, "reason": "" }


func _check_no_overlap() -> Dictionary:
    var list := _btns()
    for i in range(list.size()):
        for j in range(i + 1, list.size()):
            var a := list[i]
            var b := list[j]
            var gap := _center(a).distance_to(_center(b)) - (_radius(a) + _radius(b))
            if gap < 0.0:
                return { "name": "no_overlap", "status": FAIL,
                    "reason": "%s ↔ %s 가 %.0fpx 겹침" % [a.action, b.action, -gap] }
    return { "name": "no_overlap", "status": PASS, "reason": "" }


func _check_touch_size() -> Dictionary:
    for b in _btns():
        if _radius(b) < 32.0:
            return { "name": "touch_target_size", "status": FAIL,
                "reason": "%s 지름 %.0fpx (64px 미만 — 손가락에 작음)" % [b.action, _radius(b) * 2.0] }
    return { "name": "touch_target_size", "status": PASS, "reason": "" }


func _check_haptics_persist() -> Dictionary:
    var before := ScreenFx.haptics_enabled
    ScreenFx.set_haptics(false)
    var cfg := ConfigFile.new()
    var err := cfg.load(ScreenFx.SETTINGS_PATH)
    var saved = cfg.get_value("feel", "haptics", true) if err == OK else null
    ScreenFx.set_haptics(before)
    if err != OK:
        return { "name": "haptics_persist", "status": FAIL, "reason": "settings.cfg 저장 안 됨 (err=%d)" % err }
    if saved != false:
        return { "name": "haptics_persist", "status": FAIL, "reason": "저장값=%s (기대 false)" % str(saved) }
    return { "name": "haptics_persist", "status": PASS, "reason": "" }
