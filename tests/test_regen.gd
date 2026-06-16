extends Node
const PASS:="PASS"; const FAIL:="FAIL"
func _ready()->void:
	print("=== test_regen ===")
	var r:=await _check()
	print("[%s] %s"%[r.status,r.name]); if r.status==FAIL: print("  reason: %s"%r.reason)
	print("=== %d/1 passed ==="%(1 if r.status==PASS else 0))
	get_tree().quit(0 if r.status==PASS else 1)
func _check()->Dictionary:
	var hc:HealthComponent=HealthComponent.new()
	hc.max_hp=100.0; hc.regen_rate=2.5; hc.regen_delay=0.5
	add_child(hc); await get_tree().process_frame
	hc.hp=50.0; hc._since_hit=0.0
	# 지연 전(0.3s)엔 회복 없어야
	await get_tree().create_timer(0.3).timeout
	if hc.hp > 50.5: return {"name":"time_regen","status":FAIL,"reason":"지연 전 회복됨(%.1f)"%hc.hp}
	# 지연 후 1.5초 더 → 회복(약 2.5*~1.3 ≈ 3+)
	await get_tree().create_timer(1.5).timeout
	var ok:bool = hc.hp > 52.0
	var h:float = hc.hp
	hc.queue_free()
	if not ok: return {"name":"time_regen","status":FAIL,"reason":"자연 회복 안 됨(%.1f)"%h}
	return {"name":"time_regen","status":PASS,"reason":""}
