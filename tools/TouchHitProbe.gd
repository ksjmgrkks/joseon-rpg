extends Node
##
## 터치 판정 검사기 — **창을 띄워서** 실제 터치 이벤트를 각 버튼 가운데에 넣어보고
## 그 액션이 눌리는지 확인한다. (헤드리스에서는 TouchScreenButton 이 입력을 받지 않아
## 이 검사는 반드시 실제 DisplayServer 가 있는 창 모드로 돌려야 한다.)
##
## 사용:
##   godot --path . res://tools/TouchHitProbe.tscn
##   → 버튼별 OK/FAIL 을 출력하고, 하나라도 FAIL 이면 종료 코드 1.
##
## 이 도구가 잡아낸 회귀: shape_centered=false 로 두면 판정원이 텍스처 좌상단에 놓여
## 보이는 버튼을 눌러도 반응하지 않았다(폰에서 '버튼이 안 눌림').
##

func _ready() -> void:
    var controls: CanvasLayer = load("res://scenes/ui/MobileControls.tscn").instantiate()
    add_child(controls)
    controls.visible = true
    await get_tree().process_frame
    await get_tree().process_frame

    var failed := 0
    var total := 0
    for c in controls.get_children():
        if not (c is TouchScreenButton):
            continue
        var b := c as TouchScreenButton
        var r: float = float(b.get_meta("radius", 40.0))
        var center: Vector2 = b.position + Vector2(r, r)
        total += 1
        var ok_center := await _touch(String(b.action), center)
        # 버튼 밖(대각선으로 반지름의 2배 떨어진 점)은 눌리면 안 된다
        var ok_outside := not await _touch(String(b.action), center + Vector2(r * 2.2, -r * 2.2))
        if ok_center and ok_outside:
            print("[OK]   %-10s center=%s r=%.0f" % [b.action, str(center), r])
        else:
            failed += 1
            print("[FAIL] %-10s center=%s r=%.0f  (가운데 눌림=%s, 바깥 안눌림=%s)" % [
                b.action, str(center), r, str(ok_center), str(ok_outside)])
    print("=== %d/%d buttons OK ===" % [total - failed, total])
    get_tree().quit(0 if failed == 0 else 1)


# 한 점을 터치했다 떼고, 누르는 동안 액션이 눌렸는지 반환.
func _touch(action: String, pos: Vector2) -> bool:
    var down := InputEventScreenTouch.new()
    down.index = 0
    down.pressed = true
    down.position = pos
    get_viewport().push_input(down)
    await get_tree().process_frame
    var pressed := Input.is_action_pressed(action)
    var up := InputEventScreenTouch.new()
    up.index = 0
    up.pressed = false
    up.position = pos
    get_viewport().push_input(up)
    await get_tree().process_frame
    return pressed
