extends Node
##
## ScreenFit(가로 모드 안내) 검증 — 헤드리스.
## 실행: `godot --headless res://tests/test_screen_fit.tscn`
##
## 회귀 대상: "세로→가로로 되돌려도 '가로로 돌려 주십시오' 안내가 안 사라짐"
## (2026-08-20 사용자 리포트). size_changed 신호 하나만 믿지 않도록 디바운스
## 재검사 타이머 + 저빈도 폴링 타이머 + 탭-재검사 안전망을 넣었다 — 그 세 가지를 검증한다.
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_screen_fit ===")
    var results: Array[Dictionary] = []
    results.append(_check_landscape_hides_hint())
    results.append(_check_portrait_shows_hint_only_if_handheld())
    results.append(_check_timers_exist_and_configured())
    results.append(_check_resize_does_not_stack_timers())
    results.append(_check_tap_recheck_clears_stuck_hint())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _res(name: String, ok: bool, reason: String = "") -> Dictionary:
    return {"name": name, "status": PASS if ok else FAIL, "reason": reason}


func _check_landscape_hides_hint() -> Dictionary:
    ScreenFit._apply(Vector2(1600, 900), true)   # 넓은 화면 + 손안 기기라도
    var hidden: bool = not ScreenFit._hint_layer.visible
    return _res("가로 비율이면 손안기기여도 안내를 숨긴다", hidden,
        "hint visible=%s" % ScreenFit._hint_layer.visible)


func _check_portrait_shows_hint_only_if_handheld() -> Dictionary:
    ScreenFit._apply(Vector2(720, 1600), true)
    var shown_on_handheld: bool = ScreenFit._hint_layer.visible
    ScreenFit._apply(Vector2(720, 1600), false)
    var hidden_on_desktop: bool = not ScreenFit._hint_layer.visible
    var ok := shown_on_handheld and hidden_on_desktop
    return _res("세로면 손안기기에서만 안내를 띄운다(데스크톱은 무시)", ok,
        "handheld=%s desktop_hidden=%s" % [shown_on_handheld, hidden_on_desktop])


func _check_timers_exist_and_configured() -> Dictionary:
    var recheck_ok := ScreenFit._recheck_timer != null and ScreenFit._recheck_timer.one_shot \
        and is_equal_approx(ScreenFit._recheck_timer.wait_time, ScreenFit.RECHECK_DELAY)
    var poll_ok := ScreenFit._poll_timer != null and not ScreenFit._poll_timer.one_shot \
        and is_equal_approx(ScreenFit._poll_timer.wait_time, ScreenFit.POLL_INTERVAL) \
        and not ScreenFit._poll_timer.is_stopped()
    var ok := recheck_ok and poll_ok
    return _res("디바운스(1회성)·폴링(반복) 타이머가 올바르게 구성된다", ok,
        "recheck_ok=%s poll_ok=%s" % [recheck_ok, poll_ok])


func _check_resize_does_not_stack_timers() -> Dictionary:
    var before := ScreenFit.get_child_count()
    for i in 5:
        ScreenFit._on_resize()
    var after := ScreenFit.get_child_count()
    var ok := before == after
    return _res("size_changed 를 연달아 받아도 타이머가 쌓이지 않는다", ok,
        "child_count before=%d after=%d" % [before, after])


func _check_tap_recheck_clears_stuck_hint() -> Dictionary:
    # 실제 감지가 놓쳐서 안내가 세로 상태로 '박제'된 상황을 흉내낸다.
    ScreenFit._hint_layer.visible = true
    var fake := InputEventScreenTouch.new()
    fake.pressed = true
    ScreenFit._on_hint_input(fake)
    # 헤드리스 환경의 실제 창은 가로(1280x720 기본)+비-핸드헬드이므로
    # 재검사하면 반드시 꺼져야 한다 — 이게 바로 "탭하면 풀린다" 안전망의 핵심.
    var cleared: bool = not ScreenFit._hint_layer.visible
    return _res("안내를 탭하면 즉시 재검사해서 박제된 상태를 풀 수 있다", cleared,
        "hint visible after tap=%s" % ScreenFit._hint_layer.visible)
