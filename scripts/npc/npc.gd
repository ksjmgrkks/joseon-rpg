extends Area2D
##
## NPC 골격 — 플레이어가 가까이 와서 interact 누르면 대화 시작.
## 시각 스프라이트는 placeholder. 표시 텍스트(이름 패널·인터랙트 힌트)는 추후.
##

@export_file("*.json") var dialogue_path: String = "res://assets/dialogue/sample_villager.json"
## SpriteDb 시트 경로 (예: "npc/elder"). 비우면 placeholder 유지.
@export var sheet: String = ""

var _player_in_range: bool = false


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


func _process(_delta: float) -> void:
    if not _player_in_range:
        return
    if Dialogue.is_active():
        return
    if Input.is_action_just_pressed("interact"):
        Dialogue.start(dialogue_path)


func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        _player_in_range = true


func _on_body_exited(body: Node) -> void:
    if body.is_in_group("player"):
        _player_in_range = false
