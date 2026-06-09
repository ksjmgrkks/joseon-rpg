extends Area2D
class_name LevelExit
##
## LevelExit — 플레이어가 닿으면 SceneManager로 다음 씬을 부른다.
##
## 사용:
##   1. Area2D 노드에 이 스크립트 붙이기 + CollisionShape2D 추가 (예: 32x96 rect).
##   2. Inspector에서 target_scene(.tscn 경로) · target_entry(목적 씬의 LevelEntry name) 설정.
##   3. 닿으면 SceneManager.change_scene_to(target_scene, target_entry) 호출.
##
## 한 번 발동되면 _used=true 로 잠궈 같은 발동 막음.
##

@export_file("*.tscn") var target_scene: String = ""
@export var target_entry: StringName = &"default"
@export var fade_seconds: float = 0.4

var _used: bool = false


func _ready() -> void:
    monitoring = true
    body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
    if _used:
        return
    if not body.is_in_group("player"):
        return
    if target_scene.is_empty():
        push_warning("[LevelExit] target_scene is empty on %s" % name)
        return
    _used = true
    SceneManager.change_scene_to(target_scene, target_entry, fade_seconds)
