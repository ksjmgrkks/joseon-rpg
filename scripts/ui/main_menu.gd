extends Control
##
## 메인 메뉴 — 새로 시작·이어하기(슬롯 선택)·설정·종료.
##

const START_LEVEL_PATH := "res://scenes/levels/Foothills.tscn"   # 스코어어택: 첫 전투 스테이지(스토리/프롤로그 없음)
## 이야기 모드 시작점 — STORY_BIBLE v2 1막 「넋을 달래는 아이」.
## 2026-08-19 사용자 요청으로 **메뉴에서 「이야기」 버튼을 뺐다**(시작 화면 단순화).
## 데이터·씬은 그대로 살아 있으므로, 되살리려면 MainMenu.tscn 에 StoryBtn 을 다시 넣고
## _on_story 를 연결하면 된다(이 경로로 직접 진입도 가능).
const STORY_START_PATH := "res://scenes/levels/Haewon0Prologue.tscn"
const SETTINGS_PATH := "res://scenes/ui/SettingsMenu.tscn"

# 저장 메타의 지역명(SaveManager.AREA_LABELS) → 씬 경로 역매핑 (이어하기 복귀용)
const AREA_SCENES := {
    "마을 어귀": "res://scenes/levels/VillageIntro.tscn",
    "산기슭": "res://scenes/levels/Foothills.tscn",
    "깊은 숲": "res://scenes/levels/ForestDeep.tscn",
    "마을": "res://scenes/levels/Village.tscn",
    "들판": "res://scenes/levels/TestLevel.tscn",
    "숲": "res://scenes/levels/Forest.tscn",
    "산신당 터": "res://scenes/levels/ShrineRuins.tscn",
    "절벽 아레나": "res://scenes/levels/BossArena.tscn",
    "고을 저잣거리": "res://scenes/levels/TownMarket.tscn",
    "관아 동헌": "res://scenes/levels/MagistrateOffice.tscn",
    "폐사지": "res://scenes/levels/RuinedTemple.tscn",
    "신산 산길": "res://scenes/levels/MountainPass.tscn",
    "신단 제단": "res://scenes/levels/SacredAltar.tscn",
    "나루 — 첫 등": "res://scenes/levels/Haewon0Prologue.tscn",
    "나루의 뱃사공": "res://scenes/levels/Haewon1Ferry.tscn",
    "물에 잠긴 저잣거리": "res://scenes/levels/Haewon2Market.tscn",
    "물에 잠긴 강마을": "res://scenes/levels/Haewon3Village.tscn",
    "닫힌 수문": "res://scenes/levels/Haewon4Watergate.tscn",
    "빈 고을": "res://scenes/levels/Haewon5EmptyTown.tscn",
    "그 문, 다시": "res://scenes/levels/Haewon6Yunseul.tscn",
}
const SLOT_PICKER_SCENE := preload("res://scenes/ui/SlotPicker.tscn")
const STAGE_SELECT_SCENE := preload("res://scenes/ui/StageSelect.tscn")

@onready var title_label: Label = $Margin/VBox/Title
@onready var subtitle_label: Label = $Margin/VBox/Subtitle
@onready var new_btn: Button = $Margin/VBox/Buttons/NewBtn
@onready var continue_btn: Button = $Margin/VBox/Buttons/ContinueBtn
@onready var settings_btn: Button = $Margin/VBox/Buttons/SettingsBtn
@onready var quit_btn: Button = $Margin/VBox/Buttons/QuitBtn

var _picker: Control = null
var _stage_select: Control = null


func _ready() -> void:
    _apply_locale()
    # 「해원」 타이틀(텍스트) 표시. 옛 그래픽 로고(TitleLogo)는 '귀창록' 잔재라 숨김 유지.
    if title_label:    title_label.visible = true
    if subtitle_label: subtitle_label.visible = true
    var logo := get_node_or_null("TitleLogo")
    if logo:
        logo.visible = false
    Locale.locale_changed.connect(_on_locale_changed)
    new_btn.pressed.connect(_on_new)
    continue_btn.pressed.connect(_on_continue)
    settings_btn.pressed.connect(_on_settings)
    quit_btn.pressed.connect(_on_quit)
    # 슬롯 1~3 중 하나라도 저장이 있어야 '이어하기' 활성화
    continue_btn.disabled = not _any_save_exists()
    new_btn.call_deferred("grab_focus")   # 키보드로 바로 메뉴 조작


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
    # 새로 시작 — 완성된 전투체인 1~3스테이지 중 하나를 고르는 선택 화면을 연다.
    if _stage_select != null:
        return
    _stage_select = STAGE_SELECT_SCENE.instantiate()
    _stage_select.stage_chosen.connect(_on_stage_picked)
    _stage_select.cancelled.connect(_close_stage_select)
    add_child(_stage_select)


func _on_stage_picked(scene_path: String) -> void:
    _fresh_run()
    ScoreManager.start_run()
    _close_stage_select()
    SceneManager.change_scene(scene_path)


func _close_stage_select() -> void:
    if _stage_select:
        _stage_select.queue_free()
        _stage_select = null


## 이야기 — 같은 초기화를 하고 1막부터. 진혼의 대가(기억)는 온전한 상태에서 출발한다.
func _on_story() -> void:
    _fresh_run()
    SceneManager.change_scene(STORY_START_PATH)


# 새 판 공통 초기화 (스코어어택·이야기 양쪽이 같은 상태에서 출발)
func _fresh_run() -> void:
    Flags.clear()
    Inventory.clear()
    if Equipment: Equipment.clear()
    PlayerStats.reset()
    if SkillManager: SkillManager.reset_cooldowns()
    if MemoryLedger: MemoryLedger.reset()   # 「해원」: 기억은 온전한 상태에서 시작


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
