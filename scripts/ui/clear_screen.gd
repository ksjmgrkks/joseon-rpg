extends Control
##
## 클리어 화면 — 마지막 전투 스테이지를 끝내면 표시. (스토리 엔딩 대체)
##

const FIRST_STAGE := "res://scenes/levels/Foothills.tscn"
const MENU := "res://scenes/ui/MainMenu.tscn"


func _ready() -> void:
    $Margin/VBox/RetryBtn.pressed.connect(_on_retry)
    $Margin/VBox/MenuBtn.pressed.connect(_on_menu)
    $Margin/VBox/RetryBtn.call_deferred("grab_focus")


func _reset() -> void:
    Flags.clear()
    Inventory.clear()
    if Equipment:
        Equipment.clear()
    PlayerStats.reset()
    if SkillManager:
        SkillManager.reset_cooldowns()


func _on_retry() -> void:
    _reset()
    SceneManager.change_scene(FIRST_STAGE)


func _on_menu() -> void:
    SceneManager.change_scene(MENU)
