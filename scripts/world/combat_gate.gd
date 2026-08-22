extends Node2D
class_name CombatGate
##
## 전투 게이트 — 구역의 적("enemy" 그룹)을 모두 처치할 때까지 길을 막는 장벽.
## 적이 0이 되면 장벽을 걷고 토스트로 알린 뒤, 옵션 플래그를 세운다.
##
## 빌더가 생성: 보이는 반투명 결계 + 충돌 벽(StaticBody2D). 적 처치 완료 시 스스로 개방.
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
var _open: bool = false
var _grace: float = 0.4                    # 적 스폰 대기(시작 직후 오판 방지)

## 결계 아트 폭(px) — 원본 64px 그림을 그대로 쓴다.
const BARRIER_ART_W: float = 64.0


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
    # 시각 결계 — 부적이 걸린 청색 빛기둥(PixelLab 아트, 2026-08-22 교체).
    # 예전엔 그냥 반투명 ColorRect 라 "결계"로 안 읽혔다.
    var tex_path := "res://assets/sprites/fx/gate_barrier.png"
    if ResourceLoader.exists(tex_path):
        var art := TextureRect.new()
        art.texture = load(tex_path)
        art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        # 세로로 이어 붙여 결계 높이를 채운다(가운데 띠가 반복돼도 티가 안 나는 그림).
        art.stretch_mode = TextureRect.STRETCH_TILE
        art.size = Vector2(BARRIER_ART_W, gate_height)
        art.position = Vector2(-BARRIER_ART_W / 2.0, -gate_height / 2.0)
        art.modulate = Color(1, 1, 1, 0.92)
        _barrier.add_child(art)
        # 아주 느린 명멸 — 살아 있는 장막처럼 보이게.
        var tw := art.create_tween().set_loops()
        tw.tween_property(art, "modulate:a", 0.72, 1.6).set_trans(Tween.TRANS_SINE)
        tw.tween_property(art, "modulate:a", 0.92, 1.6).set_trans(Tween.TRANS_SINE)
    else:
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
    var remaining := get_tree().get_nodes_in_group("enemy_gate").size()
    if remaining <= 0:
        _open_gate()
    # '남은 적 N' 카운터는 사용자 피드백(2026-07-11)으로 제거 — 결계 안내(정적)만 둔다.


func _open_gate() -> void:
    _open = true
    if open_flag != "":
        Flags.set_flag(open_flag, true)
    opened.emit()
    if QuestToast:
        QuestToast._show("길이 열렸다 — 나아가라")
    if ScreenFx:
        ScreenFx.shake(3.0, 0.2)
    # 결계 사라지는 연출
    var tw := create_tween()
    tw.tween_property(_barrier, "modulate:a", 0.0, 0.4)
    tw.tween_callback(_barrier.queue_free)
