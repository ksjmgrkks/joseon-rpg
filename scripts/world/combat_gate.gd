extends Node2D
class_name CombatGate
##
## 전투 게이트 — 구역의 적("enemy" 그룹)을 모두 처치할 때까지 길을 막는 장벽.
## 적이 0이 되면 장벽을 걷고 토스트로 알린 뒤, 옵션 플래그를 세운다.
##
## 빌더가 생성: 보이는 반투명 결계 + 충돌 벽(StaticBody2D). 적 처치 완료 시 스스로 개방.
## 스테이지 시작 시 적이 없으면(0) 즉시 열림.
##

@export var open_flag: String = ""        # 열릴 때 set_flag (선택)
@export var gate_height: float = 200.0

var _barrier: StaticBody2D
var _label: Label
var _open: bool = false
var _grace: float = 0.4                    # 적 스폰 대기(시작 직후 오판 방지)


func _ready() -> void:
    # 충돌 벽 (플레이어 차단)
    _barrier = StaticBody2D.new()
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(16, gate_height)
    cs.shape = shape
    _barrier.add_child(cs)
    add_child(_barrier)
    # 시각 결계 — 반투명 청색 빛기둥(영적 장막)
    var rect := ColorRect.new()
    rect.color = Color(0.25, 0.42, 0.55, 0.35)
    rect.offset_left = -8
    rect.offset_top = -gate_height / 2.0
    rect.offset_right = 8
    rect.offset_bottom = gate_height / 2.0
    _barrier.add_child(rect)
    # 남은 적 안내 라벨 (결계 위)
    _label = Label.new()
    _label.text = "결계가 막혀 있다"
    _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _label.position = Vector2(-80, -gate_height / 2.0 - 28)
    _label.size = Vector2(160, 24)
    _label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
    _label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
    _label.add_theme_constant_override("outline_size", 4)
    _barrier.add_child(_label)


func _process(delta: float) -> void:
    if _open:
        return
    if _grace > 0.0:
        _grace -= delta
        return
    var remaining := get_tree().get_nodes_in_group("enemy").size()
    if remaining <= 0:
        _open_gate()
    elif _label:
        _label.text = "남은 적 %d" % remaining


func _open_gate() -> void:
    _open = true
    if open_flag != "":
        Flags.set_flag(open_flag, true)
    if QuestToast:
        QuestToast._show("길이 열렸다 — 나아가라")
    if ScreenFx:
        ScreenFx.shake(3.0, 0.2)
    # 결계 사라지는 연출
    var tw := create_tween()
    tw.tween_property(_barrier, "modulate:a", 0.0, 0.4)
    tw.tween_callback(_barrier.queue_free)
