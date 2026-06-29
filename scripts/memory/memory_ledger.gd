extends Node
##
## MemoryLedger — autoload. 「해원(解冤)」의 시그니처 시스템 ①·② 중 **'기억이 지워짐'**.
##
## 길손이 원혼을 하나 해원(진혼)할 때마다, 그에 얽힌 제 기억 한 조각이 지워진다.
## 곧 속죄이자 망각이자 자기소멸 — 짐을 더는 것이 곧 자신을 지우는 일.
## 마지막엔 화면에 단 하나의 이름 '윤슬'만 남고, 그마저 놓으면 모든 글자가 빈다(자기 천도).
##
## 이 스크립트는 "무엇이/얼마나 지워졌는가"의 **순수 상태·순서·세이브**만 책임진다.
## 글자가 실제로 흐려지고 사라지는 비주얼은 `memory_glyph.gd`(순수 변환) + 대사/HUD 레이어가 담당.
## (단일 책임 분리 — CLAUDE.md 코드 컨벤션.)
##
## 사용:
##   MemoryLedger.reset()                       # 새 게임 시작 시
##   MemoryLedger.erase_for_gut(gut_index)      # 한 굽이의 진혼 완료 시 호출(그 굽이 조각 전부 소거)
##   MemoryLedger.progress()                    # 0.0~1.0 (HUD/글자 dissolve 비율)
##   MemoryLedger.is_erased("true_name")        # 특정 조각 소거 여부(대사 분기·이름 표기)
##   MemoryLedger.screen_names()                # 화면에 아직 남은 정체성 토큰(마지막엔 ["윤슬"])
##
## SaveManager 연동: save_requested 에 "memory" 키로 자기 영역을 싣고, loaded 에서 복원.
##

## 한 조각이 지워질 때(굽이 진혼 후). UI 가 글자 dissolve 연출을 트리거.
signal memory_erased(fragment: Dictionary)
## 상태가 바뀔 때마다(소거·리셋·로드) — HUD/이름표 갱신용.
signal ledger_changed()
## 마지막 이름('윤슬')마저 놓이는 순간(6굽이 끝) — 엔딩 트리거.
signal last_name_released()

## 굽이 순서대로의 기억 조각. gut: 0=프롤로그, 1~6=굽이. (STORY_BIBLE 비트시트와 1:1)
## (자동로드 파싱 안정성을 위해 const 는 타입 주석 없이 둔다 — 원소는 Dictionary.)
const FRAGMENTS := [
    {"id": "a_face",          "gut": 0, "label": "누군가의 얼굴 하나"},
    {"id": "watergate_keeper","gut": 1, "label": "물길을 쥐고 문을 여닫던 자였다는 자각"},
    {"id": "the_seat",        "gut": 2, "label": "명령을 내리던 자리에 있었다는 기억"},
    {"id": "true_name",       "gut": 3, "label": "제 본명 — 이후로는 '길손'이라는 호칭만 남는다"},
    {"id": "the_cause",       "gut": 4, "label": "무엇을(고을을) 위해 그랬는지, 그 명분"},
    {"id": "almost_all",      "gut": 5, "label": "거의 전부 — 이제 화면엔 '윤슬' 한 이름만"},
    {"id": "yunseul",         "gut": 6, "label": "윤슬 — 끝내 못 구한 사랑하는 이, 마지막 한 이름"},
]

## 끝까지 화면에 남는 단 하나의 이름(시그니처).
const LAST_NAME := "윤슬"

var _erased: Dictionary = {}   # id(String) -> true


func _ready() -> void:
    SaveManager.save_requested.connect(_on_save_requested)
    SaveManager.loaded.connect(_on_loaded)


# ─────────────────────────── 상태 변경 ───────────────────────────

## 새 게임: 모든 기억이 온전한 상태로 되돌린다.
func reset() -> void:
    _erased.clear()
    ledger_changed.emit()


## 특정 조각 하나를 지운다. 이미 지워졌으면 무시. 새로 지워졌으면 true.
func erase(id: String) -> bool:
    if _erased.has(id):
        return false
    var frag := _fragment(id)
    if frag.is_empty():
        push_warning("[MemoryLedger] 알 수 없는 기억 조각: %s" % id)
        return false
    _erased[id] = true
    memory_erased.emit(frag)
    ledger_changed.emit()
    if id == "yunseul":
        last_name_released.emit()
    return true


## 한 굽이의 진혼이 끝났을 때 호출 — 그 굽이에 속한 조각을 전부 지운다.
## 지워진 조각 수를 반환(연출용).
func erase_for_gut(gut: int) -> int:
    var n := 0
    for frag in FRAGMENTS:
        if int(frag["gut"]) == gut and not _erased.has(frag["id"]):
            if erase(String(frag["id"])):
                n += 1
    return n


# ─────────────────────────── 조회 ───────────────────────────

func is_erased(id: String) -> bool:
    return _erased.has(id)


func erased_count() -> int:
    return _erased.size()


func total() -> int:
    return FRAGMENTS.size()


## 0.0(아무것도 안 지워짐) ~ 1.0(전부 지워짐). 글자 dissolve 강도·HUD 표현에.
func progress() -> float:
    if FRAGMENTS.is_empty():
        return 0.0
    return float(_erased.size()) / float(FRAGMENTS.size())


## 본명이 아직 남아 있는가(3굽이 'true_name' 소거 전). false 면 어디서든 '길손'으로만 표기.
func name_intact() -> bool:
    return not _erased.has("true_name")


## 화면에 아직 남아야 할 정체성 토큰들(이름표/HUD). 지워질수록 줄고,
## 5굽이 이후엔 [LAST_NAME] 하나, 6굽이 끝('yunseul' 소거)엔 빈 배열.
func screen_names() -> Array[String]:
    var names: Array[String] = []
    if _erased.has("yunseul"):
        return names
    if _erased.has("almost_all"):
        names.append(LAST_NAME)
        return names
    if name_intact():
        names.append("길손")   # 본명은 끝내 안 나오므로 호칭으로 표기(소거 전엔 또렷)
    names.append(LAST_NAME)
    return names


## 다음에 지워질(아직 온전한 가장 이른 굽이의) 조각. 없으면 빈 Dictionary.
func next_fragment() -> Dictionary:
    for frag in FRAGMENTS:
        if not _erased.has(frag["id"]):
            return frag
    return {}


func _fragment(id: String) -> Dictionary:
    for frag in FRAGMENTS:
        if String(frag["id"]) == id:
            return frag
    return {}


# ─────────────────────────── 세이브/로드 ───────────────────────────

func _on_save_requested(_slot: int, data: Dictionary) -> void:
    data["memory"] = { "erased": _erased.keys() }


func _on_loaded(_slot: int, data: Dictionary) -> void:
    _erased.clear()
    var mem = data.get("memory", {})
    if mem is Dictionary:
        for id in mem.get("erased", []):
            _erased[String(id)] = true
    ledger_changed.emit()
