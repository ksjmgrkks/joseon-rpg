extends Node
##
## Inventory autoload — 아이템 슬롯 기반 인벤토리.
##
## - items.json 의 정의를 로드해 add/remove/has/count 제공.
## - 같은 id는 max_stack 까지 스택. 초과 시 새 슬롯.
## - SaveManager save/load 시그널에 자동 연결되어 'inventory' 키로 직렬화.
##
## 외부 API:
##   add(id, count=1) -> int    : 실제로 들어간 수량(용량 부족 시 < count)
##   remove(id, count=1) -> int : 실제로 빠진 수량
##   has(id, count=1) -> bool
##   count(id) -> int
##   slots() -> Array            : [{id, count}, ...] 복사본
##   get_def(id) -> Dictionary   : 아이템 정의(이름·설명 등)
##
## 시그널: inventory_changed(slots: Array)
##

signal inventory_changed(slots: Array)

const ITEMS_PATH := "res://assets/items/items.json"
const CAPACITY := 20

var _definitions: Dictionary = {}
var _slots: Array = []  # [{ "id": String, "count": int }, ...]


func _ready() -> void:
    _load_definitions()
    SaveManager.save_requested.connect(_on_save)
    SaveManager.loaded.connect(_on_load)


func _load_definitions() -> void:
    var file := FileAccess.open(ITEMS_PATH, FileAccess.READ)
    if file == null:
        push_error("[Inventory] cannot open: %s" % ITEMS_PATH)
        return
    var raw := file.get_as_text()
    file.close()
    var data = JSON.parse_string(raw)
    if not (data is Dictionary):
        push_error("[Inventory] invalid items.json")
        return
    _definitions = data.get("items", {})


func get_def(id: String) -> Dictionary:
    var d = _definitions.get(id, {})
    return d if d is Dictionary else {}


func slots() -> Array:
    return _slots.duplicate(true)


func count(id: String) -> int:
    var total := 0
    for s in _slots:
        if s.id == id:
            total += int(s.count)
    return total


func has(id: String, n: int = 1) -> bool:
    return count(id) >= n


func add(id: String, n: int = 1) -> int:
    if n <= 0:
        return 0
    var def := get_def(id)
    if def.is_empty():
        push_warning("[Inventory] unknown item id: %s" % id)
        return 0
    var max_stack := int(def.get("max_stack", 1))
    var remaining := n
    # 기존 스택 채우기
    for s in _slots:
        if s.id == id and int(s.count) < max_stack:
            var space := max_stack - int(s.count)
            var take := mini(space, remaining)
            s.count = int(s.count) + take
            remaining -= take
            if remaining <= 0:
                _emit_change()
                return n
    # 새 슬롯 추가
    while remaining > 0:
        if _slots.size() >= CAPACITY:
            _emit_change()
            return n - remaining
        var take := mini(max_stack, remaining)
        _slots.append({ "id": id, "count": take })
        remaining -= take
    _emit_change()
    return n


func remove(id: String, n: int = 1) -> int:
    if n <= 0:
        return 0
    var removed := 0
    for i in range(_slots.size() - 1, -1, -1):
        if _slots[i].id == id:
            var take := mini(int(_slots[i].count), n - removed)
            _slots[i].count = int(_slots[i].count) - take
            removed += take
            if _slots[i].count <= 0:
                _slots.remove_at(i)
            if removed >= n:
                break
    if removed > 0:
        _emit_change()
    return removed


func clear() -> void:
    _slots.clear()
    _emit_change()


func _emit_change() -> void:
    inventory_changed.emit(_slots.duplicate(true))


# SaveManager 연동
func _on_save(_slot: int, data: Dictionary) -> void:
    data["inventory"] = { "slots": _slots.duplicate(true) }


func _on_load(_slot: int, data: Dictionary) -> void:
    var bag: Dictionary = data.get("inventory", {})
    var loaded_slots: Array = bag.get("slots", [])
    _slots.clear()
    for s in loaded_slots:
        if s is Dictionary and s.has("id") and s.has("count"):
            _slots.append({ "id": String(s.id), "count": int(s.count) })
    _emit_change()
