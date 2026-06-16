extends Node
const PASS:="PASS"; const FAIL:="FAIL"
func _ready()->void:
	print("=== test_new_items ===")
	var r:=_check()
	print("[%s] %s"%[r.status,r.name]); if r.status==FAIL: print("  reason: %s"%r.reason)
	print("=== %d/1 passed ==="%(1 if r.status==PASS else 0))
	get_tree().quit(0 if r.status==PASS else 1)
func _check()->Dictionary:
	Inventory.clear(); Equipment.clear()
	Inventory.add("sword_steel",1); Inventory.add("armor_leather",1)
	if not Equipment.equip("sword_steel"): return {"name":"new_items_equip","status":FAIL,"reason":"강철검 장착 실패"}
	if not is_equal_approx(Equipment.current_damage(10.0),15.0): return {"name":"new_items_equip","status":FAIL,"reason":"강철검 데미지 %f"%Equipment.current_damage(10.0)}
	if not Equipment.equip("armor_leather"): return {"name":"new_items_equip","status":FAIL,"reason":"가죽갑옷 장착 실패"}
	if not is_equal_approx(Equipment.current_defense(),9.0): return {"name":"new_items_equip","status":FAIL,"reason":"가죽갑옷 방어 %f"%Equipment.current_defense()}
	return {"name":"new_items_equip","status":PASS,"reason":""}
