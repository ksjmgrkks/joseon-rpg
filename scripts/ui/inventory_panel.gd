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
        # 장비(slot=weapon/armor) 면 '장착' 버튼. 이미 장착돼 있으면 표시만.
        var slot := String(def.get("slot", ""))
        if slot == "weapon" or slot == "armor":
            var iid := String(s.id)
            var is_equipped := (slot == "weapon" and Equipment.weapon_id == iid) \
                or (slot == "armor" and Equipment.armor_id == iid)
            if is_equipped:
                var tag := Label.new()
                tag.text = "[장착중]"
                row.add_child(tag)
            else:
                var eq_btn := Button.new()
                eq_btn.text = "장착"
                eq_btn.pressed.connect(func() -> void: _equip_item(iid))
                row.add_child(eq_btn)

        slots_list.add_child(row)

    # 현재 장착 정보를 한 줄
    if Equipment.weapon_id != "" or Equipment.armor_id != "":
        var eq := Label.new()
        var wname: String = Inventory.get_def(Equipment.weapon_id).get("name", "(없음)") if Equipment.weapon_id != "" else "(없음)"
        var aname: String = Inventory.get_def(Equipment.armor_id).get("name", "(없음)") if Equipment.armor_id != "" else "(없음)"
        eq.text = "장비 — 무기: %s, 방어구: %s" % [wname, aname]
        slots_list.add_child(eq)

    hint_label.text = "[I] 닫기  ·  %d / %d 슬롯  ·  엽전 %d" % [slots.size(), Inventory.CAPACITY, PlayerStats.gold]


func _use_consumable(item_id: String, heal_amt: int) -> void:
    var player := get_tree().get_first_node_in_group("player")
    if player == null:
        return
    var health: HealthComponent = player.get_node_or_null("HealthComponent")
    if health == null:
        return
    health.heal(float(heal_amt))
    Inventory.remove(item_id, 1)
    Audio.play_sfx(Sfx.POTION)


func _equip_item(item_id: String) -> void:
    if Equipment.equip(item_id):
        _rebuild(Inventory.slots())
