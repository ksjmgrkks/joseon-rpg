extends Node
##
## 시야(카메라 배율) 설정 검증.
## 실행: `godot --headless res://tests/test_view_config.tscn`
##
## 지키려는 계약 두 가지:
##  ① 배율은 PRESETS 범위를 벗어나지 않는다(잘못된 저장값이 들어와도).
##  ② **화면에서 본 지면선 위치가 배율과 무관하게 같다** — Camera2D.offset 은 월드 단위라
##     확대하면 그만큼 더 밀린다. 배율로 나눠 보정하지 않으면 확대할수록 하늘만 보인다
##     (2026-08-22 실제로 겪고 고친 것).
##

const PASS := "PASS"
const FAIL := "FAIL"
const BASE_OFFSET := Vector2(0, -160.0)   # stage.gd 의 CAMERA_OFFSET_Y


func _ready() -> void:
    print("=== test_view_config ===")
    var results: Array[Dictionary] = [
        _check_clamp(),
        _check_presets_apply(),
        await _check_ground_line_stable(),
    ]
    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _check_clamp() -> Dictionary:
    var before := ViewConfig.zoom
    ViewConfig.set_zoom(99.0)
    var hi := ViewConfig.zoom
    ViewConfig.set_zoom(0.01)
    var lo := ViewConfig.zoom
    ViewConfig.set_zoom(before)
    var max_p: float = ViewConfig.PRESETS[ViewConfig.PRESETS.size() - 1]
    var min_p: float = ViewConfig.PRESETS[0]
    var ok := is_equal_approx(hi, max_p) and is_equal_approx(lo, min_p)
    return {"name": "배율_범위_고정", "status": PASS if ok else FAIL,
        "reason": "" if ok else "99→%.2f(기대 %.2f) / 0.01→%.2f(기대 %.2f)" % [hi, max_p, lo, min_p]}


func _check_presets_apply() -> Dictionary:
    var before := ViewConfig.zoom
    var bad: Array[String] = []
    for i in range(ViewConfig.PRESETS.size()):
        ViewConfig.set_preset(i)
        if not is_equal_approx(ViewConfig.zoom, float(ViewConfig.PRESETS[i])):
            bad.append("%d번 프리셋 → %.2f" % [i, ViewConfig.zoom])
        if ViewConfig.preset_index() != i:
            bad.append("%d번 프리셋의 역조회가 %d" % [i, ViewConfig.preset_index()])
    ViewConfig.set_zoom(before)
    return {"name": "프리셋_왕복", "status": PASS if bad.is_empty() else FAIL, "reason": ", ".join(bad)}


## 배율을 바꿔도 '화면에서의 카메라 오프셋'(offset × zoom)이 그대로여야 한다.
func _check_ground_line_stable() -> Dictionary:
    var cam := Camera2D.new()
    cam.set_meta("base_offset", BASE_OFFSET)
    cam.add_to_group("player_cam")
    add_child(cam)
    cam.make_current()
    await get_tree().process_frame

    var before := ViewConfig.zoom
    var seen: Array[float] = []
    for z in ViewConfig.PRESETS:
        ViewConfig.set_zoom(float(z))
        ViewConfig.apply_to_current()
        seen.append(cam.offset.y * cam.zoom.y)      # 화면에서 밀리는 픽셀 수
    ViewConfig.set_zoom(before)
    cam.queue_free()

    var bad: Array[String] = []
    for i in range(seen.size()):
        if not is_equal_approx(seen[i], BASE_OFFSET.y):
            bad.append("배율 %.2f 에서 화면 오프셋 %.1f (기대 %.1f)" % [
                ViewConfig.PRESETS[i], seen[i], BASE_OFFSET.y])
    return {"name": "지면선_배율과_무관", "status": PASS if bad.is_empty() else FAIL,
        "reason": ", ".join(bad)}
