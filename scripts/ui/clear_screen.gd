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
    # 스코어 어택 — 클리어 결과 집계(점수+클리어 시간 최고기록) 후 요약 표시.
    var res := ScoreManager.register_result(true)
    _show_summary(res)


func _show_summary(res: Dictionary) -> void:
    var vbox := $Margin/VBox as VBoxContainer
    var summary := Label.new()
    summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    summary.add_theme_font_size_override("font_size", 18)
    summary.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
    var lines := "점수 %d   ·   시간 %s" % [ScoreManager.score, ScoreManager.format_time(ScoreManager.run_time)]
    if res.get("new_best_score", false):
        lines += "\n★ 최고 점수 갱신 %d" % int(res.get("best_score", 0))
    else:
        lines += "\n최고 점수 %d" % int(res.get("best_score", 0))
    if res.get("new_best_time", false):
        lines += "\n★ 최단 클리어 %s" % ScoreManager.format_time(float(res.get("best_time", 0.0)))
    summary.text = lines
    vbox.add_child(summary)
    vbox.move_child(summary, 1)   # 타이틀 바로 아래


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
