extends Area2D
class_name AutoCutscene
##
## 플레이어가 밟으면 전용 회상 씬으로 컷 전환했다가 같은 전투/탐색 씬으로 복귀하는 트리거.
## 게이트(전투)가 없어 clear_cutscene 을 못 쓰는 굽이의 '위치 기반 회상'용
## (예: 5굽이 빈집 — 윤슬을 잃던 밤). once_flag 로 한 번만 발동.
##
## SceneManager.play_cutscene 가 '돌아올 씬+entry'를 기억하므로, 컷이 끝나면 이 씬의
## return_entry(기본 from_recall) 위치로 되돌아온다.
##

@export var cutscene_path: String = ""
@export var return_entry: String = "from_recall"
@export var once_flag: String = ""


func _ready() -> void:
    monitoring = true
    body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
    if not body.is_in_group("player"):
        return
    if cutscene_path.is_empty() or SceneManager == null or not SceneManager.transitions_enabled:
        return
    if Dialogue and Dialogue.is_active():
        return
    if once_flag != "" and Flags.has_flag(once_flag):
        return
    if once_flag != "":
        Flags.set_flag(once_flag, true)
    var ret := ""
    if get_tree().current_scene != null:
        ret = get_tree().current_scene.scene_file_path
    SceneManager.play_cutscene(cutscene_path, ret, StringName(return_entry))
