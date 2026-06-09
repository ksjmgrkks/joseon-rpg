extends Node
##
## PlayerStats autoload — 플레이어 레벨/XP/소지금(엽전). SaveManager 연동.
## 시그널: xp_changed, level_up, gold_changed.
##

signal xp_changed(xp: int, xp_to_next: int)
signal level_up(new_level: int)
signal gold_changed(amount: int)

var level: int = 1
var xp: int = 0
var gold: int = 0


func _ready() -> void:
    SaveManager.save_requested.connect(_on_save)
    SaveManager.loaded.connect(_on_load)


## 레벨 N 까지 필요한 누적 XP (단순 곡선: 100 * N^1.5).
func xp_for_level(target_level: int) -> int:
    if target_level <= 1:
        return 0
    return int(100.0 * pow(float(target_level - 1), 1.5))


func xp_to_next() -> int:
    return xp_for_level(level + 1) - xp


func gain_xp(amount: int) -> void:
    if amount <= 0:
        return
    xp += amount
    var leveled := false
    while xp >= xp_for_level(level + 1):
        level += 1
        leveled = true
        level_up.emit(level)
    xp_changed.emit(xp, xp_to_next())


func add_gold(amount: int) -> void:
    if amount == 0:
        return
    gold = maxi(0, gold + amount)
    gold_changed.emit(gold)


# true 면 차감 성공, false 면 잔액 부족(차감 안 함).
func spend_gold(amount: int) -> bool:
    if amount <= 0:
        return true
    if gold < amount:
        return false
    gold -= amount
    gold_changed.emit(gold)
    return true


func reset() -> void:
    level = 1
    xp = 0
    gold = 0
    xp_changed.emit(xp, xp_to_next())
    gold_changed.emit(gold)


func _on_save(_slot: int, data: Dictionary) -> void:
    data["stats"] = { "level": level, "xp": xp, "gold": gold }


func _on_load(_slot: int, data: Dictionary) -> void:
    var s: Dictionary = data.get("stats", {})
    level = int(s.get("level", 1))
    xp = int(s.get("xp", 0))
    gold = int(s.get("gold", 0))
    xp_changed.emit(xp, xp_to_next())
    gold_changed.emit(gold)
