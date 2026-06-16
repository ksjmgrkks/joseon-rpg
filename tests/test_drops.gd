extends Node
const PASS:="PASS"; const FAIL:="FAIL"
func _ready()->void:
	print("=== test_drops ===")
	var r:=await _check()
	print("[%s] %s"%[r.status,r.name]); if r.status==FAIL: print("  reason: %s"%r.reason)
	print("=== %d/1 passed ==="%(1 if r.status==PASS else 0))
	get_tree().quit(0 if r.status==PASS else 1)
func _check()->Dictionary:
	# 드롭 확률 100% 로 강제한 적을 죽여 픽업이 부모에 생기는지
	var host:=Node2D.new(); add_child(host)
	var gob:Node2D=load("res://scenes/enemies/Goblin.tscn").instantiate()
	gob.drop_chance=1.0; gob.drop_gold_chance=1.0
	host.add_child(gob); gob.global_position=Vector2(500,400)
	await get_tree().process_frame
	var hc:HealthComponent=gob.get_node("HealthComponent")
	hc.take_damage(9999.0)
	await get_tree().process_frame
	# 픽업(Pickup) 자식이 host 에 2개(회복+엽전) 생겼는지
	var picks:=0
	for c in host.get_children():
		if c is Pickup: picks+=1
	host.queue_free()
	if picks < 2: return {"name":"enemy_drops_loot","status":FAIL,"reason":"드롭 픽업 %d개(기대 2)"%picks}
	return {"name":"enemy_drops_loot","status":PASS,"reason":""}
