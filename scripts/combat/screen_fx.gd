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
var _active_camera: Camera2D = null
var _active_base_offset: Vector2 = Vector2.ZERO
var _camera_fx_serial: int = 0


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _load_settings()


func shake(intensity: float = 6.0, duration: float = 0.18) -> void:
    var cam := _current_camera()
    if cam == null:
        return
    var original := _begin_camera_fx(cam)
    var serial := _camera_fx_serial
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
    tween.tween_callback(func() -> void: _finish_camera_fx(cam, original, serial))
    _active_tween = tween


## 유효 명중용 카메라 펀치. 무작위 떨림 대신 공격 방향으로 한 번 눌렀다가
## 약한 반동을 거쳐 기준 위치로 돌아와, 짧아도 프레임 드랍처럼 보이지 않는다.
func impact_bump(intensity: float = 2.0, duration: float = 0.075,
        direction_x: float = 1.0) -> void:
    var cam := _current_camera()
    if cam == null:
        return
    var original := _begin_camera_fx(cam)
    var serial := _camera_fx_serial
    var direction := 1.0 if direction_x >= 0.0 else -1.0
    var kick := Vector2(direction * intensity, -intensity * 0.16)
    var tween := create_tween()
    tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_property(cam, "offset", original + kick, duration * 0.22)\
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(cam, "offset", original - kick * 0.24, duration * 0.28)\
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(cam, "offset", original, duration * 0.50)\
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_callback(func() -> void: _finish_camera_fx(cam, original, serial))
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


## 햅틱(진동) — 폰에서 타격을 손끝으로 느끼게. 데스크톱/헤드리스에선 조용히 무시.
## 모바일 앱(Android/iOS) 및 안드로이드 브라우저(Web)에서 동작.
## 설정 메뉴의 토글로 끌 수 있고, user://settings.cfg 에 남는다.
const SETTINGS_PATH := "user://settings.cfg"
var haptics_enabled: bool = true


func set_haptics(on: bool) -> void:
    haptics_enabled = on
    var cfg := ConfigFile.new()
    cfg.load(SETTINGS_PATH)          # 없으면 빈 설정으로 시작
    cfg.set_value("feel", "haptics", on)
    cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SETTINGS_PATH) != OK:
        return
    haptics_enabled = bool(cfg.get_value("feel", "haptics", true))


func rumble(ms: int = 18) -> void:
    if not haptics_enabled:
        return
    var os_name := OS.get_name()
    if os_name == "Android" or os_name == "iOS" or os_name == "Web":
        Input.vibrate_handheld(clampi(ms, 1, 300))


func _current_camera() -> Camera2D:
    var tree := get_tree()
    if tree == null:
        return null
    var viewport := tree.root.get_viewport()
    if viewport == null:
        return null
    return viewport.get_camera_2d()


## 진행 중 효과를 새 흔들림 위치가 아니라 원래 카메라 위치로 먼저 복원한다.
## 다중 명중이 한 프레임에 겹쳐도 offset이 누적되거나 영구히 밀리지 않는다.
func _begin_camera_fx(cam: Camera2D) -> Vector2:
    if _active_tween and _active_tween.is_valid():
        _active_tween.kill()
        if is_instance_valid(_active_camera):
            _active_camera.offset = _active_base_offset
    _camera_fx_serial += 1
    _active_camera = cam
    _active_base_offset = cam.offset
    return _active_base_offset


func _finish_camera_fx(cam: Camera2D, original: Vector2, serial: int) -> void:
    if serial != _camera_fx_serial:
        return
    if is_instance_valid(cam):
        cam.offset = original
    _active_tween = null
    _active_camera = null
