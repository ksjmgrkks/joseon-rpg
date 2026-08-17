extends Node
##
## 엔딩 분기 검증 (헤드리스).
## 실행: `godot --headless res://tests/test_endings.tscn`
##
## 「해원」 v2 는 엔딩이 4종이고, 저울은 하나다 — '얼마나 자기를 태웠는가'(선택 진혼/단서 수)
## + 5막 태도 + 7막 마지막 선택. 조합을 잘못 엮으면 특정 엔딩에 영영 못 닿으므로 전수 검증한다.
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_endings ===")
    var results: Array[Dictionary] = []
    results.append(_check_table())
    results.append(_check_all_reachable())
    results.append(_check_presentation())
    results.append(_check_flag_path())

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


# (태운 수, 자기한 놓기, 이름 찾음, 회상 봄) → 기대 엔딩
func _check_table() -> Dictionary:
    var cases := [
        [4, true,  true,  true,  EndingResolver.SOMYEOL],   # 마지막 선택이 무엇보다 우선
        [0, true,  false, false, EndingResolver.SOMYEOL],
        [0, false, true,  true,  EndingResolver.YUNSEUL],   # 아끼고 + 이름 + 회상 = 숨김
        [1, false, true,  true,  EndingResolver.YUNSEUL],
        [2, false, true,  true,  EndingResolver.HAEWON],    # 너무 태우면 숨김 조건 탈락
        [0, false, false, true,  EndingResolver.HAEWON],    # 이름 못 찾으면 숨김 아님
        [3, false, true,  true,  EndingResolver.MANGGAK],   # 많이 태우면 알아보지 못한다
        [4, false, false, false, EndingResolver.MANGGAK],
        [2, false, false, false, EndingResolver.HAEWON],
    ]
    for c in cases:
        var got: String = EndingResolver.resolve_from(int(c[0]), bool(c[1]), bool(c[2]), bool(c[3]))
        if got != String(c[4]):
            return { "name": "resolve_table", "status": FAIL,
                "reason": "burned=%d release=%s name=%s recall=%s → %s (기대 %s)" % [c[0], str(c[1]), str(c[2]), str(c[3]), got, c[4]] }
    return { "name": "resolve_table", "status": PASS, "reason": "%d조합" % cases.size() }


# 네 엔딩 모두 실제로 도달 가능한 조합이 있는가 (죽은 엔딩 방지)
func _check_all_reachable() -> Dictionary:
    var seen := {}
    for burned in range(0, 5):
        for release in [false, true]:
            for name_found in [false, true]:
                for recall in [false, true]:
                    seen[EndingResolver.resolve_from(burned, release, name_found, recall)] = true
    for want in [EndingResolver.SOMYEOL, EndingResolver.YUNSEUL, EndingResolver.MANGGAK, EndingResolver.HAEWON]:
        if not seen.has(want):
            return { "name": "all_endings_reachable", "status": FAIL, "reason": "도달 불가 엔딩: %s" % want }
    return { "name": "all_endings_reachable", "status": PASS, "reason": "" }


# 엔딩마다 제목·본문이 채워져 있는가 (빈 화면 방지)
func _check_presentation() -> Dictionary:
    for id in [EndingResolver.SOMYEOL, EndingResolver.YUNSEUL, EndingResolver.MANGGAK, EndingResolver.HAEWON]:
        var p := EndingResolver.presentation(id)
        if String(p.get("title", "")) == "":
            return { "name": "presentation_filled", "status": FAIL, "reason": "%s: 제목 없음" % id }
        var lines: Array = p.get("lines", [])
        if lines.size() < 3:
            return { "name": "presentation_filled", "status": FAIL, "reason": "%s: 본문 %d줄(3줄 이상 기대)" % [id, lines.size()] }
        if int(p.get("lanterns", 0)) <= 0:
            return { "name": "presentation_filled", "status": FAIL, "reason": "%s: 등불 수 0" % id }
    return { "name": "presentation_filled", "status": PASS, "reason": "" }


# 실제 Flags 경로: 대사가 남기는 플래그로 판정이 굴러가는가
func _check_flag_path() -> Dictionary:
    Flags.clear()
    var base := EndingResolver.resolve()
    if base != EndingResolver.HAEWON:
        Flags.clear()
        return { "name": "flag_path", "status": FAIL, "reason": "아무 플래그 없을 때 %s (해원 기대)" % base }
    Flags.set_flag("haewon_final_release_self", true)
    var released := EndingResolver.resolve()
    Flags.clear()
    if released != EndingResolver.SOMYEOL:
        return { "name": "flag_path", "status": FAIL, "reason": "자기한 놓기 플래그인데 %s" % released }
    return { "name": "flag_path", "status": PASS, "reason": "" }
