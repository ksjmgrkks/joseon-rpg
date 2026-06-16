extends Node
const PASS:="PASS"; const FAIL:="FAIL"
func _ready()->void:
	print("=== test_iframe ===")
	var r:=await _check()
	print("[%s] %s"%[r.status,r.name]); if r.status==FAIL: print("  reason: %s"%r.reason)
	print("=== %d/1 passed ==="%(1 if r.status==PASS else 0))
	get_tree().quit(0 if r.status==PASS else 1)
func _check()->Dictionary:
	var hc:HealthComponent=HealthComponent.new()
	hc.max_hp=100.0; hc.invuln_on_hit=0.5
	add_child(hc); await get_tree().process_frame
	hc.take_damage(10.0)   # 적용
	hc.take_damage(10.0)   # 무적 중 — 무시되어야
	hc.take_damage(10.0)   # 무시
	var after_burst:float=hc.hp
	if not is_equal_approx(after_burst,90.0):
		hc.queue_free(); return {"name":"iframe_blocks_burst","status":FAIL,"reason":"연타 무적 안 됨 (hp=%.0f, 기대 90)"%after_burst}
	# 무적 끝나길 대기 후 한 번 더 → 적용
	await get_tree().create_timer(0.65).timeout
	hc.take_damage(10.0)
	var ok:bool=is_equal_approx(hc.hp,80.0)
	hc.queue_free()
	if not ok: return {"name":"iframe_blocks_burst","status":FAIL,"reason":"무적 종료 후 피해 미적용 (hp=%.0f)"%hc.hp}
	return {"name":"iframe_blocks_burst","status":PASS,"reason":""}
