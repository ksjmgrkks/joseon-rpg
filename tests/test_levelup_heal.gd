extends Node
const PASS:="PASS"; const FAIL:="FAIL"
func _ready()->void:
	print("=== test_levelup_heal ===")
	var r:=await _check()
	print("[%s] %s"%[r.status,r.name]); if r.status==FAIL: print("  reason: %s"%r.reason)
	print("=== %d/1 passed ==="%(1 if r.status==PASS else 0))
	get_tree().quit(0 if r.status==PASS else 1)
func _check()->Dictionary:
	PlayerStats.reset()
	var player:Node2D=load("res://scenes/player/Player.tscn").instantiate()
	add_child(player); await get_tree().process_frame
	var hc:HealthComponent=player.get_node("HealthComponent")
	hc.take_damage(70.0)   # hp 30
	await get_tree().process_frame
	var before:float=hc.hp
	# 레벨업 유발 → 회복돼야
	while PlayerStats.level < 2:
		PlayerStats.gain_xp(200)
	await get_tree().process_frame
	var after:float=hc.hp
	player.queue_free()
	if after <= before:
		return {"name":"levelup_heals","status":FAIL,"reason":"레벨업 후 회복 안 됨 (%.0f→%.0f)"%[before,after]}
	return {"name":"levelup_heals","status":PASS,"reason":""}
