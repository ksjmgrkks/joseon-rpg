extends Control
##
## 클리어 화면 — 마지막 전투 스테이지를 끝내면 표시. (스토리 엔딩 대체)
##

const FIRST_STAGE := "res://scenes/levels/Foothills.tscn"
const MENU := "res://scenes/ui/MainMenu.tscn"


func _ready() -> void:
    # 금빛 먹획 타이틀 — 단청 황 + 먹 외곽
    var title: Label = $Margin/VBox/Title
    title.add_theme_color_override("font_color", Color(0.85, 0.72, 0.42))
    title.add_theme_color_override("font_outline_color", Color(0.102, 0.086, 0.071, 0.9))
    title.add_theme_constant_override("outline_size", 4)
    title.add_theme_font_size_override("font_size", 28)
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
