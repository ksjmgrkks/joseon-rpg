extends Node
const PASS:="PASS"; const FAIL:="FAIL"
func _ready()->void:
	print("=== test_combat_gate ===")
	var r:=await _check()
	print("[%s] %s"%[r.status,r.name]); if r.status==FAIL: print("  reason: %s"%r.reason)
	print("=== %d/1 passed ==="%(1 if r.status==PASS else 0))
	get_tree().quit(0 if r.status==PASS else 1)
func _check()->Dictionary:
	var gate:Node2D=load("res://scripts/world/combat_gate.gd").new()
	add_child(gate)
	# 적 하나 추가 → 게이트 닫힘 유지
	var e:=CharacterBody2D.new(); e.add_to_group("enemy"); add_child(e)
	for i in range(40): await get_tree().process_frame
	var barrier_alive:=gate.get_child_count()>0 and is_instance_valid(gate.get_child(0))
	if not barrier_alive: return {"name":"gate_opens_on_clear","status":FAIL,"reason":"적이 남았는데 장벽이 사라짐"}
	# 적 제거 → 게이트 개방
	e.queue_free()
	for i in range(40): await get_tree().process_frame
	var opened:bool = gate._open
	gate.queue_free()
	if not opened: return {"name":"gate_opens_on_clear","status":FAIL,"reason":"적 처치 후에도 게이트 안 열림"}
	return {"name":"gate_opens_on_clear","status":PASS,"reason":""}
