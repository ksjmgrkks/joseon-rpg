extends CanvasLayer
##
## 일시정지 메뉴 — 'pause' 액션(Esc)으로 토글. 슬롯 1에 저장 기능 포함.
## process_mode = ALWAYS — 일시정지 중에도 동작.
##

@onready var panel: PanelContainer = $Panel
@onready var dim: ColorRect = $Dim
@onready var resume_btn: Button = $Panel/Margin/VBox/ResumeBtn
@onready var save_btn: Button = $Panel/Margin/VBox/SaveBtn
@onready var quit_btn: Button = $Panel/Margin/VBox/QuitBtn
@onready var status_label: Label = $Panel/Margin/VBox/StatusLabel


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    panel.visible = false
    dim.visible = false
    resume_btn.pressed.connect(close)
    save_btn.pressed.connect(_on_save_pressed)
    quit_btn.pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed("pause"):
        return
    if panel.visible:
        close()
    else:
        open()
    get_viewport().set_input_as_handled()


func open() -> void:
    panel.visible = true
    dim.visible = true
    status_label.text = ""
    get_tree().paused = true


func close() -> void:
    panel.visible = false
    dim.visible = false
    get_tree().paused = false


func _on_save_pressed() -> void:
    var ok := SaveManager.save(1)
    status_label.text = "슬롯 1에 저장됨" if ok else "저장 실패"


func _on_quit_pressed() -> void:
    get_tree().quit()
