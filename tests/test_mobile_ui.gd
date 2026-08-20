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
    results.append(_check_hit_geometry())
    results.append(_check_portrait_guard())
    results.append(_check_new_art_wired())

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


# 세로로 든 화면에서는 expand 를 끄고 레터박스로 — 하늘만 보이는 화면 방지.
func _check_portrait_guard() -> Dictionary:
    var win := get_window()
    var before := win.size
    win.size = Vector2i(720, 1280)          # 세로
    ScreenFit._apply()
    var portrait_mode := win.content_scale_aspect
    win.size = Vector2i(1560, 720)          # 가로 (19.5:9)
    ScreenFit._apply()
    var land_mode := win.content_scale_aspect
    win.size = before
    ScreenFit._apply()
    var ok := portrait_mode == Window.CONTENT_SCALE_ASPECT_KEEP \
        and land_mode == Window.CONTENT_SCALE_ASPECT_EXPAND
    var reason := "" if ok else "portrait=%d land=%d (기대 KEEP=%d / EXPAND=%d)" % [
        portrait_mode, land_mode, Window.CONTENT_SCALE_ASPECT_KEEP, Window.CONTENT_SCALE_ASPECT_EXPAND]
    return { "name": "portrait_guard", "status": PASS if ok else FAIL, "reason": reason }


# 보이는 버튼의 '가운데'를 실제로 터치했을 때 그 액션이 눌리는가.
# (TouchScreenButton.shape_centered 를 잘못 두면 판정원이 텍스처 좌상단으로 밀려
#  눈에 보이는 버튼을 눌러도 반응하지 않는다 — 폰에서 실제로 겪은 회귀.)
func _check_hit_geometry() -> Dictionary:
    # TouchScreenButton 의 판정원 위치는 shape_centered 가 결정한다:
    #   true  → 텍스처 **가운데** (우리가 원하는 것)
    #   false → 텍스처 **좌상단 꼭짓점** (보이는 버튼에서 반지름만큼 어긋남)
    # 이 의미는 tools/TouchHitProbe.tscn(창 모드)로 실제 터치를 넣어 확인했다.
    # 헤드리스에서는 TouchScreenButton 이 입력을 받지 않으므로 기하만 검사한다.
    for b in _btns():
        if not b.shape_centered:
            return { "name": "hit_geometry", "status": FAIL,
                "reason": "%s: shape_centered=false — 판정원이 텍스처 좌상단으로 밀린다" % b.action }
        if b.texture_normal == null:
            return { "name": "hit_geometry", "status": FAIL, "reason": "%s: 텍스처 없음" % b.action }
        var r := _radius(b)
        var tex_size := b.texture_normal.get_size()
        # 텍스처가 판정원 지름과 같아야 (텍스처 중심 = 판정원 중심 = 배치 좌표)
        if absf(tex_size.x - r * 2.0) > 2.0 or absf(tex_size.y - r * 2.0) > 2.0:
            return { "name": "hit_geometry", "status": FAIL,
                "reason": "%s: 텍스처 %s ≠ 판정 지름 %.0f (그림과 판정이 어긋남)" % [b.action, str(tex_size), r * 2.0] }
        if not b.passby_press:
            return { "name": "hit_geometry", "status": FAIL,
                "reason": "%s: passby_press 꺼짐 — 손가락을 끌면 안 눌린다" % b.action }
    return { "name": "hit_geometry", "status": PASS, "reason": "" }


## 신규 PixelLab 아트(assets/ui/mobile/btn_*.png)가 실제로 쓰이는지 — 코드로 그린
## 원(구 폴백)으로 조용히 되돌아가 있으면 못 알아채기 쉬워서 명시적으로 고정한다.
func _check_new_art_wired() -> Dictionary:
    var art_actions := ["move_left", "move_right", "interact", "attack", "jump", "dodge"]
    for a in art_actions:
        if not ResourceLoader.exists("res://assets/ui/mobile/btn_%s.png" % a):
            return { "name": "new_art_wired", "status": FAIL,
                "reason": "assets/ui/mobile/btn_%s.png 가 없음" % a }
    for b in _btns():
        if not art_actions.has(String(b.action)) and not String(b.action).begins_with("skill_"):
            continue
        if b.modulate != Color.WHITE:
            return { "name": "new_art_wired", "status": FAIL,
                "reason": "%s: 시작 modulate 가 흰색이 아님(눌림 틴트가 안 풀렸을 가능성)" % b.action }
    return { "name": "new_art_wired", "status": PASS, "reason": "" }
