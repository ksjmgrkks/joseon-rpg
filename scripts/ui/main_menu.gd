extends Control
##
## 메인 메뉴 — 새로 시작·이어하기(슬롯 선택)·설정·종료.
##

const START_LEVEL_PATH := "res://scenes/levels/Village.tscn"
const PROLOGUE_PATH := "res://scenes/ui/Prologue.tscn"
const SETTINGS_PATH := "res://scenes/ui/SettingsMenu.tscn"

# 저장 메타의 지역명(SaveManager.AREA_LABELS) → 씬 경로 역매핑 (이어하기 복귀용)
const AREA_SCENES := {
    "마을": "res://scenes/levels/Village.tscn",
    "들판": "res://scenes/levels/TestLevel.tscn",
    "숲": "res://scenes/levels/Forest.tscn",
    "산신당 터": "res://scenes/levels/ShrineRuins.tscn",
    "절벽 아레나": "res://scenes/levels/BossArena.tscn",
}
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
    if SaveManager.has_save(0):    # autosave
        return true
    for s in range(1, 4):
        if SaveManager.has_save(s):
            return true
    return false


func _on_new() -> void:
    # 새로 시작 — 진행 상태 초기화 후 프롤로그(서사 도입) → 마을
    Flags.clear()
    Inventory.clear()
    if Equipment: Equipment.clear()
    PlayerStats.reset()
    if SkillManager: SkillManager.reset_cooldowns()
    SceneManager.change_scene(PROLOGUE_PATH)


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
    # 저장된 지역으로 복귀 (메타의 area 라벨 → 씬). 매칭 실패 시 마을로 폴백.
    var info := SaveManager.get_slot_info(slot)
    var dest := String(AREA_SCENES.get(String(info.get("area", "")), START_LEVEL_PATH))
    SaveManager.load(slot)
    _close_picker()
    SceneManager.change_scene(dest)


func _close_picker() -> void:
    if _picker:
        _picker.queue_free()
        _picker = null


func _on_settings() -> void:
    SceneManager.change_scene(SETTINGS_PATH)


func _on_quit() -> void:
    get_tree().quit()
