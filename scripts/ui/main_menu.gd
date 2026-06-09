extends Control
##
## 메인 메뉴 — 새로 시작·이어하기(슬롯 선택)·설정·종료.
##

const START_LEVEL_PATH := "res://scenes/levels/Village.tscn"
const SETTINGS_PATH := "res://scenes/ui/SettingsMenu.tscn"
const SLOT_PICKER_SCENE := preload("res://scenes/ui/SlotPicker.tscn")

@onready var title_label: Label = $Margin/VBox/Title
@onready var subtitle_label: Label = $Margin/VBox/Subtitle
@onready var new_btn: Button = $Margin/VBox/Buttons/NewBtn
@onready var continue_btn: Button = $Margin/VBox/Buttons/ContinueBtn
@onready var settings_btn: Button = $Margin/VBox/Buttons/SettingsBtn
@onready var quit_btn: Button = $Margin/VBox/Buttons/QuitBtn

var _picker: Control = null


func _ready() -> void:
    _apply_locale()
    Locale.locale_changed.connect(_on_locale_changed)
    new_btn.pressed.connect(_on_new)
    continue_btn.pressed.connect(_on_continue)
    settings_btn.pressed.connect(_on_settings)
    quit_btn.pressed.connect(_on_quit)
    # 슬롯 1~3 중 하나라도 저장이 있어야 '이어하기' 활성화
    continue_btn.disabled = not _any_save_exists()


func _apply_locale() -> void:
    if title_label:    title_label.text    = Locale.t("menu.title")
    if subtitle_label: subtitle_label.text = Locale.t("menu.subtitle")
    if new_btn:        new_btn.text        = Locale.t("menu.new")
    if continue_btn:   continue_btn.text   = Locale.t("menu.continue")
    if settings_btn:   settings_btn.text   = Locale.t("menu.settings")
    if quit_btn:       quit_btn.text       = Locale.t("menu.quit")


func _on_locale_changed(_locale: String) -> void:
    _apply_locale()


func _any_save_exists() -> bool:
    for s in range(1, 4):
        if SaveManager.has_save(s):
            return true
    return false


func _on_new() -> void:
    # 새로 시작 — 진행 상태 초기화 후 시작 마을(Village)로
    Flags.clear()
    Inventory.clear()
    if Equipment: Equipment.clear()
    PlayerStats.reset()
    SceneManager.change_scene(START_LEVEL_PATH)


func _on_continue() -> void:
    if _picker != null:
        return
    _picker = SLOT_PICKER_SCENE.instantiate()
    _picker.mode = "load"
    _picker.slot_chosen.connect(_on_slot_load)
    _picker.cancelled.connect(_close_picker)
    add_child(_picker)


func _on_slot_load(slot: int) -> void:
    if not SaveManager.has_save(slot):
        return
    SaveManager.load(slot)
    _close_picker()
    SceneManager.change_scene(START_LEVEL_PATH)


func _close_picker() -> void:
    if _picker:
        _picker.queue_free()
        _picker = null


func _on_settings() -> void:
    SceneManager.change_scene(SETTINGS_PATH)


func _on_quit() -> void:
    get_tree().quit()
