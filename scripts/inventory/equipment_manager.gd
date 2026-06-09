extends Node
##
## EquipmentManager autoload — 무기/방어구 슬롯.
##
## 아이템 정의(items.json)에 "slot": "weapon"|"armor" 와 stat(damage/defense)을 둔다.
## equip(id) 는 인벤토리에서 1개 차감(스택에서) 후 슬롯에 장착, 기존 장착품은 다시 인벤토리로 반환.
## unequip(slot) 는 슬롯 비우고 인벤토리로 돌려준다.
##
## 효과:
##   - weapon.damage → Player 공격 시 Hitbox.damage 의 기본값으로 사용(Player._do_combo_attack 에서 lookup).
##   - armor.defense → HealthComponent.take_damage 에서 차감.
##
## 시그널: equipment_changed(weapon_id: String, armor_id: String)
##

signal equipment_changed(weapon_id: String, armor_id: String)

var weapon_id: String = ""
var armor_id: String = ""


func _ready() -> void:
    SaveManager.save_requested.connect(_on_save)
    SaveManager.loaded.connect(_on_load)


func _slot_of(id: String) -> String:
    var d := Inventory.get_def(id)
    return String(d.get("slot", ""))


func equip(id: String) -> bool:
    if id == "" or Inventory.count(id) <= 0:
        return false
    var slot := _slot_of(id)
    if slot != "weapon" and slot != "armor":
        return false
    # 인벤토리에서 1개 빼고
    Inventory.remove(id, 1)
    # 기존 장착품은 인벤토리로 반환
    var prev := weapon_id if slot == "weapon" else armor_id
    if prev != "":
        Inventory.add(prev, 1)
    if slot == "weapon":
        weapon_id = id
    else:
        armor_id = id
    equipment_changed.emit(weapon_id, armor_id)
    return true


func unequip(slot: String) -> bool:
    if slot == "weapon" and weapon_id != "":
        Inventory.add(weapon_id, 1)
        weapon_id = ""
        equipment_changed.emit(weapon_id, armor_id)
        return true
    if slot == "armor" and armor_id != "":
        Inventory.add(armor_id, 1)
        armor_id = ""
        equipment_changed.emit(weapon_id, armor_id)
        return true
    return false


# 현재 장착 무기의 데미지(없으면 base 인자 반환).
func current_damage(base: float) -> float:
    if weapon_id == "":
        return base
    var d := Inventory.get_def(weapon_id)
    return float(d.get("damage", base))


# 현재 장착 방어구의 방어력(없으면 0).
func current_defense() -> float:
    if armor_id == "":
        return 0.0
    var d := Inventory.get_def(armor_id)
    return float(d.get("defense", 0))


func clear() -> void:
    weapon_id = ""
    armor_id = ""
    equipment_changed.emit(weapon_id, armor_id)


func _on_save(_slot: int, data: Dictionary) -> void:
    data["equipment"] = { "weapon": weapon_id, "armor": armor_id }


func _on_load(_slot: int, data: Dictionary) -> void:
    var e: Dictionary = data.get("equipment", {})
    weapon_id = String(e.get("weapon", ""))
    armor_id = String(e.get("armor", ""))
    equipment_changed.emit(weapon_id, armor_id)
