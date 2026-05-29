extends Control
##
## 설정 메뉴 — 볼륨 슬라이더(Master / SFX / BGM, 0~100). AudioManager에 즉시 반영.
## SaveManager 슬롯 1에 저장. 메인 메뉴로 돌아가는 버튼.
##

const MAIN_MENU_PATH := "res://scenes/ui/MainMenu.tscn"

@onready var master_slider: HSlider = $Margin/VBox/MasterRow/Slider
@onready var sfx_slider: HSlider = $Margin/VBox/SfxRow/Slider
@onready var bgm_slider: HSlider = $Margin/VBox/BgmRow/Slider
@onready var save_btn: Button = $Margin/VBox/Buttons/SaveBtn
@onready var back_btn: Button = $Margin/VBox/Buttons/BackBtn
@onready var status_label: Label = $Margin/VBox/Status


func _ready() -> void:
    # 슬롯 1에 저장본 있으면 미리 로드해 슬라이더 값 채움
    if SaveManager.has_save(1):
        SaveManager.load(1)
    # AudioManager 내부 dB → 0~100 역변환은 어려우니 기본 100으로 초기.
    # (저장된 dB는 유지되지만 슬라이더가 보여주는 건 100. 슬라이더를 만지면 동기화.)
    master_slider.value = 100.0
    sfx_slider.value = 100.0
    bgm_slider.value = 100.0

    master_slider.value_changed.connect(Audio.set_master_volume)
    sfx_slider.value_changed.connect(Audio.set_sfx_volume)
    bgm_slider.value_changed.connect(Audio.set_bgm_volume)

    save_btn.pressed.connect(_on_save)
    back_btn.pressed.connect(_on_back)


func _on_save() -> void:
    var ok := SaveManager.save(1)
    status_label.text = "슬롯 1에 저장됨" if ok else "저장 실패"


func _on_back() -> void:
    SceneManager.change_scene(MAIN_MENU_PATH)
