extends CanvasLayer
##
## Weather autoload — 전역 궂은 날씨(비 + 낮게 흐르는 먹구름). 모든 씬 위에 '화면 공간'으로 깔린다.
##
## 방향: 밤낮 순환은 제거(TimeManager 정지)하고, 화면 전체는 WorldTint 가 침잠한 회청색으로
## 어둡게 눌러 '수문을 닫던 그 날'의 흐리고 비 오는 톤을 낸다. 여기선 비 파티클과 먹구름 띠만 담당.
##
## layer=5 — 월드(0) 위, HUD(8)·대화(10) 아래. CanvasModulate(WorldTint)는 기본 캔버스만
## 물들이므로 여기 비/구름은 제 색을 유지한다(어둠에 묻히지 않음).
##
## 에셋은 PixelLab 로 만든 rain.png / clouds.png 를 쓰되, 없으면 코드 폴백으로도 동작한다.
##

const CLOUD_TEX := "res://assets/sprites/weather/clouds.png"
const VIEW_W := 1280.0
const VIEW_H := 720.0

var _rain: CPUParticles2D
var _cloud: TextureRect
var _cloud_w: float = 320.0
var _cloud_speed: float = 9.0


func _ready() -> void:
    layer = 5
    _build_clouds()
    _build_rain()


# ── 비 ────────────────────────────────────────────────
## 기울기(수직에서 오른쪽으로 벗어난 각). 물줄기 텍스처와 낙하 방향을 같은 각으로 맞춰
## 빗줄기가 '제 진행 방향으로 곧게' 흐르게 한다. (안 맞으면 빗줄기가 옆으로 눕는 어색함)
const RAIN_TILT_DEG := 9.0

func _build_rain() -> void:
    _rain = CPUParticles2D.new()
    _rain.amount = 230
    _rain.lifetime = 0.8            # 화면 세로를 빠르게 훑고 사라짐(고속 낙하)
    _rain.preprocess = 0.8          # 시작하자마자 화면 가득 차 있게
    _rain.position = Vector2(VIEW_W * 0.5, -80.0)
    _rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
    _rain.emission_rect_extents = Vector2(VIEW_W * 0.72, 6.0)
    # 낙하 방향과 빗줄기 기울기를 동일 각으로 — 곧게 떨어지는 비.
    var tilt := deg_to_rad(RAIN_TILT_DEG)
    _rain.direction = Vector2(sin(tilt), cos(tilt))
    _rain.spread = 1.5              # 거의 평행(부챗살처럼 퍼지지 않게)
    _rain.gravity = Vector2.ZERO    # 등속 낙하 — 가속으로 속도가 제각각이 되지 않게
    _rain.initial_velocity_min = 980.0
    _rain.initial_velocity_max = 1180.0
    _rain.angle_min = RAIN_TILT_DEG
    _rain.angle_max = RAIN_TILT_DEG
    _rain.scale_amount_min = 0.7    # 원근감 — 가는 빗줄기와 굵은 빗줄기 섞임
    _rain.scale_amount_max = 1.25
    _rain.color = Color(0.82, 0.88, 0.98, 0.5)
    _rain.texture = _rain_texture()
    add_child(_rain)


## 빗방울 하나 = 한 줄기. 위는 흐리고 아래로 갈수록 진한 세로 물줄기(2×26).
## (기존 rain.png 은 여러 줄기가 박힌 '타일' 이라 파티클 텍스처로 쓰면
##  빗방울 하나가 슬래시 뭉치로 보여 매우 어색했음 → 코드 단일 줄기로 대체)
func _rain_texture() -> Texture2D:
    var h := 26
    var img := Image.create(2, h, false, Image.FORMAT_RGBA8)
    for y in range(h):
        var t := float(y) / float(h - 1)
        var a := 0.06 + 0.80 * t          # 머리는 옅게, 꼬리는 진하게
        img.set_pixel(0, y, Color(1, 1, 1, a))
        img.set_pixel(1, y, Color(1, 1, 1, a * 0.55))
    return ImageTexture.create_from_image(img)


# ── 먹구름 띠(화면 상단에서 천천히 흐른다) ──────────────
func _build_clouds() -> void:
    if not ResourceLoader.exists(CLOUD_TEX):
        return
    var tex: Texture2D = load(CLOUD_TEX)
    _cloud_w = float(tex.get_width())
    _cloud = TextureRect.new()
    _cloud.texture = tex
    _cloud.stretch_mode = TextureRect.STRETCH_TILE
    _cloud.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
    _cloud.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _cloud.modulate = Color(1, 1, 1, 0.5)
    _cloud.size = Vector2(VIEW_W + _cloud_w * 2.0, float(tex.get_height()))
    _cloud.position = Vector2(-_cloud_w, -16.0)
    add_child(_cloud)


func _process(delta: float) -> void:
    if _cloud:
        _cloud.position.x -= _cloud_speed * delta
        if _cloud.position.x <= -_cloud_w * 2.0:
            _cloud.position.x += _cloud_w
