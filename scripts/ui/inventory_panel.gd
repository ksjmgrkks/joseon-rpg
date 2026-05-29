extends CanvasLayer
##
## 인벤토리 UI — 'inventory' 액션(I)으로 토글. 보유 아이템·수량·설명 표시.
## 디자인 폴리시(한지·먹 톤)는 폰트 임포트 후.
##

@onready var panel: PanelContainer = $Panel
@onready var slots_list: VBoxContainer = $Panel/Margin/VBox/SlotsList
@onready var hint_label: Label = $Panel/Margin/VBox/Hint


func _ready() -> void:
    panel.visible = false
    Inventory.inventory_changed.connect(_on_inventory_changed)
    _rebuild(Inventory.slots())


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("inventory"):
        panel.visible = not panel.visible
        if panel.visible:
            _rebuild(Inventory.slots())
        get_viewport().set_input_as_handled()


func _on_inventory_changed(slots: Array) -> void:
    if panel.visible:
        _rebuild(slots)


func _rebuild(slots: Array) -> void:
    # 기존 항목 정리
    for c in slots_list.get_children():
        c.queue_free()
    if slots.is_empty():
        var l := Label.new()
        l.text = "(비어 있음)"
        slots_list.add_child(l)
        hint_label.text = "[I] 닫기"
        return
    for s in slots:
        var def := Inventory.get_def(String(s.id))
        var name := String(def.get("name", s.id))
        var desc := String(def.get("description", ""))
        var cnt := int(s.count)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 12)

        var name_label := Label.new()
        name_label.text = "%s × %d" % [name, cnt]
        name_label.custom_minimum_size = Vector2(160, 0)
        row.add_child(name_label)

        var desc_label := Label.new()
        desc_label.text = desc
        desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        row.add_child(desc_label)

        # 소모품(heal) 이면 '사용' 버튼
        if String(def.get("type", "")) == "consumable" and def.has("heal"):
            var use_btn := Button.new()
            use_btn.text = "사용"
            var item_id := String(s.id)
            var heal_amt := int(def.get("heal", 0))
            use_btn.pressed.connect(func() -> void: _use_consumable(item_id, heal_amt))
            row.add_child(use_btn)

        slots_list.add_child(row)
    hint_label.text = "[I] 닫기  ·  %d / %d 슬롯" % [slots.size(), Inventory.CAPACITY]


func _use_consumable(item_id: String, heal_amt: int) -> void:
    var player := get_tree().get_first_node_in_group("player")
    if player == null:
        return
    var health: HealthComponent = player.get_node_or_null("HealthComponent")
    if health == null:
        return
    health.heal(float(heal_amt))
    Inventory.remove(item_id, 1)
