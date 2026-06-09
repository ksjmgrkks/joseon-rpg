extends CanvasLayer
##
## 일시정지 메뉴 — 'pause' 액션(Esc)으로 토글. 슬롯 1/2/3 중 선택 저장.
## process_mode = ALWAYS — 일시정지 중에도 동작.
##

const SLOT_PICKER_SCENE := preload("res://scenes/ui/SlotPicker.tscn")

@onready var panel: PanelContainer = $Panel
@onready var dim: ColorRect = $Dim
@onready var resume_btn: Button = $Panel/Margin/VBox/ResumeBtn
@onready var save_btn: Button = $Panel/Margin/VBox/SaveBtn
@onready var quit_btn: Button = $Panel/Margin/VBox/QuitBtn
@onready var status_label: Label = $Panel/Margin/VBox/StatusLabel

var _picker: Control = null


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
    if _picker != null:
        return   # 슬롯 선택창이 떠 있으면 Esc 는 picker 가 처리
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
    if _picker != null:
        return
    _picker = SLOT_PICKER_SCENE.instantiate()
    _picker.mode = "save"
    _picker.slot_chosen.connect(_on_slot_save)
    _picker.cancelled.connect(_close_picker)
    add_child(_picker)


func _on_slot_save(slot: int) -> void:
    var ok := SaveManager.save(slot)
    _close_picker()
    status_label.text = ("슬롯 %d에 저장됨" % slot) if ok else "저장 실패"


func _close_picker() -> void:
    if _picker:
        _picker.queue_free()
        _picker = null


func _on_quit_pressed() -> void:
    get_tree().quit()
