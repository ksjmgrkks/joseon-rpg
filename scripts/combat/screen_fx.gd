extends Node
##
## ScreenFx autoload — 화면 진동·명중 확대·시간 감속.
##
## 사용:
##   ScreenFx.shake(8.0, 0.20)        # 강도 px, 초
##   ScreenFx.hit_stop(0.06)          # 초. 폼이 화끈해짐.
##   ScreenFx.impact_focus(1.015)     # 월드만 1.5% 확대 후 원복
##   ScreenFx.slow_motion(0.025, 0.7) # 멎지 않는 짧은 명중 감속
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
# 명중 확대는 일반 shake의 offset과 별도 트랙으로 운용한다.
var _focus_tween: Tween = null
var _focus_camera: Camera2D = null
var _focus_base_zoom: Vector2 = Vector2.ONE
var _focus_target_ratio: float = 1.0
var _focus_serial: int = 0


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


## 유효 명중용 임팩트 포커스. 현재 사용자 배율을 기준으로 월드만 미세 확대했다가
## 빠르게 원래 배율로 돌아온다(CanvasLayer UI는 영향을 받지 않는다).
## 연속 명중은 같은 펄스를 더 강하게 갱신할 뿐, 확대/축소를 적마다 반복하지 않는다.
func impact_focus(zoom_ratio: float = 1.015, zoom_in: float = 0.022,
        zoom_out: float = 0.075) -> void:
    var cam := _current_camera()
    if cam == null:
        return
    var same_pulse := _focus_tween != null and _focus_tween.is_valid() and _focus_camera == cam
    if same_pulse:
        _focus_tween.kill()
        _focus_target_ratio = maxf(_focus_target_ratio, zoom_ratio)
    else:
        if _focus_tween and _focus_tween.is_valid():
            _focus_tween.kill()
            if is_instance_valid(_focus_camera):
                _focus_camera.zoom = _focus_base_zoom
        _focus_camera = cam
        _focus_base_zoom = cam.zoom
        _focus_target_ratio = zoom_ratio
    _focus_serial += 1
    var serial := _focus_serial
    var target := _focus_base_zoom * _focus_target_ratio
    var tween := create_tween()
    tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_property(cam, "zoom", target, zoom_in)\
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(cam, "zoom", _focus_base_zoom, zoom_out)\
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_callback(func() -> void: _finish_focus(cam, serial))
    _focus_tween = tween


## 히트스톱 — duration 초 동안 시간을 scale 배로 늦춘다.
## scale 이 작을수록 더 '딱' 멈춘다(묵직한 타격). 가벼운 타격은 scale 을 키워 살짝만.
func hit_stop(duration: float = 0.06, scale: float = 0.05) -> void:
    _time_dilate(duration, scale)


## 명중용 완만한 시간 감속. hit-stop과 같은 실시간 복구 장치를 쓰되 0.5 이상만 허용해
## 화면이 멎지 않고 공격 동작이 잠깐 묵직해지는 정도로 제한한다.
func slow_motion(duration: float = 0.025, scale: float = 0.7) -> void:
    _time_dilate(duration, clampf(scale, 0.5, 0.9))


func _time_dilate(duration: float, scale: float) -> void:
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


func _finish_focus(cam: Camera2D, serial: int) -> void:
    if serial != _focus_serial:
        return
    if is_instance_valid(cam):
        cam.zoom = _focus_base_zoom
    _focus_tween = null
    _focus_camera = null
    _focus_target_ratio = 1.0
