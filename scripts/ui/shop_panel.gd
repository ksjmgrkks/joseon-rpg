extends CanvasLayer
##
## ShopPanel autoload — 상점 UI. 대화 시스템의 'open_shop' 액션이 open(items, title) 호출.
##
## items: Array of { "id": String, "price": int }  (선택: count)
## - 진열된 항목을 좌측에 표시(이름 · 정가 · 보유 수량).
## - 보유 아이템은 우측 '판매' 영역 — 절반가 매입.
## - 상점 닫기는 ESC 또는 [닫기] 버튼.
##

@onready var panel: PanelContainer = $Panel
@onready var dim: ColorRect = $Dim
@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var buy_list: VBoxContainer = $Panel/Margin/VBox/Body/BuyList
@onready var sell_list: VBoxContainer = $Panel/Margin/VBox/Body/SellList
@onready var status_label: Label = $Panel/Margin/VBox/Status
@onready var close_btn: Button = $Panel/Margin/VBox/CloseBtn

var _stock: Array = []     # [{id, price}, ...]


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    panel.visible = false
    dim.visible = false
    close_btn.pressed.connect(close)
    if ShopManager:
        ShopManager.transaction.connect(_on_transaction)
    if Inventory:
        Inventory.inventory_changed.connect(_on_inventory_changed)
    if PlayerStats:
        PlayerStats.gold_changed.connect(_on_gold_changed)


func open(items: Array, title: String = "상점") -> void:
    _stock = items.duplicate(true)
    title_label.text = title
    status_label.text = "엽전 %d" % PlayerStats.gold
    panel.visible = true
    dim.visible = true
    _rebuild()


func close() -> void:
    panel.visible = false
    dim.visible = false


func _rebuild() -> void:
    for c in buy_list.get_children():
        c.queue_free()
    for c in sell_list.get_children():
        c.queue_free()
    # 진열대
    for entry in _stock:
        if not (entry is Dictionary):
            continue
        var id := String(entry.get("id", ""))
        var price := int(entry.get("price", 0))
        var def := Inventory.get_def(id)
        var iname := String(def.get("name", id))
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 12)
        var lbl := Label.new()
        var owned := Inventory.count(id)
        lbl.text = "%s  ·  %d문  (보유 %d)" % [iname, price, owned]
        lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(lbl)
        var btn := Button.new()
        btn.text = "구매"
        btn.disabled = PlayerStats.gold < price
        btn.pressed.connect(func() -> void: _on_buy(id, price))
        row.add_child(btn)
        buy_list.add_child(row)

    # 판매 영역 — 인벤토리 모든 비-퀘스트 아이템 중 매매가 정의된 것만 (1:1 매핑이 없으면 정가 절반 추정)
    var slots := Inventory.slots()
    for s in slots:
        var id := String(s.id)
        var def := Inventory.get_def(id)
        if String(def.get("type", "")) == "quest":
            continue   # 퀘스트 아이템은 판매 불가
        var sell_price := _sell_price_for(id, def)
        if sell_price <= 0:
            continue
        var iname := String(def.get("name", id))
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 12)
        var lbl := Label.new()
        lbl.text = "%s × %d  ·  매입 %d문" % [iname, int(s.count), sell_price]
        lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(lbl)
        var btn := Button.new()
        btn.text = "판매"
        btn.pressed.connect(func() -> void: _on_sell(id, sell_price))
        row.add_child(btn)
        sell_list.add_child(row)


func _sell_price_for(id: String, def: Dictionary) -> int:
    # 진열대에 있으면 정가의 50%
    for e in _stock:
        if e is Dictionary and String(e.get("id", "")) == id:
            return int(int(e.get("price", 0)) / 2)
    # gold 아이템은 그 값 그대로
    if def.has("gold"):
        return int(def.get("gold", 0))
    # 기본: 10문
    return 10


func _on_buy(id: String, price: int) -> void:
    if ShopManager and ShopManager.buy(id, price):
        status_label.text = "구매 완료 · 엽전 %d" % PlayerStats.gold
    else:
        status_label.text = "엽전이 부족합니다 · 엽전 %d" % PlayerStats.gold


func _on_sell(id: String, price: int) -> void:
    if ShopManager and ShopManager.sell(id, price):
        status_label.text = "판매 완료 · 엽전 %d" % PlayerStats.gold
    else:
        status_label.text = "판매할 수 없는 항목입니다"


func _on_transaction(_kind: String, _item: String, _ok: bool) -> void:
    if panel.visible:
        _rebuild()


func _on_inventory_changed(_slots: Array) -> void:
    if panel.visible:
        _rebuild()


func _on_gold_changed(amount: int) -> void:
    if panel.visible:
        status_label.text = "엽전 %d" % amount


func _unhandled_input(event: InputEvent) -> void:
    if not panel.visible:
        return
    if event.is_action_pressed("ui_cancel"):
        close()
        get_viewport().set_input_as_handled()
