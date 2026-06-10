extends AnimatedSprite2D
class_name CharacterVisual
##
## 범용 캐릭터 비주얼 — SpriteDb 시트를 붙이고 idle 재생.
## NPC·적 placeholder Sprite2D 를 이 노드로 교체해 쓴다.
##
## sheet 예: "npc/elder", "enemies/goblin", "protagonist"
## foot_offset: 프레임 발바닥(y)과 캔버스 중심의 차 — 노드 원점 기준 발 위치 보정.
##   기본 규격(32x64, 발 y=62, 콜리전 반높이 16)이면 -14.
##

@export var sheet: String = ""
@export var foot_offset: float = -14.0


func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    if sheet.is_empty():
        return
    var sf := SpriteDb.frames(sheet)
    if sf == null:
        push_warning("[Visual] 시트 없음: %s (placeholder 유지)" % sheet)
        return
    sprite_frames = sf
    offset = Vector2(0, foot_offset)
    play_safe("idle")


## 없는 애니면 idle 로 폴백. 같은 애니 재요청은 무시(프레임 리셋 방지).
func play_safe(anim_name: String) -> void:
    if sprite_frames == null:
        return
    var target := anim_name
    if not sprite_frames.has_animation(target):
        target = "idle"
        if not sprite_frames.has_animation(target):
            return
    if animation == target and is_playing():
        return
    play(target)
