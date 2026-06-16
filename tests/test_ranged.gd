extends Node
const PASS:="PASS"; const FAIL:="FAIL"
func _ready()->void:
	print("=== test_ranged ===")
	var r:=await _check()
	print("[%s] %s"%[r.status,r.name]); if r.status==FAIL: print("  reason: %s"%r.reason)
	print("=== %d/1 passed ==="%(1 if r.status==PASS else 0))
	get_tree().quit(0 if r.status==PASS else 1)
func _check()->Dictionary:
	var host:=Node2D.new(); add_child(host)
	var player:Node2D=load("res://scenes/player/Player.tscn").instantiate()
	host.add_child(player); player.global_position=Vector2(400,400)
	var rea:Node2D=load("res://scenes/enemies/Reaper.tscn").instantiate()
	host.add_child(rea); rea.global_position=Vector2(600,400)  # 중거리(200px)
	await get_tree().process_frame
	# 원거리 발사가 일어나도록 프레임 진행 → SpiritOrb 가 host 에 생기는지
	var saw_orb:=false
	for i in range(20):
		await get_tree().physics_frame
		for c in host.get_children():
			if c is SpiritOrb: saw_orb=true
		if saw_orb: break
	host.queue_free()
	if not saw_orb: return {"name":"reaper_fires_orb","status":FAIL,"reason":"중거리에서 영혼 구슬 발사 안 함"}
	return {"name":"reaper_fires_orb","status":PASS,"reason":""}
