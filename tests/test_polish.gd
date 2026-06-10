extends Node
##
## 3차 폴리시(H/I/J/K) 헤드리스 테스트.
##   H — SceneManager 씬 전환 자동 저장: 슬롯 0 기록 + 비게임플레이 씬 제외 + 토글 off
##   I — QuestToast: 시작/완료 알림 표시, 단계 전이는 침묵
##   J — EnemyHpBar: 피격 전 숨김 → 피격 시 표시·비율 갱신 → 시간 경과 후 자동 숨김
##   K — NightOnly: 낮 숨김/밤 표시 + Area2D monitoring 동기 토글
##
## 자동 저장은 공개 진입점이 _do_change(씬 교체 — 테스트 씬 자체가 죽음)뿐이라
## 결정 로직인 _try_autosave 를 직접 호출해 검증한다.
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_polish ===")
    # 낮/밤 진행이 테스트 도중 흐르지 않게 고정
    TimeManager.set_paused(true)
    var results: Array[Dictionary] = []
    _reset()
    results.append(_check_autosave_writes_slot0())
    _reset()
    results.append(_check_autosave_skips_menu())
    _reset()
    results.append(_check_autosave_toggle_off())
    _reset()
    results.append(_check_toast_on_start())
    results.append(_check_toast_silent_on_stage())
    results.append(_check_toast_on_complete())
    _reset()
    results.append(_check_hpbar_show_hide())
    _reset()
    results.append(_check_night_only_day_init())
    results.append(_check_night_only_phase_toggle())
    results.append(_check_night_only_night_init())

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
    if Equipment: Equipment.clear()
    PlayerStats.reset()
    QuestManager.clear()
    QuestToast.clear_history()
    QuestToast.panel.visible = false
    SaveManager.delete_save(SceneManager.AUTOSAVE_SLOT)


# ---------------------------------------------------------------- H 자동 저장

func _check_autosave_writes_slot0() -> Dictionary:
    # 현재 씬 = 이 테스트 씬(TestRunner) — NON_GAMEPLAY_SCENES 아님 → 저장돼야 함
    PlayerStats.add_gold(77)
    SceneManager._try_autosave()
    if not SaveManager.has_save(SceneManager.AUTOSAVE_SLOT):
        return _fail("autosave_writes_slot0", "slot 0 not written from gameplay scene")
    var info := SaveManager.get_slot_info(SceneManager.AUTOSAVE_SLOT)
    if int(info.get("slot", -1)) != SceneManager.AUTOSAVE_SLOT:
        return _fail("autosave_writes_slot0", "slot number mismatch (%d)" % int(info.get("slot", -1)))
    if int(info.get("gold", -1)) != 77:
        return _fail("autosave_writes_slot0", "gold meta mismatch (%d)" % int(info.get("gold", -1)))
    return _pass("autosave_writes_slot0")


func _check_autosave_skips_menu() -> Dictionary:
    # 현재 씬 이름을 MainMenu 로 바꿔 비게임플레이 취급되는지 확인
    var original := String(name)
    name = "MainMenu"
    SceneManager._try_autosave()
    name = original
    if SaveManager.has_save(SceneManager.AUTOSAVE_SLOT):
        return _fail("autosave_skips_menu", "autosave fired from non-gameplay scene")
    return _pass("autosave_skips_menu")


func _check_autosave_toggle_off() -> Dictionary:
    SceneManager.autosave_on_scene_change = false
    SceneManager._try_autosave()
    SceneManager.autosave_on_scene_change = true
    if SaveManager.has_save(SceneManager.AUTOSAVE_SLOT):
        return _fail("autosave_toggle_off", "autosave fired while toggled off")
    return _pass("autosave_toggle_off")


# ---------------------------------------------------------------- I 퀘스트 토스트

func _check_toast_on_start() -> Dictionary:
    QuestManager.start_quest("main_tiger_lord")
    if not QuestToast.panel.visible:
        return _fail("toast_on_start", "panel hidden after quest start")
    if not QuestToast.label.text.begins_with("퀘스트 시작"):
        return _fail("toast_on_start", "unexpected label: %s" % QuestToast.label.text)
    return _pass("toast_on_start")


func _check_toast_silent_on_stage() -> Dictionary:
    # 시작 알림 이후 단계 전이는 조용해야 함
    QuestToast.panel.visible = false
    QuestManager.set_stage("main_tiger_lord", "to_forest")
    if QuestToast.panel.visible:
        return _fail("toast_silent_on_stage", "stage transition raised a toast")
    return _pass("toast_silent_on_stage")


func _check_toast_on_complete() -> Dictionary:
    QuestManager.complete_quest("main_tiger_lord")
    if not QuestToast.panel.visible:
        return _fail("toast_on_complete", "panel hidden after quest complete")
    if not QuestToast.label.text.begins_with("퀘스트 완료"):
        return _fail("toast_on_complete", "unexpected label: %s" % QuestToast.label.text)
    return _pass("toast_on_complete")


# ---------------------------------------------------------------- J 적 HP 바

func _check_hpbar_show_hide() -> Dictionary:
    var host := Node2D.new()
    var health := HealthComponent.new()
    health.max_hp = 40.0
    host.add_child(health)
    add_child(host)
    var bar := EnemyHpBar.attach_to(host, health)
    if bar.visible:
        host.queue_free()
        return _fail("hpbar_show_hide", "bar visible before any hit")
    health.take_damage(10.0)
    if not bar.visible:
        host.queue_free()
        return _fail("hpbar_show_hide", "bar hidden after hit")
    var expected := EnemyHpBar.BAR_WIDTH * (30.0 / 40.0)
    if absf(bar._bar.size.x - expected) > 0.01:
        host.queue_free()
        return _fail("hpbar_show_hide", "bar width %.2f != %.2f" % [bar._bar.size.x, expected])
    # SHOW_SECONDS 경과 시뮬레이트 — 엔진 프레임을 기다리는 대신 _process 직접 호출
    bar._process(EnemyHpBar.SHOW_SECONDS + 0.1)
    var still_visible := bar.visible
    host.queue_free()
    if still_visible:
        return _fail("hpbar_show_hide", "bar did not auto-hide after %.1fs" % EnemyHpBar.SHOW_SECONDS)
    return _pass("hpbar_show_hide")


# ---------------------------------------------------------------- K 밤 전용 노드

func _check_night_only_day_init() -> Dictionary:
    TimeManager.set_time(0.0)   # 낮
    var n := NightOnly.new()
    var area := Area2D.new()
    n.add_child(area)
    add_child(n)
    var ok := (not n.visible) and (not area.monitoring) and (not area.monitorable)
    n.queue_free()
    if not ok:
        return _fail("night_only_day_init", "visible=%s monitoring=%s during day" % [n.visible, area.monitoring])
    return _pass("night_only_day_init")


func _check_night_only_phase_toggle() -> Dictionary:
    TimeManager.set_time(0.0)
    var n := NightOnly.new()
    var area := Area2D.new()
    n.add_child(area)
    add_child(n)
    # 실제 게임에선 TimeManager._process 가 낮/밤 경계 통과 시 emit —
    # 테스트에선 페이즈 전이만 직접 시뮬레이트한다.
    TimeManager.phase_changed.emit(true)
    if not (n.visible and area.monitoring and area.monitorable):
        n.queue_free()
        return _fail("night_only_phase_toggle", "not activated on night phase")
    TimeManager.phase_changed.emit(false)
    var ok := (not n.visible) and (not area.monitoring)
    n.queue_free()
    if not ok:
        return _fail("night_only_phase_toggle", "not deactivated back on day phase")
    return _pass("night_only_phase_toggle")


func _check_night_only_night_init() -> Dictionary:
    TimeManager.set_time(0.95)   # 밤 (day_ratio=2/3 이후)
    var n := NightOnly.new()
    add_child(n)
    var ok := n.visible
    n.queue_free()
    TimeManager.set_time(0.0)
    if not ok:
        return _fail("night_only_night_init", "spawned hidden although night")
    return _pass("night_only_night_init")


func _pass(name_: String) -> Dictionary:
    return { "name": name_, "status": PASS, "reason": "" }


func _fail(name_: String, reason: String) -> Dictionary:
    return { "name": name_, "status": FAIL, "reason": reason }
