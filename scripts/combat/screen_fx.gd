extends Node
##
## ScreenFx autoload — 화면 진동(camera shake)·히트스톱(hit stop).
##
## 사용:
##   ScreenFx.shake(8.0, 0.20)        # 강도 px, 초
##   ScreenFx.hit_stop(0.06)          # 초. 폼이 화끈해짐.
##
## 카메라는 매 호출 시점에 `get_viewport().get_camera_2d()` 로 동적 조회.
## 활성 카메라가 없으면 조용히 무시(헤드리스/테스트 안전).
##

# 히트스톱 진행 중에는 새 hit_stop 콜이 누적되지 않도록 잠금
var _hit_stopping: bool = false
# shake 누적도 같은 카메라에 대해 한 번에 하나만
var _active_tween: Tween = null


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS


func shake(intensity: float = 6.0, duration: float = 0.18) -> void:
    var cam := _current_camera()
    if cam == null:
        return
    if _active_tween and _active_tween.is_valid():
        _active_tween.kill()
    var original := cam.offset
    var steps := maxi(3, int(duration * 60.0))
    var tween := create_tween()
    tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    var per_step := duration / float(steps)
    for i in steps:
        var falloff := 1.0 - float(i) / float(steps)
        var offset := Vector2(
            randf_range(-intensity, intensity),
            randf_range(-intensity, intensity)
        ) * falloff
        tween.tween_property(cam, "offset", original + offset, per_step)
    tween.tween_property(cam, "offset", original, per_step)
    _active_tween = tween


## 히트스톱 — duration 초 동안 시간을 scale 배로 늦춘다.
## scale 이 작을수록 더 '딱' 멈춘다(묵직한 타격). 가벼운 타격은 scale 을 키워 살짝만.
func hit_stop(duration: float = 0.06, scale: float = 0.05) -> void:
    if _hit_stopping:
        return
    _hit_stopping = true
    var prev := Engine.time_scale
    Engine.time_scale = clampf(scale, 0.01, 1.0)
    # 시간 스케일이 줄어든 상태에서 await 하면 너무 길어지므로 real-time 타이머 사용.
    var t := get_tree().create_timer(duration, true, false, true)
    await t.timeout
    Engine.time_scale = prev
    _hit_stopping = false


func _current_camera() -> Camera2D:
    var tree := get_tree()
    if tree == null:
        return null
    var viewport := tree.root.get_viewport()
    if viewport == null:
        return null
    return viewport.get_camera_2d()
