extends ParallaxBackground
class_name ParallaxBackdrop
##
## 수묵 산수 패럴랙스 배경 v2 — 깊이감 있는 조선 산수.
## 각 레벨 루트에 인스턴스만 하면 됨. 레벨마다 sky_color / tint 로 톤 조절.
##
## 구성(원경 → 근경):
##   ① 그라데이션 하늘   — 위(하늘)→아래(지평선 한지빛) 세로 그라데이션.
##   ② 떠다니는 구름      — 코드 드로잉 구름이 느리게 흐른다.
##   ③ 원경 먼 산맥       — PixelLab 수묵 산 실루엣(mtn_far)을 넓은 밭에 여러 개 흩어 배치.
##   ④ 산안개 띠(먼)      — 능선 사이 부드러운 안개(코드). 대기 원근·깊이.
##   ⑤ 중경 솔숲 능선     — PixelLab 솔숲 언덕(mtn_hill), 조금 더 진하게.
##   ⑥ 산안개 띠(낮은)    — 근경 앞 옅은 물안개.
##   ⑦ 근경 둔덕          — 솔숲 언덕을 더 크고 진하게(플레이 지면 바로 뒤).
##   ⑧ 야간 분위기        — 어두운 하늘엔 별/반딧불(코드).
##
## 산 실루엣은 '조각'(투명 배경)이라 넓은 밭에 여러 개 흩어 mirroring — 티나는 반복 없이
## 자연스러운 산맥. 새 아트가 없으면 옛 seamless 스트립(bg_far/mid/near)으로 자동 폴백.
##

@export var sky_color: Color = Color(0.93, 0.89, 0.78, 1.0)   # 한지 베이지(낮)
@export var tint: Color = Color.WHITE
@export var scale_factor: int = 2
# 각 레이어 motion_scale (0=고정, 1=카메라와 동일). 멀수록 작게.
@export var far_scale: float = 0.15
@export var mid_scale: float = 0.40
@export var near_scale: float = 0.70
# 지평선 y(화면 좌표). 산 실루엣의 밑동이 이 근처에 앉는다.
@export var horizon_y: float = 596.0
# 대기 원근: 먼 산을 하늘색 쪽으로 얼마나 흐릴지 (0=그대로, 1=완전 하늘색).
@export var aerial: float = 0.5
# 구름이 흐르는 속도(px/s, 음수면 왼쪽). 0 이면 정지.
@export var cloud_drift: float = -7.0
# 수묵 산안개 띠 표시 여부.
@export var mist: bool = true
## 원경 산·솔숲을 그릴지. 담 안(마당·곳간·사당) 장면은 false — 하늘과 담만 남는다.
@export var mountains: bool = true
## 흐르는 구름을 그릴지. 실내에 준하는 장면은 false.
@export var clouds: bool = true
# 야간 분위기 자동 판정 임계(하늘 휘도). 이보다 어두우면 별/반딧불 표시. 음수면 끔.
@export var night_luminance: float = 0.55
## 비주얼 세트. 빈 문자열은 기존 공용 산수, "stage1"은 1스테이지 전용 pro 리마스터.
@export var art_set: String = ""

# 신규 PixelLab 수묵 산 실루엣(있으면 이걸 쓰고, 없으면 옛 스트립으로 폴백).
const MTN_FAR := "res://assets/sprites/bg/mtn_far.png"
const MTN_HILL := "res://assets/sprites/bg/mtn_hill.png"
const ART_SETS := {
    "stage1": {
        "far": "res://assets/sprites/bg/stage1/far.png",
        "mid": "res://assets/sprites/bg/stage1/mid.png",
        "near": "res://assets/sprites/bg/stage1/near.png",
    },
}
# 옛 seamless 스트립(폴백).
const BG_FAR := "res://assets/sprites/bg/bg_far.png"
const BG_MID := "res://assets/sprites/bg/bg_mid.png"
const BG_NEAR := "res://assets/sprites/bg/bg_near.png"

# 산맥 밭 폭 — 이 폭마다 반복(넓을수록 반복이 덜 티남).
const FIELD := 2400.0

var _cloud_layer: ParallaxLayer = null
var _mist_layers: Array = []      # [{node, speed}]
var _ambience: Node2D = null


func _ready() -> void:
    _add_sky()
    if clouds:
        _add_clouds()
    # 담 안 마당·곳간·사당처럼 '닫힌 공간'에서는 원경 산·솔숲을 끈다.
    # (기와집 마당 뒤로 산맥이 보이면 장면이 어그러진다 — 2026-08-18 사용자 지적.)
    if mountains:
        var paths := _mountain_paths()
        if ResourceLoader.exists(paths["far"]) and ResourceLoader.exists(paths["mid"]):
            _build_mountains(paths)
        else:
            _build_legacy_strips()
    _add_ambience()


func _process(delta: float) -> void:
    if _cloud_layer and cloud_drift != 0.0:
        _cloud_layer.motion_offset.x += cloud_drift * delta
    # 안개 띠 — 각자 다른 속도로 아주 느리게 흐른다(살아있는 대기감).
    for m in _mist_layers:
        var band: Node2D = m["node"]
        if is_instance_valid(band):
            band.position.x += float(m["speed"]) * delta
            var span: float = float(m["span"])
            if band.position.x <= -span:
                band.position.x += span
            elif band.position.x >= 0.0:
                band.position.x -= span


# ── ① 그라데이션 하늘 ────────────────────────────────────────
func _add_sky() -> void:
    var layer := ParallaxLayer.new()
    layer.motion_scale = Vector2(0, 0)   # 화면 고정
    add_child(layer)
    var grad := Gradient.new()
    # 상단은 하늘색을 살짝 눌러(깊게), 중단 하늘색, 하단 지평선 한지빛.
    grad.set_color(0, sky_color.darkened(0.06))
    grad.add_point(0.5, sky_color)
    var horizon := sky_color.lightened(0.16).lerp(Color(0.96, 0.92, 0.82), 0.34)
    grad.set_color(grad.get_point_count() - 1, horizon)
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
    tr.size = Vector2(8192, 1200)
    tr.position = Vector2(-4096, -300)
    layer.add_child(tr)


# ── ② 떠다니는 구름(코드 드로잉) ─────────────────────────────
func _add_clouds() -> void:
    if cloud_drift == 0.0:
        return
    var layer := ParallaxLayer.new()
    layer.motion_scale = Vector2(0.08, 1.0)
    layer.motion_mirroring = Vector2(1280.0, 0)
    add_child(layer)
    _cloud_layer = layer
    var night := _is_night()
    var col := Color(1.0, 0.98, 0.92, 0.30) if not night else Color(0.80, 0.82, 0.90, 0.20)
    var rng := RandomNumberGenerator.new()
    rng.seed = 20260627
    for i in range(5):
        var cx := rng.randf_range(0.0, 1280.0)
        var cy := rng.randf_range(30.0, 210.0)
        _draw_cloud(layer, Vector2(cx, cy), rng.randf_range(0.8, 1.6), col, rng)


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


# ── ③⑤ 산맥 레이어(신규 PixelLab 수묵 산수 — 깨끗한 단일 타일 무한반복) ──
## 각 이미지는 그 자체로 완성된 수묵 산수(하늘+능선)라, 겹쳐 흩으면 반투명 하늘이
## 사각으로 겹쳐 띠(밴딩)가 생긴다 → 레이어당 '한 장'만 가로 무한반복해 깨끗하게.
func _mountain_paths() -> Dictionary:
    if ART_SETS.has(art_set):
        return ART_SETS[art_set]
    return {"far": MTN_FAR, "mid": MTN_HILL, "near": ""}


func _build_mountains(paths: Dictionary) -> void:
    var far_tex: Texture2D = load(paths["far"])
    var hill_tex: Texture2D = load(paths["mid"])
    # 원경 먼 산맥 — 하늘색으로 흐려(대기 원근) 위쪽 깊이.
    var far_col := tint.lerp(sky_color, aerial)
    far_col.a = 0.48 if art_set == "stage1" else 1.0
    _mountain_layer(far_tex, far_scale, far_col, 1.0, horizon_y + 44.0)
    if mist:
        _add_mist(far_scale + 0.03, horizon_y - 6.0, 0.26, 9.0)
    # 중경 솔숲 — 플레이 지면 바로 뒤에 앉혀 근경감.
    var mid_col := tint.lerp(sky_color, aerial * 0.3)
    mid_col.a = 0.62 if art_set == "stage1" else 1.0
    _mountain_layer(hill_tex, mid_scale, mid_col, 1.0, horizon_y + 120.0)
    if mist:
        _add_mist(mid_scale + 0.04, horizon_y + 84.0, 0.20, 13.0)
    # 1스테이지 리마스터는 중경 재사용 대신 독립 근경을 둔다.
    var near_path := String(paths.get("near", ""))
    if near_path != "" and ResourceLoader.exists(near_path):
        var near_tex: Texture2D = load(near_path)
        var near_col := tint.lerp(sky_color, aerial * 0.08)
        near_col.a = 0.45
        _mountain_layer(near_tex, near_scale, near_col, 1.0, horizon_y + 132.0)


## 한 산맥 레이어: 완성된 수묵 산수 한 장을 가로로 이어붙여 무한반복. base_y = 이미지 밑동 y.
## 인접 복사본을 좌우반전 교대(mirror-tile)로 깔아, 맞닿는 모서리 픽셀이 같아 이음매가 안 보인다.
func _mountain_layer(tex: Texture2D, motion: float, mod_col: Color, s: float, base_y: float) -> void:
    var layer := ParallaxLayer.new()
    layer.motion_scale = Vector2(motion, 1.0)
    var tw := float(tex.get_width()) * s
    var y := base_y - float(tex.get_height()) * s
    # 화면(그리고 여유)을 덮도록 짝수 개 이어붙임 — 반전 교대 주기(2칸)에 맞춰 짝수.
    var cols := int(ceil(FIELD / tw))
    if cols % 2 == 1:
        cols += 1
    layer.motion_mirroring = Vector2(cols * tw, 0)   # 이음매(짝수칸)에서 깨끗이 반복
    add_child(layer)
    for i in range(cols + 1):
        var spr := Sprite2D.new()
        spr.texture = tex
        spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        spr.centered = false
        spr.flip_h = (i % 2 == 1)   # 교대 반전 → 이음매 모서리 일치
        spr.scale = Vector2(s, s)
        spr.modulate = mod_col
        spr.position = Vector2(i * tw, y)
        layer.add_child(spr)


# ── ④⑥ 수묵 산안개 띠 ────────────────────────────────────────
## 가로로 긴 부드러운 안개 띠(위/아래 투명, 가운데 반투명 한지빛). 아주 느리게 흐른다.
func _add_mist(motion: float, y: float, alpha: float, speed: float) -> void:
    var layer := ParallaxLayer.new()
    layer.motion_scale = Vector2(motion, 1.0)
    add_child(layer)
    var span := FIELD
    # 세로 그라데이션(투명→한지빛→투명) 텍스처.
    var grad := Gradient.new()
    var haze := Color(0.97, 0.95, 0.9)
    grad.set_color(0, Color(haze.r, haze.g, haze.b, 0.0))
    grad.add_point(0.5, Color(haze.r, haze.g, haze.b, alpha))
    grad.set_color(grad.get_point_count() - 1, Color(haze.r, haze.g, haze.b, 0.0))
    var gtex := GradientTexture2D.new()
    gtex.gradient = grad
    gtex.fill_from = Vector2(0, 0)
    gtex.fill_to = Vector2(0, 1)
    gtex.width = 8
    gtex.height = 96
    # 밭을 두 폭으로 그려(-span..+span) 스크롤 시 끊김 없이 흐르게.
    var band := Node2D.new()
    layer.add_child(band)
    for k in range(2):
        var tr := TextureRect.new()
        tr.texture = gtex
        tr.stretch_mode = TextureRect.STRETCH_SCALE
        tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
        tr.size = Vector2(span, 84.0)
        tr.position = Vector2(span * k, y - 42.0)
        band.add_child(tr)
    _mist_layers.append({"node": band, "speed": speed, "span": span})


# ── (폴백) 옛 seamless 스트립 배경 ───────────────────────────
func _build_legacy_strips() -> void:
    _add_strip(BG_FAR, far_scale, 0.0, aerial)
    _add_strip(BG_MID, mid_scale, 10.0, aerial * 0.4)
    _add_strip(BG_NEAR, near_scale, 24.0, 0.0)


func _add_strip(path: String, motion: float, extra_y: float, aerial_amt: float) -> void:
    if not ResourceLoader.exists(path):
        return
    var tex: Texture2D = load(path)
    var layer := ParallaxLayer.new()
    layer.motion_scale = Vector2(motion, 1.0)
    var tw := tex.get_width() * scale_factor
    var th := tex.get_height() * scale_factor
    layer.motion_mirroring = Vector2(tw, 0)
    add_child(layer)
    var spr := Sprite2D.new()
    spr.texture = tex
    spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    spr.centered = false
    spr.scale = Vector2(scale_factor, scale_factor)
    spr.modulate = tint.lerp(sky_color, clampf(aerial_amt, 0.0, 1.0)) if aerial_amt > 0.0 else tint
    spr.position = Vector2(0, 720 - th + 40.0 + extra_y)
    layer.add_child(spr)


# ── ⑧ 야간 분위기(별·반딧불) ─────────────────────────────────
func _is_night() -> bool:
    return night_luminance >= 0.0 and sky_color.get_luminance() < night_luminance


func _add_ambience() -> void:
    if not _is_night():
        return
    var layer := ParallaxLayer.new()
    layer.motion_scale = Vector2(0.06, 0.2)
    add_child(layer)
    var root := Node2D.new()
    root.z_index = 2
    layer.add_child(root)
    _ambience = root
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
        var y_hi := 0.0 if starry else 180.0
        var y_lo := 260.0 if starry else 380.0
        dot.position = Vector2(rng.randf_range(0.0, 1280.0), rng.randf_range(y_hi, y_lo))
        root.add_child(dot)
        var lo := rng.randf_range(0.15, 0.4)
        var dur := rng.randf_range(0.8, 2.0)
        dot.modulate.a = rng.randf_range(0.4, 1.0)
        var tw := dot.create_tween().set_loops()
        tw.tween_property(dot, "modulate:a", lo, dur).set_trans(Tween.TRANS_SINE)
        tw.tween_property(dot, "modulate:a", 1.0, dur).set_trans(Tween.TRANS_SINE)
        if not starry:
            var drift := dot.create_tween().set_loops()
            var dx := rng.randf_range(-14, 14)
            var dy := rng.randf_range(-10, 10)
            var ddur := rng.randf_range(2.5, 4.5)
            var base := dot.position
            drift.tween_property(dot, "position", base + Vector2(dx, dy), ddur).set_trans(Tween.TRANS_SINE)
            drift.tween_property(dot, "position", base, ddur).set_trans(Tween.TRANS_SINE)
