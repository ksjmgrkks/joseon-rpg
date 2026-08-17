extends Node2D
class_name EnemyHpBar
##
## 적 머리 위 HP 바. 피격 시 보였다가 일정 시간 뒤 다시 숨김.
##
## 사용: 적 _ready() 에서 EnemyHpBar.attach_to(self, health) 호출.
##
## 위치·폭은 적 스프라이트(Sprite2D)의 실제 프레임 크기·스케일·foot_offset 에서
## 계산해 **머리 위**에 걸린다(적마다 키가 달라 고정 오프셋이면 몸통에 걸침).
## 두께는 폰 화면에서도 보이도록 두툼하게, 잔상(lag) 바로 방금 깎인 양을 보여준다.
##

const SHOW_SECONDS := 2.6
const MIN_WIDTH := 34.0
const MAX_WIDTH := 84.0
const BAR_HEIGHT := 7.0
const BOSS_BAR_HEIGHT := 10.0
const HEAD_MARGIN := 12.0      # 머리끝 ↔ 바 아래선 여유
const FALLBACK_TOP := -44.0    # 스프라이트를 못 찾을 때 기본 머리 높이
const LAG_DELAY := 0.16        # 잔상 바가 따라오기 전 멈춰 있는 시간
const LAG_TIME := 0.34         # 잔상 바가 줄어드는 시간

# 먹·단청 팔레트 (STYLE 유지)
const C_FRAME := Color(0.6, 0.498, 0.251, 0.85)   # 단청 황(금) 깊은 톤
const C_BG := Color(0.102, 0.086, 0.071, 0.92)    # 먹(최심)
const C_LAG := Color(0.97, 0.93, 0.84, 0.85)      # 한지빛 잔상(방금 깎인 양)
# 어두운 우천 톤(WorldTint)에서도 읽히도록 살짝 밝게 잡은 단청 적/주홍.
const C_FILL := Color(0.80, 0.32, 0.28, 1)        # 단청 적
const C_FILL_LOW := Color(0.95, 0.52, 0.26, 1)    # 빈사(30% 이하) — 밝은 주홍

var _bar: ColorRect
var _lag: ColorRect
var _bg: ColorRect
var _frame: ColorRect
var _hide_timer: float = 0.0
var _max_hp: float = 1.0
var _width: float = 40.0
var _height: float = BAR_HEIGHT
var _lag_tween: Tween
# 프레임 중앙 ↔ 그려진 몸 중앙 차이(좌우 반전 시 부호를 뒤집어 따라간다)
var _center_dx: float = 0.0
var _sprite: AnimatedSprite2D = null


## host 의 Sprite2D 를 재어 머리 위에 건다. big=true 면 보스용(두껍고 넓게).
static func attach_to(host: Node2D, health: HealthComponent, big: bool = false) -> EnemyHpBar:
    var b := EnemyHpBar.new()
    b._height = BOSS_BAR_HEIGHT if big else BAR_HEIGHT
    host.add_child(b)
    b._max_hp = health.max_hp
    b._fit_to_host(host, big)
    health.hp_changed.connect(b._on_hp_changed)
    return b


## 스프라이트 프레임에서 머리 높이·몸 폭을 계산해 바 크기/위치를 정한다.
## (자식 노드는 부모 _ready 보다 먼저 준비되므로 이 시점에 sprite_frames 가 이미 있다.)
func _fit_to_host(host: Node2D, big: bool) -> void:
    var top := FALLBACK_TOP
    var body_w := 40.0
    var spr := host.get_node_or_null("Sprite2D")
    if spr is AnimatedSprite2D:
        var a := spr as AnimatedSprite2D
        var tex: Texture2D = null
        if a.sprite_frames:
            var anim: StringName = a.animation if a.sprite_frames.has_animation(a.animation) else &"idle"
            if a.sprite_frames.has_animation(anim) and a.sprite_frames.get_frame_count(anim) > 0:
                tex = a.sprite_frames.get_frame_texture(anim, 0)
        if tex:
            var sy: float = absf(a.scale.y)
            var sx: float = absf(a.scale.x)
            # 프레임 안의 **실제로 그려진 픽셀** 상단/폭을 쓴다 — 시트마다 투명 여백이
            # 달라서 프레임 크기만 쓰면 바가 머리에서 한참 떠 보인다.
            var rect := _opaque_rect(tex)
            # 프레임은 중심 정렬 + offset(=foot_offset) → 머리끝 y
            top = a.position.y + (a.offset.y - tex.get_height() / 2.0 + rect.position.y) * sy
            body_w = rect.size.x * sx
            # 그려진 몸이 프레임 중앙에서 치우쳐 있으면 바도 그만큼 따라간다(머리 위 정렬).
            _center_dx = (rect.position.x + rect.size.x / 2.0 - tex.get_width() / 2.0) * sx
            _sprite = a
    _width = clampf(body_w * (1.15 if big else 1.05), MIN_WIDTH, MAX_WIDTH)
    if big:
        _width = maxf(_width, 64.0)
    position = Vector2(_center_dx, top - HEAD_MARGIN - _height)
    _apply_geometry()


# 프레임 안에서 실제로 불투명한 영역(캐릭터가 그려진 부분). 텍스처당 1회만 계산해 캐시.
static var _rect_cache: Dictionary = {}

static func _opaque_rect(tex: Texture2D) -> Rect2:
    var key := "%s#%d" % [tex.resource_path, tex.get_instance_id()]
    if _rect_cache.has(key):
        return _rect_cache[key]
    var full := Rect2(Vector2.ZERO, Vector2(tex.get_width(), tex.get_height()))
    var img := tex.get_image()
    if img == null:
        return full
    if img.is_compressed():
        return full
    var r := img.get_used_rect()
    if r.size.x <= 0 or r.size.y <= 0:
        r = Rect2i(Vector2i.ZERO, Vector2i(tex.get_width(), tex.get_height()))
    var out := Rect2(r.position, r.size)
    _rect_cache[key] = out
    return out


func _ready() -> void:
    z_index = 20
    _frame = ColorRect.new()
    _frame.color = C_FRAME
    add_child(_frame)
    _bg = ColorRect.new()
    _bg.color = C_BG
    add_child(_bg)
    _lag = ColorRect.new()
    _lag.color = C_LAG
    add_child(_lag)
    _bar = ColorRect.new()
    _bar.color = C_FILL
    add_child(_bar)
    _apply_geometry()
    visible = false


# 폭·두께를 실제 노드에 반영 (attach 시점/ready 시점 어느 쪽이 먼저든 안전)
func _apply_geometry() -> void:
    if _frame == null:
        return
    var half := _width / 2.0
    _frame.position = Vector2(-half - 2, -2)
    _frame.size = Vector2(_width + 4, _height + 4)
    _bg.position = Vector2(-half, 0)
    _bg.size = Vector2(_width, _height)
    _lag.position = Vector2(-half, 0)
    _lag.size = Vector2(_width, _height)
    _bar.position = Vector2(-half, 0)
    _bar.size = Vector2(_width, _height)


func _process(delta: float) -> void:
    # 대화 중에는 적 HP 바를 감춰 화면을 깨끗이 비운다(몰입).
    if Dialogue and Dialogue.is_active():
        if visible:
            visible = false
        _hide_timer = 0.0
        return
    if _hide_timer > 0.0:
        _hide_timer = maxf(0.0, _hide_timer - delta)
        if _hide_timer <= 0.0:
            visible = false
    # 적이 좌우로 돌면 그려진 몸도 뒤집히므로 바 중심도 따라 뒤집는다.
    if visible and _center_dx != 0.0 and _sprite and is_instance_valid(_sprite):
        position.x = -_center_dx if _sprite.flip_h else _center_dx


func _on_hp_changed(hp: float, max_hp: float) -> void:
    _max_hp = max_hp
    var ratio := clampf(hp / max_hp, 0.0, 1.0)
    if _bar:
        _bar.size.x = _width * ratio                     # 실제 HP 는 즉시 깎이고
        _bar.color = C_FILL_LOW if ratio <= 0.3 else C_FILL
    if _lag:
        # 잔상 바는 잠시 머물다 뒤따라 줄어든다 → '얼마나 깎였나'가 눈에 보임
        if _lag_tween and _lag_tween.is_valid():
            _lag_tween.kill()
        _lag.size.x = maxf(_lag.size.x, _width * ratio)
        _lag_tween = create_tween()
        _lag_tween.tween_interval(LAG_DELAY)
        _lag_tween.tween_property(_lag, "size:x", _width * ratio, LAG_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _punch()
    visible = true
    _hide_timer = SHOW_SECONDS


# 피격 순간 바가 짧게 부풀었다 돌아온다(타격 반응).
func _punch() -> void:
    scale = Vector2(1.06, 1.35)
    var tw := create_tween()
    tw.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
