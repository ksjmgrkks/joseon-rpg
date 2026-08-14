extends Node
const PASS:="PASS"; const FAIL:="FAIL"
func _ready()->void:
	print("=== test_drops ===")
	var r:=await _check()
	print("[%s] %s"%[r.status,r.name]); if r.status==FAIL: print("  reason: %s"%r.reason)
	print("=== %d/1 passed ==="%(1 if r.status==PASS else 0))
	get_tree().quit(0 if r.status==PASS else 1)
func _check()->Dictionary:
	# 스코어어택 개편: 엽전(coin) 드롭 폐지 → 회복 아이템만 드롭, 처치는 점수로 환산.
	var host:=Node2D.new(); add_child(host)
	var gob:Node2D=load("res://scenes/enemies/Goblin.tscn").instantiate()
	gob.drop_chance=1.0
	host.add_child(gob); gob.global_position=Vector2(500,400)
	await get_tree().process_frame
	ScoreManager.start_run()
	var score_before:int=ScoreManager.score
	var hc:HealthComponent=gob.get_node("HealthComponent")
	hc.take_damage(9999.0)
	await get_tree().process_frame
	# 픽업(Pickup) 자식 — 회복 1개만(엽전 없음).
	var picks:=0
	for c in host.get_children():
		if c is Pickup: picks+=1
	var gained:int=ScoreManager.score-score_before
	host.queue_free()
	if picks != 1: return {"name":"enemy_drops_loot","status":FAIL,"reason":"드롭 픽업 %d개(기대 1: 회복만)"%picks}
	if gained != 100: return {"name":"enemy_drops_loot","status":FAIL,"reason":"처치 점수 %d(기대 100=xp10*10)"%gained}
	return {"name":"enemy_drops_loot","status":PASS,"reason":""}
