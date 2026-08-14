extends Node
##
## ScoreManager autoload — 스코어 어택 점수 + 플레이타임 + 최고기록.
## 엽전(화폐) 시스템 대체 (2026-08-15 도파민 스코어어택 개편).
##   - 혼/보스 처치 → 점수 획득 (add_score).
##   - 런 경과시간 추적 (일시정지·게임오버·클리어 중엔 정지).
##   - 최고 점수 / 최고(가장 빠른) 클리어 시간을 SaveManager 로 영구 저장.
##

signal score_changed(score: int)
signal playtime_changed(seconds: float)
signal record_updated(best_score: int, best_time: float)

var score: int = 0
var run_time: float = 0.0          # 현재 런 경과 초
var best_score: int = 0
var best_time: float = 0.0         # 최고(=가장 빠른) 클리어 시간. 0 = 기록 없음.

var _running: bool = false


func _ready() -> void:
    _load_records()


## 런 시작 — 첫 전투 스테이지 진입 시 stage.gd 가 호출. 점수·시간 리셋.
func start_run() -> void:
    score = 0
    run_time = 0.0
    _running = true
    score_changed.emit(score)
    playtime_changed.emit(run_time)


## 이어하기/체인 다음 스테이지 진입 — 점수·시간 유지한 채 계속 카운트.
func resume() -> void:
    _running = true


func stop_run() -> void:
    _running = false


## 처치 점수 획득.
func add_score(points: int) -> void:
    if points <= 0:
        return
    score += points
    score_changed.emit(score)


func _process(delta: float) -> void:
    if not _running:
        return
    if get_tree().paused:
        return                     # 일시정지/게임오버/클리어 중 시간 정지
    run_time += delta
    playtime_changed.emit(run_time)


## 런 종료 처리 — 최고기록 갱신 후 저장. cleared=true 면 클리어(시간 기록도 대상).
## 반환: {new_best_score, new_best_time, best_score, best_time} — 결과 화면 표시용.
func register_result(cleared: bool = false) -> Dictionary:
    _running = false
    var new_best_score := false
    var new_best_time := false
    if score > best_score:
        best_score = score
        new_best_score = true
    if cleared and (best_time <= 0.0 or run_time < best_time):
        best_time = run_time
        new_best_time = true
    _save_records()
    record_updated.emit(best_score, best_time)
    return {
        "new_best_score": new_best_score,
        "new_best_time": new_best_time,
        "best_score": best_score,
        "best_time": best_time,
    }


## MM:SS 포맷 (플레이타임 표시용).
static func format_time(seconds: float) -> String:
    var s := int(maxf(0.0, seconds))
    return "%02d:%02d" % [int(s / 60.0), s % 60]


func _load_records() -> void:
    if SaveManager == null:
        return
    var r: Dictionary = SaveManager.load_records()
    best_score = int(r.get("best_score", 0))
    best_time = float(r.get("best_time", 0.0))


func _save_records() -> void:
    if SaveManager == null:
        return
    SaveManager.save_records({ "best_score": best_score, "best_time": best_time })
