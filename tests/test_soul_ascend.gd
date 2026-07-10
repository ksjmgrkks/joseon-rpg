extends Node
##
## 성불(진혼) 사망 연출 헤드리스 테스트 — 2026-07-10 (#3).
##   · SkillFx.soul_ascend 가 host(=current_scene) 아래 연출 노드를 실제로 스폰하는지
##     (텍스처 유무와 무관하게 빛 알갱이 + 파문은 늘 뜬다 → 폴백도 성립)
##   · 스크립트 에러 없이 도는지(런타임 안전)
##
## 렌더 없이 노드 스폰만 검사하므로 헤드리스로 돈다. 실제 상승·색감·타이밍은 PC 눈 확인.
##


func _ready() -> void:
    print("=== test_soul_ascend ===")
    var results: Array[Dictionary] = []
    results.append(await _check_spawns())
    results.append(await _check_big_variant())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == "FAIL":
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _host_count() -> int:
    return get_tree().current_scene.get_child_count()


func _check_spawns() -> Dictionary:
    var before := _host_count()
    SkillFx.soul_ascend(Vector2(120, 120))
    await get_tree().process_frame
    var spawned := _host_count() - before
    if spawned <= 0:
        return _fail("soul_ascend_spawns", "연출 노드가 스폰되지 않음(delta=%d)" % spawned)
    return _pass("soul_ascend_spawns")


func _check_big_variant() -> Dictionary:
    # big=true(보스)도 에러 없이 더 많은/같은 알갱이를 스폰해야 한다.
    var before := _host_count()
    SkillFx.soul_ascend(Vector2(200, 120), true)
    await get_tree().process_frame
    var spawned := _host_count() - before
    if spawned <= 0:
        return _fail("soul_ascend_big", "big 변형이 노드를 스폰하지 않음")
    return _pass("soul_ascend_big")


func _pass(name_: String) -> Dictionary:
    return {"status": "PASS", "name": name_, "reason": ""}


func _fail(name_: String, reason: String) -> Dictionary:
    return {"status": "FAIL", "name": name_, "reason": reason}
