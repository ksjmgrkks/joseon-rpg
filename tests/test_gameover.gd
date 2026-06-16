extends Node
const PASS:="PASS"; const FAIL:="FAIL"
func _ready()->void:
	print("=== test_gameover ===")
	var r:=await _check()
	# 정리: 게임오버가 트리 일시정지를 걸었을 수 있으니 해제
	get_tree().paused=false
	print("[%s] %s"%[r.status,r.name]); if r.status==FAIL: print("  reason: %s"%r.reason)
	print("=== %d/1 passed ==="%(1 if r.status==PASS else 0))
	get_tree().quit(0 if r.status==PASS else 1)
func _check()->Dictionary:
	GameOverScreen.hide_screen()
	var player:Node2D=load("res://scenes/player/Player.tscn").instantiate()
	add_child(player); await get_tree().process_frame
	var hc:HealthComponent=player.get_node("HealthComponent")
	hc.take_damage(99999.0)   # 즉사
	await get_tree().process_frame
	await get_tree().process_frame
	var shown:bool = GameOverScreen.panel.visible
	GameOverScreen.hide_screen()
	player.queue_free()
	if not shown: return {"name":"death_shows_gameover","status":FAIL,"reason":"사망 시 게임오버 화면 안 뜸"}
	return {"name":"death_shows_gameover","status":PASS,"reason":""}
