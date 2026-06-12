extends Control
##
## 설정 메뉴 — 볼륨 슬라이더(Master/SFX/BGM) + 키 설정(리바인딩).
##
## 키 설정: [변경] 클릭 → 다음 키 입력을 그 액션에 배정 (InputConfig 가 저장/충돌 처리).
## Esc 로 입력 대기 취소.
##

const MAIN_MENU_PATH := "res://scenes/ui/MainMenu.tscn"

@onready var master_slider: HSlider = $Margin/VBox/MasterRow/Slider
@onready var sfx_slider: HSlider = $Margin/VBox/SfxRow/Slider
@onready var bgm_slider: HSlider = $Margin/VBox/BgmRow/Slider
@onready var save_btn: Button = $Margin/VBox/Buttons/SaveBtn
@onready var back_btn: Button = $Margin/VBox/Buttons/BackBtn
@onready var status_label: Label = $Margin/VBox/Status
@onready var vbox: VBoxContainer = $Margin/VBox

var _listening_action: String = ""
var _key_buttons: Dictionary = {}   # action -> Button


func _ready() -> void:
    if SaveManager.has_save(1):
        SaveManager.load(1)
    master_slider.value = 100.0
    sfx_slider.value = 100.0
    bgm_slider.value = 100.0
    master_slider.value_changed.connect(Audio.set_master_volume)
    sfx_slider.value_changed.connect(Audio.set_sfx_volume)
    bgm_slider.value_changed.connect(Audio.set_bgm_volume)
    save_btn.pressed.connect(_on_save)
    back_btn.pressed.connect(_on_back)
    _build_keys_section()


## ── 키 설정 섹션 (코드 생성) ─────────────────────────────────
func _build_keys_section() -> void:
    var spacer := vbox.get_node("Spacer")
    var insert_at := spacer.get_index()

    var sep := HSeparator.new()
    vbox.add_child(sep)
    vbox.move_child(sep, insert_at)
    insert_at += 1

    var title := Label.new()
    title.text = "키 설정  (변경을 누른 뒤 원하는 키 입력 · Esc 취소)"
    vbox.add_child(title)
    vbox.move_child(title, insert_at)
    insert_at += 1

    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(0, 200)
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_child(scroll)
    vbox.move_child(scroll, insert_at)

    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 4)
    scroll.add_child(list)

    for action in InputConfig.REBINDABLE:
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 12)
        var lbl := Label.new()
        lbl.text = String(InputConfig.REBINDABLE[action])
        lbl.custom_minimum_size = Vector2(200, 0)
        row.add_child(lbl)
        var btn := Button.new()
        btn.text = InputConfig.binding_text(action)
        btn.custom_minimum_size = Vector2(180, 30)
        btn.pressed.connect(_on_rebind_pressed.bind(action))
        row.add_child(btn)
        _key_buttons[action] = btn
        list.add_child(row)

    var reset_btn := Button.new()
    reset_btn.text = "키 기본값 복원"
    reset_btn.custom_minimum_size = Vector2(0, 32)
    reset_btn.pressed.connect(_on_reset_keys)
    list.add_child(reset_btn)

    InputConfig.bindings_changed.connect(_refresh_key_buttons)


func _on_rebind_pressed(action: String) -> void:
    # 이전 대기 취소
    if _listening_action != "" and _key_buttons.has(_listening_action):
        _key_buttons[_listening_action].text = InputConfig.binding_text(_listening_action)
    _listening_action = action
    _key_buttons[action].text = "[ 키 입력 대기... ]"
    status_label.text = "'%s' 에 배정할 키를 누르십시오" % InputConfig.REBINDABLE[action]


func _input(event: InputEvent) -> void:
    if _listening_action == "":
        return
    if event is InputEventKey and event.pressed and not event.echo:
        var key := event as InputEventKey
        get_viewport().set_input_as_handled()
        if key.physical_keycode == KEY_ESCAPE:
            status_label.text = "취소됨"
        else:
            InputConfig.rebind(_listening_action, key)
            status_label.text = "배정 완료"
            Audio.play_sfx(Sfx.UI)
        var prev := _listening_action
        _listening_action = ""
        if _key_buttons.has(prev):
            _key_buttons[prev].text = InputConfig.binding_text(prev)


func _refresh_key_buttons() -> void:
    for action in _key_buttons:
        if action != _listening_action:
            _key_buttons[action].text = InputConfig.binding_text(action)


func _on_reset_keys() -> void:
    _listening_action = ""
    InputConfig.reset_to_default()
    status_label.text = "키 설정이 기본값으로 돌아갔습니다"


func _on_save() -> void:
    var ok := SaveManager.save(1)
    status_label.text = "슬롯 1에 저장됨" if ok else "저장 실패"


func _on_back() -> void:
    SceneManager.change_scene(MAIN_MENU_PATH)
