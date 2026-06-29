extends Node
##
## MemoryLedger(상태/세이브) + MemoryGlyph(순수 글자 변환) 헤드리스 테스트.
## 「해원」 시그니처 '기억이 지워짐'의 로직 검증 — 비주얼(글자 페이드)은 PC 확인 영역.
##

const PASS := "PASS"
const FAIL := "FAIL"


func _ready() -> void:
    print("=== test_memory_ledger ===")
    var results: Array[Dictionary] = []
    results.append(_check_erase_and_progress())
    results.append(_check_gut_erase())
    results.append(_check_name_and_screen_names())
    results.append(_check_last_name_signal())
    results.append(_check_save_load())
    results.append(_check_glyph_bounds())
    results.append(_check_glyph_monotonic())
    results.append(_check_glyph_spaces_and_determinism())
    MemoryLedger.reset()

    var failed := 0
    for r in results:
        print("[%s] %s" % [r.status, r.name])
        if r.status == FAIL:
            failed += 1
            print("  reason: %s" % r.reason)
    print("=== %d/%d passed ===" % [results.size() - failed, results.size()])
    get_tree().quit(0 if failed == 0 else 1)


func _ok(n: String) -> Dictionary: return {"name": n, "status": PASS, "reason": ""}
func _no(n: String, why: String) -> Dictionary: return {"name": n, "status": FAIL, "reason": why}


func _check_erase_and_progress() -> Dictionary:
    MemoryLedger.reset()
    if MemoryLedger.erased_count() != 0 or MemoryLedger.progress() != 0.0:
        return _no("erase_progress", "reset 후에도 소거 상태가 남음")
    if not MemoryLedger.erase("a_face"):
        return _no("erase_progress", "첫 소거가 false 반환")
    if MemoryLedger.erase("a_face"):
        return _no("erase_progress", "중복 소거가 true 반환(멱등 아님)")
    if not MemoryLedger.is_erased("a_face"):
        return _no("erase_progress", "is_erased 가 소거를 반영 못함")
    var expected := 1.0 / float(MemoryLedger.total())
    if abs(MemoryLedger.progress() - expected) > 0.0001:
        return _no("erase_progress", "progress %f != %f" % [MemoryLedger.progress(), expected])
    if MemoryLedger.erase("nonexistent_id"):
        return _no("erase_progress", "없는 조각 소거가 true 반환")
    return _ok("erase_progress")


func _check_gut_erase() -> Dictionary:
    MemoryLedger.reset()
    var n := MemoryLedger.erase_for_gut(0)   # 프롤로그: a_face 하나
    if n != 1 or not MemoryLedger.is_erased("a_face"):
        return _no("gut_erase", "굽이0 소거 수 %d (expect 1)" % n)
    # next_fragment 는 아직 온전한 가장 이른 굽이 조각이어야
    var nf := MemoryLedger.next_fragment()
    if String(nf.get("id", "")) != "watergate_keeper":
        return _no("gut_erase", "next_fragment %s (expect watergate_keeper)" % nf)
    if MemoryLedger.erase_for_gut(0) != 0:
        return _no("gut_erase", "이미 소거된 굽이 재호출이 0 아님")
    return _ok("gut_erase")


func _check_name_and_screen_names() -> Dictionary:
    MemoryLedger.reset()
    if not MemoryLedger.name_intact():
        return _no("screen_names", "초기에 본명이 이미 소거됨")
    var s0 := MemoryLedger.screen_names()
    if s0.size() != 2 or not s0.has("길손") or not s0.has("윤슬"):
        return _no("screen_names", "초기 screen_names %s" % [s0])
    # 3굽이 true_name 소거 → name_intact false, '길손' 표기로만
    MemoryLedger.erase("true_name")
    if MemoryLedger.name_intact():
        return _no("screen_names", "true_name 소거 후에도 name_intact true")
    # 5굽이 almost_all → '윤슬' 하나만
    MemoryLedger.erase("almost_all")
    var s1 := MemoryLedger.screen_names()
    if s1.size() != 1 or s1[0] != "윤슬":
        return _no("screen_names", "almost_all 후 %s (expect [윤슬])" % [s1])
    # 6굽이 yunseul → 빈 화면
    MemoryLedger.erase("yunseul")
    if MemoryLedger.screen_names().size() != 0:
        return _no("screen_names", "yunseul 소거 후에도 이름이 남음")
    return _ok("screen_names")


func _check_last_name_signal() -> Dictionary:
    MemoryLedger.reset()
    var fired := {"v": false}
    var cb := func(): fired.v = true
    MemoryLedger.last_name_released.connect(cb)
    MemoryLedger.erase("a_face")
    if fired.v:
        MemoryLedger.last_name_released.disconnect(cb)
        return _no("last_name_signal", "엉뚱한 조각 소거에 신호 발화")
    MemoryLedger.erase("yunseul")
    MemoryLedger.last_name_released.disconnect(cb)
    if not fired.v:
        return _no("last_name_signal", "yunseul 소거에 last_name_released 미발화")
    return _ok("last_name_signal")


func _check_save_load() -> Dictionary:
    var SLOT := 96
    SaveManager.delete_save(SLOT)
    MemoryLedger.reset()
    MemoryLedger.erase_for_gut(0)
    MemoryLedger.erase("true_name")
    SaveManager.save(SLOT)
    MemoryLedger.reset()
    if MemoryLedger.erased_count() != 0:
        return _no("save_load", "reset 후에도 소거 잔존")
    SaveManager.load(SLOT)
    SaveManager.delete_save(SLOT)
    if not (MemoryLedger.is_erased("a_face") and MemoryLedger.is_erased("true_name")):
        return _no("save_load", "로드 후 소거 상태 복원 실패")
    if MemoryLedger.erased_count() != 2:
        return _no("save_load", "로드 후 소거 수 %d (expect 2)" % MemoryLedger.erased_count())
    return _ok("save_load")


func _check_glyph_bounds() -> Dictionary:
    var text := "그 문을 내린 자가, 나다."
    # ratio 0 → 변형 없음
    if MemoryGlyph.strip(text, 0.0, 1) != text:
        return _no("glyph_bounds", "ratio=0 인데 글자가 변형됨")
    if MemoryGlyph.erased_indices(text, 0.0, 1).size() != 0:
        return _no("glyph_bounds", "ratio=0 인데 소거 인덱스 존재")
    # ratio 1 → 공백 아닌 글자 전부 소거
    var non_space := 0
    for i in text.length():
        var ch := text[i]
        if ch != " ":
            non_space += 1
    if MemoryGlyph.erased_indices(text, 1.0, 1).size() != non_space:
        return _no("glyph_bounds", "ratio=1 에 공백 외 전부 소거 아님")
    return _ok("glyph_bounds")


func _check_glyph_monotonic() -> Dictionary:
    var text := "또 한 넋을 보냈다. 누구의 얼굴이었더라."
    var lo := MemoryGlyph.erased_indices(text, 0.3, 7)
    var hi := MemoryGlyph.erased_indices(text, 0.7, 7)
    # 비율이 오르면 소거 집합은 단조 증가(기억은 되살아나지 않는다)
    if hi.size() < lo.size():
        return _no("glyph_monotonic", "0.7 소거수 %d < 0.3 소거수 %d" % [hi.size(), lo.size()])
    for i in lo:
        if not hi.has(i):
            return _no("glyph_monotonic", "0.3 에 소거된 %d 가 0.7 에서 부활" % i)
    return _ok("glyph_monotonic")


func _check_glyph_spaces_and_determinism() -> Dictionary:
    var text := "물에 빛 드는 걸 보셔요"
    # 공백 보존
    var stripped := MemoryGlyph.strip(text, 1.0, 3)
    for i in text.length():
        if text[i] == " " and stripped[i] != " ":
            return _no("glyph_spaces", "공백 위치가 소거됨")
    # 결정적: 같은 입력이면 같은 결과
    var a := MemoryGlyph.dissolve(text, 0.5, 42)
    var b := MemoryGlyph.dissolve(text, 0.5, 42)
    if a != b:
        return _no("glyph_spaces", "같은 seed/비율인데 결과가 다름(비결정적)")
    # 소거 안 된 글자는 strip 결과에 원문 그대로 남는다(소거된 자리만 공백으로 비움)
    var idx := MemoryGlyph.erased_indices(text, 0.5, 42)
    var s := MemoryGlyph.strip(text, 0.5, 42)
    for i in text.length():
        if not idx.has(i) and s[i] != text[i]:
            return _no("glyph_spaces", "소거 안 된 %d번 글자가 strip 에서 바뀜" % i)
    return _ok("glyph_spaces")
