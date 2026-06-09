extends Control
##
## 슬롯 선택 UI — 3개 슬롯 표시. 모드별 동작:
##   "load"  : 슬롯에 저장이 있으면 그 슬롯을 로드하고 Village 진입.
##   "save"  : 슬롯에 저장. 일시정지 메뉴에서 사용. 게임이 paused 상태일 수 있으니
##             process_mode=ALWAYS 가 필요한 곳에 인스턴스해야 함.
##
## 슬롯 카드: 슬롯 번호 / 지역 / Lv / 엽전 / 저장 시각. 빈 슬롯은 '비어 있음' 안내.
##

signal slot_chosen(slot: int)
signal cancelled

@export var mode: String = "load"   # "load" | "save"
@export var slot_count: int = 3

@onready var bg: ColorRect = $Bg
@onready var list_root: VBoxContainer = $Margin/VBox/Slots
@onready var title: Label = $Margin/VBox/Title
@onready var hint: Label = $Margin/VBox/Hint
@onready var back_btn: Button = $Margin/VBox/BackBtn


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    title.text = "이어하기 — 슬롯 선택" if mode == "load" else "저장 — 슬롯 선택"
    hint.text = "[ESC] 취소" if mode == "save" else "[Backspace] 메인 메뉴"
    back_btn.pressed.connect(_on_back)
    _rebuild()


func _rebuild() -> void:
    for c in list_root.get_children():
        c.queue_free()
    for i in range(1, slot_count + 1):
        var card := _make_slot_card(i)
        list_root.add_child(card)


func _make_slot_card(slot: int) -> Control:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 16)
    var info := SaveManager.get_slot_info(slot)
    var line := Label.new()
    line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    if info.is_empty():
        line.text = "슬롯 %d  —  (비어 있음)" % slot
    else:
        var area := String(info.get("area", "-"))
        var lvl := int(info.get("level", 1))
        var gold := int(info.get("gold", 0))
        var iso := String(info.get("iso", ""))
        line.text = "슬롯 %d  ·  %s  ·  Lv %d  ·  엽전 %d  ·  %s" % [slot, area, lvl, gold, iso]
    row.add_child(line)

    if mode == "load":
        var btn := Button.new()
        btn.text = "이어하기"
        btn.disabled = info.is_empty()
        btn.pressed.connect(func() -> void: _on_pick(slot))
        row.add_child(btn)
    else:
        var save_btn := Button.new()
        save_btn.text = "이 슬롯에 저장"
        save_btn.pressed.connect(func() -> void: _on_pick(slot))
        row.add_child(save_btn)
        if not info.is_empty():
            var del_btn := Button.new()
            del_btn.text = "삭제"
            del_btn.pressed.connect(func() -> void:
                SaveManager.delete_save(slot)
                _rebuild()
            )
            row.add_child(del_btn)
    return row


func _on_pick(slot: int) -> void:
    slot_chosen.emit(slot)


func _on_back() -> void:
    cancelled.emit()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        cancelled.emit()
        get_viewport().set_input_as_handled()
