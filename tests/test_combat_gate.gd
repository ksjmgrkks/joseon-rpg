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
	if gate._art == null or gate._art.sprite_frames.get_frame_count("release") != 6:
		return {"name":"gate_opens_on_clear","status":FAIL,"reason":"금줄 해제 애니메이션이 6프레임이 아님"}
	if gate._barrier.collision_layer != 4:
		return {"name":"gate_opens_on_clear","status":FAIL,"reason":"닫힌 금줄의 충돌 레이어가 꺼져 있음"}
	# 적 하나 추가 → 게이트 닫힘 유지
	var e:=CharacterBody2D.new(); e.add_to_group("enemy"); e.add_to_group("enemy_gate"); add_child(e)
	for i in range(40): await get_tree().process_frame
	var barrier_alive:=gate.get_child_count()>0 and is_instance_valid(gate.get_child(0))
	if not barrier_alive: return {"name":"gate_opens_on_clear","status":FAIL,"reason":"적이 남았는데 장벽이 사라짐"}
	# 적 제거 → 게이트 개방
	e.queue_free()
	await get_tree().create_timer(1.0).timeout
	var opened:bool = gate._open
	var collision_off:bool = gate._barrier.collision_layer == 0
	var final_frame:bool = gate._art.animation == &"open" and gate._art.frame == 0
	gate.queue_free()
	if not opened: return {"name":"gate_opens_on_clear","status":FAIL,"reason":"적 처치 후에도 게이트 안 열림"}
	if not collision_off: return {"name":"gate_opens_on_clear","status":FAIL,"reason":"금줄 해제 후 충돌이 남음"}
	if not final_frame: return {"name":"gate_opens_on_clear","status":FAIL,"reason":"해제 애니메이션이 열린 마지막 상태에 머물지 않음"}
	return {"name":"gate_opens_on_clear","status":PASS,"reason":""}
