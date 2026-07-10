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

const RAIN_TEX := "res://assets/sprites/weather/rain.png"
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
func _build_rain() -> void:
    _rain = CPUParticles2D.new()
    _rain.amount = 150
    _rain.lifetime = 1.2
    _rain.preprocess = 1.2          # 시작하자마자 화면 가득 차 있게
    _rain.position = Vector2(VIEW_W * 0.5, -40.0)
    _rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
    _rain.emission_rect_extents = Vector2(VIEW_W * 0.62, 4.0)
    _rain.direction = Vector2(0.18, 1.0)
    _rain.spread = 3.0
    _rain.gravity = Vector2(0, 260)
    _rain.initial_velocity_min = 680.0
    _rain.initial_velocity_max = 820.0
    _rain.angle_min = 8.0
    _rain.angle_max = 12.0
    _rain.scale_amount_min = 0.9
    _rain.scale_amount_max = 1.5
    _rain.color = Color(0.78, 0.84, 0.94, 0.5)
    _rain.texture = _rain_texture()
    add_child(_rain)


func _rain_texture() -> Texture2D:
    if ResourceLoader.exists(RAIN_TEX):
        return load(RAIN_TEX)
    # 폴백 — 세로 그라데이션 물줄기(에셋 없어도 비는 온다)
    var img := Image.create(2, 16, false, Image.FORMAT_RGBA8)
    for y in range(16):
        var a := 0.12 + 0.72 * (float(y) / 15.0)
        img.set_pixel(0, y, Color(1, 1, 1, a))
        img.set_pixel(1, y, Color(1, 1, 1, a * 0.6))
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
