extends Node
##
## TouchLayoutConfig autoload — 터치 버튼 커스텀 위치 저장/복원.
##
## user://touch_layout.cfg 에 액션별 위치를 "사용 가능 영역(안전영역 제외)" 대비
## 정규화 비율(0.0~1.0)로 저장한다. 해상도·화면회전이 달라져도 같은 비율로
## 재배치되도록 하기 위함 — MobileControls._layout() 이 계산하는 w/h/ins 와
## 같은 좌표계를 쓴다.
##
## 세이브 슬롯(SaveManager)과 무관한 "기기 설정"이라 새로 시작/이어하기와 상관없이 유지된다.
##

const CFG_PATH := "user://touch_layout.cfg"
const SECTION := "positions"

signal layout_changed

var _ratios: Dictionary = {}   # action(String) -> Vector2(rx, ry) in [0,1]


func _ready() -> void:
    _load()


func has_custom(action: String) -> bool:
    return _ratios.has(action)


## 정규화 비율 → 픽셀 중심 좌표. `origin`=사용영역 좌상단(안전영역 반영), `size`=사용영역 크기.
func get_position(action: String, origin: Vector2, size: Vector2) -> Vector2:
    var r: Vector2 = _ratios.get(action, Vector2(-1, -1))
    return origin + r * size


## 픽셀 중심 좌표 → 정규화 비율로 변환해 저장 (아직 디스크에 쓰지 않음, commit() 필요).
func set_position(action: String, center: Vector2, origin: Vector2, size: Vector2) -> void:
    if size.x <= 0.0 or size.y <= 0.0:
        return
    var r := (center - origin) / size
    r.x = clampf(r.x, 0.0, 1.0)
    r.y = clampf(r.y, 0.0, 1.0)
    _ratios[action] = r


func commit() -> void:
    var cfg := ConfigFile.new()
    for action in _ratios:
        cfg.set_value(SECTION, action, _ratios[action])
    cfg.save(CFG_PATH)
    layout_changed.emit()


func reset_all() -> void:
    _ratios.clear()
    if FileAccess.file_exists(CFG_PATH):
        DirAccess.remove_absolute(CFG_PATH)
    layout_changed.emit()


func _load() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(CFG_PATH) != OK:
        return
    for action in cfg.get_section_keys(SECTION):
        var v = cfg.get_value(SECTION, action, null)
        if v is Vector2:
            _ratios[action] = v
