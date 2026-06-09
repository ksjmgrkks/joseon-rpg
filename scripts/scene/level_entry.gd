extends Marker2D
class_name LevelEntry
##
## LevelEntry — 씬 안의 명명된 스폰 지점. 노드 name 이 곧 entry 키.
##
## 예: 마을 씬 안에 "Marker2D" 를 두고 name 을 "from_field" / "from_forest" 로.
## SceneManager.change_scene_to(path, &"from_field") 로 들어오면 같은 이름의
## LevelEntry 위치로 그룹 "player" 의 첫 노드가 옮겨진다.
##
## 마커가 없거나 매치 실패 시 SceneManager 가 그냥 씬의 default Player 위치를 둠.
##

func _ready() -> void:
    add_to_group("level_entry")
