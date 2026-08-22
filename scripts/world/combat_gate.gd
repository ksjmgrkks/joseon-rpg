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
    # 시각 결계 — 부적을 매단 빛기둥(PixelLab pro, 2026-08-22 교체).
    #
    # 「애니메이션 결계」 요청에 대해: PixelLab 의 animate_image 로 8프레임을 뽑아봤으나
    # 프레임마다 빛기둥이 사라지거나 색이 튀어(생성 드리프트) 루프가 지저분했다.
    # 정지 그림 한 장 + **엔진에서 두 겹으로 움직이는 방식**이 훨씬 깨끗하다:
    #   ① 본체는 천천히 밝아졌다 어두워지고(숨쉬는 장막)
    #   ② 그 위에 반투명 사본이 위로 흘러 올라간다(기가 솟는 결)
    var tex_path := "res://assets/sprites/fx/gate_barrier.png"
    if ResourceLoader.exists(tex_path):
        var tex: Texture2D = load(tex_path)
        # 두 겹이 결계 밖으로 새지 않도록 잘라내는 틀. 없으면 흐르는 겹이 화면 위아래로 뻗는다.
        var frame := Control.new()
        frame.clip_contents = true
        frame.size = Vector2(BARRIER_ART_W, gate_height)
        frame.position = Vector2(-BARRIER_ART_W / 2.0, -gate_height / 2.0)
        frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _barrier.add_child(frame)

        var art := TextureRect.new()
        art.texture = tex
        art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        art.stretch_mode = TextureRect.STRETCH_TILE
        art.size = Vector2(BARRIER_ART_W, gate_height)
        art.modulate = Color(1, 1, 1, 0.95)
        frame.add_child(art)
        var tw := art.create_tween().set_loops()
        tw.tween_property(art, "modulate:a", 0.74, 1.5).set_trans(Tween.TRANS_SINE)
        tw.tween_property(art, "modulate:a", 0.95, 1.5).set_trans(Tween.TRANS_SINE)

        # 흐르는 겹 — 한 타일 높이만큼 위로 올라갔다 제자리로(이어 붙어 티가 안 난다).
        var th := float(tex.get_height())
        var flow := TextureRect.new()
        flow.texture = tex
        flow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        flow.stretch_mode = TextureRect.STRETCH_TILE
        flow.size = Vector2(BARRIER_ART_W, gate_height + th)
        flow.position = Vector2(0, 0)
        flow.modulate = Color(0.85, 0.95, 1.0, 0.28)
        frame.add_child(flow)
        var ft := flow.create_tween().set_loops()
        ft.tween_property(flow, "position:y", -th, 2.6).set_trans(Tween.TRANS_LINEAR)
        ft.tween_callback(func() -> void: flow.position.y = 0.0)
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
