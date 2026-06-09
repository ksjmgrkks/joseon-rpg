extends Node
##
## TimeManager autoload — 게임 내 시간 흐름(낮/밤).
##
## 한 사이클 = day_seconds + night_seconds (기본 180 + 90 = 270초 = 4.5분).
## 시작은 낮(time_of_day=0.0).
## 시그널: phase_changed(is_night: bool), time_changed(t: float)   t in [0,1)
##

signal phase_changed(is_night: bool)
signal time_changed(t: float)

@export var day_seconds: float = 180.0
@export var night_seconds: float = 90.0
@export var paused_at_start: bool = false

var time_of_day: float = 0.0     # [0,1) — 0..day_ratio 가 낮
var _running: bool = true


func _ready() -> void:
    _running = not paused_at_start
    SaveManager.save_requested.connect(_on_save)
    SaveManager.loaded.connect(_on_load)


func _process(delta: float) -> void:
    if not _running:
        return
    var total := day_seconds + night_seconds
    if total <= 0.0:
        return
    var prev_night := is_night()
    time_of_day = fposmod(time_of_day + delta / total, 1.0)
    time_changed.emit(time_of_day)
    var now_night := is_night()
    if now_night != prev_night:
        phase_changed.emit(now_night)


func day_ratio() -> float:
    var total := day_seconds + night_seconds
    if total <= 0.0:
        return 1.0
    return day_seconds / total


func is_night() -> bool:
    return time_of_day >= day_ratio()


func set_paused(b: bool) -> void:
    _running = not b


func set_time(t: float) -> void:
    time_of_day = fposmod(t, 1.0)
    time_changed.emit(time_of_day)


# 0..1 의 t 값을 받아 화면 tint 색을 반환 — CanvasModulate 같은 데서 활용.
func tint_for(t: float) -> Color:
    var night_pct: float = 0.0
    var dr := day_ratio()
    if t < dr:
        # 낮 — 끝부분 가까울수록 약간 황혼 톤
        var p := t / max(dr, 0.0001)   # 0..1
        if p < 0.7:
            return Color(1, 1, 1, 1)
        night_pct = (p - 0.7) / 0.3   # 0..1
    else:
        # 밤 — 진입 직후 어두워졌다가 새벽 가까이 다시 밝아짐
        var p := (t - dr) / max(1.0 - dr, 0.0001) # 0..1
        if p < 0.2:
            night_pct = lerp(1.0, 1.0, 0.0)  # 진입은 즉시 어둡게
            night_pct = 1.0
        elif p < 0.8:
            night_pct = 1.0
        else:
            night_pct = (1.0 - p) / 0.2   # 새벽으로 밝아짐
    var dawn := Color(1, 1, 1, 1)
    var night := Color(0.35, 0.42, 0.62, 1)
    return dawn.lerp(night, clampf(night_pct, 0.0, 1.0))


func _on_save(_slot: int, data: Dictionary) -> void:
    data["time"] = { "t": time_of_day }


func _on_load(_slot: int, data: Dictionary) -> void:
    var d: Dictionary = data.get("time", {})
    time_of_day = clampf(float(d.get("t", 0.0)), 0.0, 1.0)
    time_changed.emit(time_of_day)
    phase_changed.emit(is_night())
