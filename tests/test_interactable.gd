extends Node
##
## 조사 가능한 지형지물(Interactable) 헤드리스 테스트 — 2026-07-10 (#2 상호작용 시스템).
##   · 플레이어가 사거리에 들어오면 '△' 프롬프트가 보이고, 벗어나면 숨는지
##   · interact 발동 시 플래그가 서고, once 면 이후 프롬프트가 다시 안 뜨는지
##   · once_flag 가 이미 서 있으면 처음부터 사용됨(_used) 상태인지(세이브 연동)
##
## 렌더/키입력 없이 상태 전이만 검사하므로 헤드리스로 돈다.
##

const IT := preload("res://scripts/world/interactable.gd")


func _ready() -> void:
    print("=== test_interactable ===")
    var results: Array[Dictionary] = []
    results.append(_check_prompt_and_trigger())
    results.append(_check_once_flag_preused())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == "FAIL":
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _fake_player() -> Node2D:
    var p := Node2D.new()
    p.add_to_group("player")
    return p


func _make(flag: String, once: bool, once_flag: String = "") -> Interactable:
    var it := Area2D.new()
    it.set_script(IT)
    # 실제 stage 빌더처럼 프로퍼티를 먼저 세팅한 뒤 add_child(=_ready) — once_flag 를 _ready 가 읽는다.
    it.flag_on_use = flag
    it.once = once
    it.once_flag = once_flag
    it.dialogue_path = ""               # 대사 없이 플래그만 — 테스트에서 Dialogue 안 띄움
    add_child(it)                       # _ready → 프롬프트 생성 + once_flag 반영
    return it


func _prompt_visible(it: Node) -> bool:
    for c in it.get_children():
        if c is Label:
            return (c as Label).visible
    return false


func _check_prompt_and_trigger() -> Dictionary:
    Flags.set_flag("test_it_used", false)
    var it := _make("test_it_used", true)
    var player := _fake_player()
    if _prompt_visible(it):
        return _fail("interact_prompt", "사거리 밖인데 프롬프트가 보임")
    it._on_enter(player)
    if not _prompt_visible(it):
        return _fail("interact_prompt", "사거리 진입 후에도 프롬프트가 안 보임")
    it._trigger()
    if not Flags.has_flag("test_it_used"):
        return _fail("interact_prompt", "조사해도 플래그가 서지 않음")
    if _prompt_visible(it):
        return _fail("interact_prompt", "once 인데 조사 후에도 프롬프트가 남음")
    return _pass("interact_prompt")


func _check_once_flag_preused() -> Dictionary:
    Flags.set_flag("test_it_preused", true)     # 이미 조사한 적 있음(세이브)
    var it := _make("noop", true, "test_it_preused")
    var player := _fake_player()
    it._on_enter(player)
    if _prompt_visible(it):
        return _fail("interact_once_flag", "이미 사용한 지형지물인데 프롬프트가 다시 뜸")
    return _pass("interact_once_flag")


func _pass(name_: String) -> Dictionary:
    return {"status": "PASS", "name": name_, "reason": ""}


func _fail(name_: String, reason: String) -> Dictionary:
    return {"status": "FAIL", "name": name_, "reason": reason}
