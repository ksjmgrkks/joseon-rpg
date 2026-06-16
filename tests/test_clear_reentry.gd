extends Node
const PASS:="PASS"; const FAIL:="FAIL"
func _ready()->void:
	print("=== test_clear_reentry ===")
	var r:=await _check()
	print("[%s] %s"%[r.status,r.name]); if r.status==FAIL: print("  reason: %s"%r.reason)
	print("=== %d/1 passed ==="%(1 if r.status==PASS else 0))
	get_tree().quit(0 if r.status==PASS else 1)
func _count(node, cls_name)->int:
	var n:=0
	for c in node.get_children():
		if c.get_class()=="CharacterBody2D" and c.is_in_group("enemy"): n+=1
	return n
func _check()->Dictionary:
	# 1) 클리어 안 됨 → 적 존재
	Flags.clear()
	var s1:Node=load("res://scenes/levels/VillageIntro.tscn").instantiate()
	add_child(s1); await get_tree().process_frame; await get_tree().process_frame
	var enemies_fresh:=get_tree().get_nodes_in_group("enemy").size()
	s1.queue_free(); await get_tree().process_frame
	if enemies_fresh <= 0:
		return {"name":"cleared_skips_enemies","status":FAIL,"reason":"신규 진입인데 적이 없음"}
	# 2) 클리어 플래그 셋 → 재진입 시 적 없음
	Flags.set_flag("village_cleared", true)
	var s2:Node=load("res://scenes/levels/VillageIntro.tscn").instantiate()
	add_child(s2); await get_tree().process_frame; await get_tree().process_frame
	var enemies_re:=get_tree().get_nodes_in_group("enemy").size()
	s2.queue_free()
	if enemies_re != 0:
		return {"name":"cleared_skips_enemies","status":FAIL,"reason":"클리어 후 재진입인데 적 %d마리 재생성"%enemies_re}
	return {"name":"cleared_skips_enemies","status":PASS,"reason":""}
