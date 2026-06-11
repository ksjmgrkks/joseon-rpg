extends ParallaxBackground
class_name ParallaxBackdrop
##
## 수묵 산수 패럴랙스 배경 — bg_far/mid/near 3레이어를 코드로 구성.
## 각 레벨 루트에 인스턴스만 하면 됨. 하늘은 sky_color 단색 + 3겹 시차.
##
## bg PNG 는 640x360, 정수배(2x)로 깔아 1280x720 을 채우고 가로 무한 반복(motion_mirroring).
## 레벨마다 톤이 다르도록 sky_color / tint 조절 가능.
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

const BG_FAR := "res://assets/sprites/bg/bg_far.png"
const BG_MID := "res://assets/sprites/bg/bg_mid.png"
const BG_NEAR := "res://assets/sprites/bg/bg_near.png"


func _ready() -> void:
    # 하늘 단색 — ParallaxBackground 뒤에 깔리도록 CanvasLayer 따로 두지 않고
    # 가장 먼 레이어에 큰 ColorRect 를 곱한다.
    _add_sky()
    _add_layer(BG_FAR, far_scale, 0.0)
    _add_layer(BG_MID, mid_scale, 10.0)
    _add_layer(BG_NEAR, near_scale, 24.0)


func _add_sky() -> void:
    var layer := ParallaxLayer.new()
    layer.motion_scale = Vector2(0, 0)
    add_child(layer)
    var rect := ColorRect.new()
    rect.color = sky_color
    rect.size = Vector2(4096, 2048)
    rect.position = Vector2(-2048, -1024)
    layer.add_child(rect)


func _add_layer(path: String, motion: float, extra_y: float) -> void:
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
    spr.modulate = tint
    # 화면 하단 정렬: 720 뷰포트 기준 배경 바닥을 살짝 아래로
    spr.position = Vector2(0, 720 - th + y_offset + extra_y)
    layer.add_child(spr)
