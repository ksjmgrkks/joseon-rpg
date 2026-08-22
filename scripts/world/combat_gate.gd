extends Node2D
class_name CombatGate
##
## 전투 게이트 — 구역의 적("enemy" 그룹)을 모두 처치할 때까지 길을 막는 장벽.
## 적이 0이 되면 장벽을 걷고 토스트로 알린 뒤, 옵션 플래그를 세운다.
##
## 빌더가 생성: 금줄 경계석 + 충돌 벽(StaticBody2D). 적 처치 완료 시 금줄이 풀린다.
## 스테이지 시작 시 적이 없으면(0) 즉시 열림.
##

## 결계가 열리는 순간(구역 적 전멸 = 진혼 완료) 1회 발화. 「해원」 기억 소거 배선이 듣는다.
## "enemy_gate" 그룹만 센다 — 선택 전투(patroller.optional=true)는 "enemy"엔 남되
## 여기선 빠져 결계를 막지 않는다(사이드 진혼: 죽여도 그만, 안 죽여도 그만).
signal opened

@export var open_flag: String = ""        # 열릴 때 set_flag (선택)
@export var gate_height: float = 200.0

var _barrier: StaticBody2D
var _label: Label
var _art: AnimatedSprite2D
var _open: bool = false
var _grace: float = 0.4                    # 적 스폰 대기(시작 직후 오판 방지)

## Stage 의 기본 게이트 중심 y=600에서 지면선 y=684까지의 거리.
const ART_GROUND_FROM_ORIGIN := 84.0


func _ready() -> void:
    # 충돌 벽 (플레이어 차단)
    _barrier = StaticBody2D.new()
    _barrier.collision_layer = 4    # 월드(bit3) — 플레이어 몸(mask=4)이 막힌다
    var cs := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(16, gate_height)
    cs.shape = shape
    _barrier.add_child(cs)
    add_child(_barrier)
    # A안 금줄 경계석. 처치 전과 통과 후가 같은 구조이며, 실제 6프레임으로 줄이 풀린다.
    _art = GateArt.make_sprite(false)
    if _art.sprite_frames != null and _art.sprite_frames.has_animation("closed"):
        _art.position.y = ART_GROUND_FROM_ORIGIN - GateArt.FRAME_SIZE.y * 0.5
        _barrier.add_child(_art)
    else:
        var rect := ColorRect.new()
        rect.color = Color(0.36, 0.30, 0.20, 0.65)
        rect.offset_left = -8
        rect.offset_top = -gate_height / 2.0
        rect.offset_right = 8
        rect.offset_bottom = gate_height / 2.0
        _barrier.add_child(rect)
    # 남은 적 안내 라벨 (결계 위)
    _label = Label.new()
    _label.text = "금줄이 길을 막고 있다"
    _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _label.position = Vector2(-80, -gate_height / 2.0 - 28)
    _label.size = Vector2(160, 24)
    _label.add_theme_color_override("font_color", Color(0.92, 0.87, 0.72))
    _label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
    _label.add_theme_constant_override("outline_size", 4)
    _barrier.add_child(_label)


func _process(delta: float) -> void:
    if _open:
        return
    if _grace > 0.0:
        _grace -= delta
        return
    var remaining := get_tree().get_nodes_in_group("enemy_gate").size()
    if remaining <= 0:
        _open_gate()
    # '남은 적 N' 카운터는 사용자 피드백(2026-07-11)으로 제거 — 결계 안내(정적)만 둔다.


func _open_gate() -> void:
    _open = true
    if open_flag != "":
        Flags.set_flag(open_flag, true)
    # 충돌부터 풀어 플레이어가 애니메이션 도중에도 갇히지 않게 한다.
    _barrier.collision_layer = 0
    _barrier.collision_mask = 0
    for child in _barrier.get_children():
        if child is CollisionShape2D:
            child.set_deferred("disabled", true)
    opened.emit()
    if QuestToast:
        QuestToast._show("금줄이 풀렸다 — 나아가라")
    if ScreenFx:
        ScreenFx.shake(3.0, 0.2)
    # 별도 통과문으로 교체하지 않는다. 같은 경계석의 금줄이 풀리고 마지막 프레임이 남는다.
    if is_instance_valid(_art) and _art.sprite_frames.has_animation("release"):
        _art.animation_finished.connect(_on_gate_release_finished, CONNECT_ONE_SHOT)
        _art.play("release")
    if is_instance_valid(_label):
        var tw := create_tween()
        tw.tween_property(_label, "modulate:a", 0.0, 0.25)
        tw.tween_callback(_label.queue_free)


func _on_gate_release_finished() -> void:
    if is_instance_valid(_art) and _art.sprite_frames.has_animation("open"):
        _art.play("open")
