extends Area2D
##
## NPC — 플레이어가 가까이 오면 '자동으로' 대화를 시작(상호작용 키 없음).
## 스토리는 진행에 따라 읽히도록 한 번만 자동 재생. (2026-06-12: 상호작용 제거 — 사용자 요청)
##

@export_file("*.json") var dialogue_path: String = "res://assets/dialogue/sample_villager.json"
## SpriteDb 시트 경로 (예: "npc/elder"). 비우면 placeholder 유지.
@export var sheet: String = ""
## 한 번 자동 재생 후 다시 트리거 안 함. (once_flag 지정 시 저장에도 반영)
@export var once_flag: String = ""

var _played: bool = false


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    _setup_visual()


## Sprite2D(placeholder)를 SpriteDb 시트의 AnimatedSprite2D 로 교체.
func _setup_visual() -> void:
    if sheet.is_empty():
        return
    var frames := SpriteDb.frames(sheet)
    if frames == null:
        return
    var ph := get_node_or_null("Sprite2D")
    if ph:
        ph.queue_free()
    var vis := AnimatedSprite2D.new()
    vis.name = "Visual"
    vis.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    vis.sprite_frames = frames
    vis.offset = Vector2(0, -14)   # 32x64, 발 y=62 → 콜리전 중심 보정
    add_child(vis)
    if frames.has_animation("idle"):
        vis.play("idle")


func _on_body_entered(body: Node) -> void:
    if not body.is_in_group("player"):
        return
    if _played:
        return
    if once_flag != "" and Flags.has_flag(once_flag):
        _played = true
        return
    if Dialogue.is_active() or dialogue_path.is_empty():
        return
    _played = true
    if once_flag != "":
        Flags.set_flag(once_flag, true)
    Dialogue.start(dialogue_path)


func _on_body_exited(_body: Node) -> void:
    pass
