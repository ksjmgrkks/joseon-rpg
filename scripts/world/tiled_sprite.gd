extends Sprite2D
class_name TiledSprite
##
## 32x32 타일 텍스처를 region+repeat 로 넓게 깐다 (지면·돌담 등 시각 표면).
## 콜리전은 별도 StaticBody 가 담당 — 이 노드는 순수 시각.
##
## centered=false 라 position 이 좌상단. width/height 픽셀로 채움.
##

@export var tex_path: String = ""
@export var width: int = 256
@export var height: int = 32


func _ready() -> void:
    if tex_path.is_empty() or not ResourceLoader.exists(tex_path):
        return
    texture = load(tex_path)
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
    centered = false
    region_enabled = true
    region_rect = Rect2(0, 0, width, height)
