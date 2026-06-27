extends ParallaxBackground
class_name ParallaxBackdrop
##
## 수묵 산수 패럴랙스 배경 — bg_far/mid/near 3레이어 + 분위기 연출(코드).
## 각 레벨 루트에 인스턴스만 하면 됨. 레벨마다 톤이 다르도록 sky_color / tint 조절.
##
## bg PNG 는 640x360, 정수배(2x)로 깔아 가로 무한 반복(motion_mirroring).
##
## 추가 연출(아트 재생성 불필요·코드만):
##   ① 그라데이션 하늘  — 단색 대신 위(하늘)→아래(지평선 한지빛) 세로 그라데이션.
##   ② 떠다니는 구름     — 코드 드로잉 구름 레이어가 느리게 흐른다(별도 레이어 → 산은 안 움직임).
##   ③ 대기 원근(aerial) — 먼 산일수록 하늘색에 가깝게 흐려 깊이감.
##   ④ 야간 분위기       — 어두운 하늘(폐사지·제단 등)엔 별/반딧불이 은은히 깜빡인다.
##

@export var sky_color: Color = Color(0.93, 0.89, 0.78, 1.0)   # 한지 베이지(낮)
@export var tint: Color = Color.WHITE
@export var scale_factor: int = 2
# 각 레이어 motion_scale (0=고정, 1=카메라와 동일). 멀수록 작게.
@export var far_scale: float = 0.15
@export var mid_scale: float = 0.40
@export var near_scale: float = 0.70
# 화면 하단에서 배경을 얼마나 올릴지 (지면 위로 산수가 보이게)
@export var y_offset: float = 40.0
# 대기 원근: 먼 산을 하늘색 쪽으로 얼마나 흐릴지 (0=그대로, 1=완전 하늘색).
@export var aerial: float = 0.35
# 구름이 흐르는 속도(px/s, 음수면 왼쪽). 0 이면 정지.
@export var cloud_drift: float = -7.0
# 야간 분위기 자동 판정 임계(하늘 휘도). 이보다 어두우면 별/반딧불 표시. 음수면 끔.
@export var night_luminance: float = 0.55

const BG_FAR := "res://assets/sprites/bg/bg_far.png"
const BG_MID := "res://assets/sprites/bg/bg_mid.png"
const BG_NEAR := "res://assets/sprites/bg/bg_near.png"

var _cloud_layer: ParallaxLayer = null
var _ambience: Node2D = null


func _ready() -> void:
    _add_sky()
    _add_clouds()
    _add_layer(BG_FAR, far_scale, 0.0, aerial)      # 먼 산 — 대기 원근 적용
    _add_layer(BG_MID, mid_scale, 10.0, aerial * 0.4)
    _add_layer(BG_NEAR, near_scale, 24.0, 0.0)
    _add_ambience()


func _process(delta: float) -> void:
    # 구름만 천천히 흐르게 — 별도 레이어라 산수는 카메라 시차만 따른다.
    if _cloud_layer and cloud_drift != 0.0:
        _cloud_layer.motion_offset.x += cloud_drift * delta


# ── ① 그라데이션 하늘 ────────────────────────────────────────
func _add_sky() -> void:
    var layer := ParallaxLayer.new()
    layer.motion_scale = Vector2(0, 0)   # 화면 고정
    add_child(layer)
    var grad := Gradient.new()
    grad.set_color(0, sky_color)                       # 최상단(하늘)
    grad.add_point(0.6, sky_color)                     # 상단 60% 는 하늘색 유지
    # 지평선: 하늘색을 밝게 + 한지빛으로 살짝 끌어와 부드러운 노을/안개
    var horizon := sky_color.lightened(0.16).lerp(Color(0.96, 0.92, 0.82), 0.32)
    grad.set_color(grad.get_point_count() - 1, horizon)  # 최하단(지평선)
    var gtex := GradientTexture2D.new()
    gtex.gradient = grad
    gtex.fill_from = Vector2(0, 0)
    gtex.fill_to = Vector2(0, 1)
    gtex.width = 8
    gtex.height = 256
    var tr := TextureRect.new()
    tr.texture = gtex
    tr.stretch_mode = TextureRect.STRETCH_SCALE
    tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
    # 화면(720) 위쪽은 하늘, 지면(약 684) 부근이 지평선이 되도록 세로 범위 설정.
    tr.size = Vector2(8192, 1200)
    tr.position = Vector2(-4096, -300)
    layer.add_child(tr)


# ── ② 떠다니는 구름(코드 드로잉) ─────────────────────────────
func _add_clouds() -> void:
    if cloud_drift == 0.0:
        return
    var layer := ParallaxLayer.new()
    layer.motion_scale = Vector2(0.08, 1.0)   # 아주 먼 하늘 — 카메라엔 거의 안 따라옴
    var field := 1280.0
    layer.motion_mirroring = Vector2(field, 0)   # 구름밭 가로 반복
    add_child(layer)
    _cloud_layer = layer
    # 구름 색 — 한지빛, 야간이면 살짝 어둡게
    var night := _is_night()
    var col := Color(1.0, 0.98, 0.92, 0.32) if not night else Color(0.80, 0.82, 0.90, 0.22)
    var rng := RandomNumberGenerator.new()
    rng.seed = 20260627
    for i in range(5):
        var cx := rng.randf_range(0.0, field)
        var cy := rng.randf_range(40.0, 230.0)
        _draw_cloud(layer, Vector2(cx, cy), rng.randf_range(0.8, 1.6), col, rng)


# 동양화풍 안개구름 — 납작한 타원 덩어리 3~4개를 겹쳐 한 송이.
func _draw_cloud(parent: Node, pos: Vector2, scale: float, col: Color, rng: RandomNumberGenerator) -> void:
    var root := Node2D.new()
    root.position = pos
    root.z_index = 1
    parent.add_child(root)
    var lobes := rng.randi_range(3, 4)
    for j in range(lobes):
        var lobe := Polygon2D.new()
        var rx := rng.randf_range(28.0, 52.0) * scale
        var ry := rng.randf_range(8.0, 13.0) * scale
        var pts := PackedVector2Array()
        for k in range(12):
            var a := TAU * k / 12.0
            pts.append(Vector2(cos(a) * rx, sin(a) * ry))
        lobe.polygon = pts
        lobe.color = col
        lobe.position = Vector2(rng.randf_range(-30, 30) * scale, rng.randf_range(-6, 6) * scale)
        root.add_child(lobe)


# ── ③ 산수 레이어(대기 원근 포함) ────────────────────────────
func _add_layer(path: String, motion: float, extra_y: float, aerial_amt: float = 0.0) -> void:
    if not ResourceLoader.exists(path):
        return
    var tex: Texture2D = load(path)
    var layer := ParallaxLayer.new()
    layer.motion_scale = Vector2(motion, 1.0)
    var tw := tex.get_width() * scale_factor
    var th := tex.get_height() * scale_factor
    layer.motion_mirroring = Vector2(tw, 0)   # 가로 무한 반복
    add_child(layer)
    var spr := Sprite2D.new()
    spr.texture = tex
    spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    spr.centered = false
    spr.scale = Vector2(scale_factor, scale_factor)
    # 대기 원근: 먼 산일수록 하늘색으로 흐려 깊이감.
    spr.modulate = tint.lerp(sky_color, clampf(aerial_amt, 0.0, 1.0)) if aerial_amt > 0.0 else tint
    spr.position = Vector2(0, 720 - th + y_offset + extra_y)
    layer.add_child(spr)


# ── ④ 야간 분위기(별·반딧불) ─────────────────────────────────
func _is_night() -> bool:
    return night_luminance >= 0.0 and sky_color.get_luminance() < night_luminance


func _add_ambience() -> void:
    if not _is_night():
        return
    var layer := ParallaxLayer.new()
    layer.motion_scale = Vector2(0.06, 0.2)   # 하늘에 붙어 거의 고정
    add_child(layer)
    var root := Node2D.new()
    root.z_index = 2
    layer.add_child(root)
    _ambience = root
    # 푸른 하늘이면 별(차갑고 높이), 그 외(숲 등)면 반딧불(따뜻하고 낮게).
    var starry := sky_color.b >= sky_color.g
    var col := Color(0.92, 0.95, 1.0) if starry else Color(0.95, 0.92, 0.55)
    var rng := RandomNumberGenerator.new()
    rng.seed = 990627
    var n := 26 if starry else 18
    for i in range(n):
        var dot := Polygon2D.new()
        var r := rng.randf_range(1.0, 2.2)
        dot.polygon = PackedVector2Array([
            Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)])
        dot.color = col
        var y_hi := 0.0 if starry else 180.0   # 별은 위쪽, 반딧불은 중하단
        var y_lo := 260.0 if starry else 380.0
        dot.position = Vector2(rng.randf_range(0.0, 1280.0), rng.randf_range(y_hi, y_lo))
        root.add_child(dot)
        # 깜빡임(트윈 루프) — 각자 다른 속도·위상.
        var lo := rng.randf_range(0.15, 0.4)
        var dur := rng.randf_range(0.8, 2.0)
        dot.modulate.a = rng.randf_range(0.4, 1.0)
        var tw := dot.create_tween().set_loops()
        tw.tween_property(dot, "modulate:a", lo, dur).set_trans(Tween.TRANS_SINE)
        tw.tween_property(dot, "modulate:a", 1.0, dur).set_trans(Tween.TRANS_SINE)
        # 반딧불은 천천히 떠다님.
        if not starry:
            var drift := dot.create_tween().set_loops()
            var dx := rng.randf_range(-14, 14)
            var dy := rng.randf_range(-10, 10)
            var ddur := rng.randf_range(2.5, 4.5)
            var base := dot.position
            drift.tween_property(dot, "position", base + Vector2(dx, dy), ddur).set_trans(Tween.TRANS_SINE)
            drift.tween_property(dot, "position", base, ddur).set_trans(Tween.TRANS_SINE)
