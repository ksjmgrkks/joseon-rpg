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
@export var sprite_scale: float = 1.0   ## 원본 프레임이 목표 화면 크기보다 클 때 축소용 (foot_offset 은 이미 이 스케일 반영값이어야 함)


func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    if sheet.is_empty():
        return
    set_sheet(sheet, sprite_scale, foot_offset)


## 시트를 다른 것으로 통째로 교체(예: 위장→정체 드러남처럼 형태 자체가 바뀌는 경우).
## 재생 중이던 애니 이름을 그대로 유지해서 이어 재생을 시도한다(없으면 idle 폴백).
func set_sheet(new_sheet: String, new_scale: float = 1.0, new_offset: float = -14.0) -> void:
    var sf := SpriteDb.frames(new_sheet)
    if sf == null:
        push_warning("[Visual] 시트 없음: %s (이전 시트 유지)" % new_sheet)
        return
    var keep_anim := animation
    sheet = new_sheet
    sprite_scale = new_scale
    foot_offset = new_offset
    sprite_frames = sf
    offset = Vector2(0, foot_offset)
    scale = Vector2(sprite_scale, sprite_scale)
    play_safe(keep_anim if keep_anim != "" else "idle")


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
