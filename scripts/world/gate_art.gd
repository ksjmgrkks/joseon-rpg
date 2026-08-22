extends RefCounted
class_name GateArt
## 금줄 경계석 공용 비주얼. 봉인과 출구가 같은 구조의 다른 상태를 공유한다.

const SHEET := "res://assets/sprites/fx/gate_geumjul_release.png"
const FRAME_SIZE := Vector2i(192, 208)
const FRAME_COUNT := 6
const RELEASE_FPS := 9.0


static func make_sprite(opened: bool = false) -> AnimatedSprite2D:
    var sprite := AnimatedSprite2D.new()
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    if not ResourceLoader.exists(SHEET):
        return sprite
    var texture: Texture2D = load(SHEET)
    var frames := SpriteFrames.new()
    frames.remove_animation("default")
    frames.add_animation("closed")
    frames.set_animation_loop("closed", true)
    frames.add_frame("closed", _atlas_frame(texture, 0))
    frames.add_animation("release")
    frames.set_animation_loop("release", false)
    frames.set_animation_speed("release", RELEASE_FPS)
    for i in FRAME_COUNT:
        frames.add_frame("release", _atlas_frame(texture, i))
    frames.add_animation("open")
    frames.set_animation_loop("open", true)
    frames.add_frame("open", _atlas_frame(texture, FRAME_COUNT - 1))
    sprite.sprite_frames = frames
    sprite.animation = "open" if opened else "closed"
    return sprite


static func _atlas_frame(texture: Texture2D, index: int) -> AtlasTexture:
    var atlas := AtlasTexture.new()
    atlas.atlas = texture
    atlas.region = Rect2(index * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
    return atlas
