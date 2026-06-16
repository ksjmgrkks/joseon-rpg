extends Node
const PASS:="PASS"; const FAIL:="FAIL"
func _ready()->void:
	print("=== test_enemy_attack ===")
	var r:=await _check()
	print("[%s] %s"%[r.status,r.name]); if r.status==FAIL: print("  reason: %s"%r.reason)
	print("=== %d/1 passed ==="%(1 if r.status==PASS else 0))
	get_tree().quit(0 if r.status==PASS else 1)
func _check()->Dictionary:
	var player:Node2D=load("res://scenes/player/Player.tscn").instantiate()
	add_child(player); player.global_position=Vector2(400,400)
	var gob:Node2D=load("res://scenes/enemies/Goblin.tscn").instantiate()
	add_child(gob); gob.global_position=Vector2(430,400)   # 사거리 안
	await get_tree().process_frame
	var ph:HealthComponent=player.get_node("HealthComponent")
	var hp0:float=ph.hp
	# 예비동작+타격이 일어날 만큼 대기 (telegraph 0.28 + 여유)
	for i in range(80): await get_tree().physics_frame
	var hp1:float=ph.hp
	var dropped:bool = hp1 < hp0
	player.queue_free(); gob.queue_free()
	if not dropped:
		return {"name":"enemy_hits_player","status":FAIL,"reason":"적 근접인데 플레이어 HP 안 깎임 (%.0f→%.0f)"%[hp0,hp1]}
	return {"name":"enemy_hits_player","status":PASS,"reason":""}
