extends Control
##
## 메인 메뉴 — 게임 시작·이어하기·설정·종료.
##

const START_LEVEL_PATH := "res://scenes/levels/Village.tscn"
const SETTINGS_PATH := "res://scenes/ui/SettingsMenu.tscn"

@onready var new_btn: Button = $Margin/VBox/Buttons/NewBtn
@onready var continue_btn: Button = $Margin/VBox/Buttons/ContinueBtn
@onready var settings_btn: Button = $Margin/VBox/Buttons/SettingsBtn
@onready var quit_btn: Button = $Margin/VBox/Buttons/QuitBtn


func _ready() -> void:
    new_btn.pressed.connect(_on_new)
    continue_btn.pressed.connect(_on_continue)
    settings_btn.pressed.connect(_on_settings)
    quit_btn.pressed.connect(_on_quit)
    # 슬롯 1에 저장본 없으면 '이어하기' 비활성화
    continue_btn.disabled = not SaveManager.has_save(1)


func _on_new() -> void:
    # 새로 시작 — 진행 상태 초기화 후 시작 마을(Village)로
    Flags.clear()
    Inventory.clear()
    SceneManager.change_scene(START_LEVEL_PATH)


func _on_continue() -> void:
    if not SaveManager.has_save(1):
        return
    SaveManager.load(1)
    SceneManager.change_scene(START_LEVEL_PATH)


func _on_settings() -> void:
    SceneManager.change_scene(SETTINGS_PATH)


func _on_quit() -> void:
    get_tree().quit()
