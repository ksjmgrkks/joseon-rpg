extends CanvasLayer
##
## Game Over 오버레이 — Player.died 시 show_screen() 호출.
## process_mode = ALWAYS, 게임 멈추고 두 가지 선택: 이어하기(슬롯 1)/메인 메뉴.
##

const MAIN_MENU_PATH := "res://scenes/ui/MainMenu.tscn"

@onready var panel: PanelContainer = $Panel
@onready var dim: ColorRect = $Dim
@onready var continue_btn: Button = $Panel/Margin/VBox/ContinueBtn
@onready var menu_btn: Button = $Panel/Margin/VBox/MenuBtn


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    panel.visible = false
    dim.visible = false
    continue_btn.pressed.connect(_on_continue)
    menu_btn.pressed.connect(_on_menu)


func show_screen() -> void:
    # 자동 저장(슬롯 0)에서 이어하기 — 스테이지 진입마다 체크포인트가 찍힌다.
    continue_btn.disabled = not SaveManager.has_save(0)
    panel.visible = true
    dim.visible = true
    get_tree().paused = true
    # 키보드 포커스 — 이어하기 가능하면 거기, 아니면 메뉴
    if continue_btn.disabled:
        menu_btn.call_deferred("grab_focus")
    else:
        continue_btn.call_deferred("grab_focus")


func hide_screen() -> void:
    panel.visible = false
    dim.visible = false
    get_tree().paused = false


func _on_continue() -> void:
    if not SaveManager.has_save(0):
        return
    SaveManager.load(0)
    hide_screen()
    get_tree().reload_current_scene()


func _on_menu() -> void:
    hide_screen()
    SceneManager.change_scene(MAIN_MENU_PATH)
