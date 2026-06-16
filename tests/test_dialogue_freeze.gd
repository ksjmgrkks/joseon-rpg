extends Node
const PASS:="PASS"; const FAIL:="FAIL"
const TMP:="user://_freeze.json"
func _ready()->void:
	print("=== test_dialogue_freeze ===")
	var results:Array[Dictionary]=[]
	results.append(await _check_enemy_freezes())
	results.append(await _check_npc_autostart())
	var failed:=0
	for r in results:
		print("[%s] %s"%[r.status,r.name]); if r.status==FAIL: failed+=1; print("  reason: %s"%r.reason)
	print("=== %d/%d passed ==="%[results.size()-failed,results.size()])
	get_tree().quit(0 if failed==0 else 1)
func _check_enemy_freezes()->Dictionary:
	if Dialogue.is_active(): Dialogue._end()
	var host:=Node2D.new(); add_child(host)
	# 지면(적이 떠다니지 않게)
	var ground:=StaticBody2D.new(); var cs:=CollisionShape2D.new(); var sh:=RectangleShape2D.new()
	sh.size=Vector2(2000,40); cs.shape=sh; ground.add_child(cs); ground.position=Vector2(600,520); host.add_child(ground)
	var player:Node2D=load("res://scenes/player/Player.tscn").instantiate(); host.add_child(player); player.global_position=Vector2(400,480)
	var gob:Node2D=load("res://scenes/enemies/Goblin.tscn").instantiate(); host.add_child(gob); gob.global_position=Vector2(700,480)
	for i in range(20): await get_tree().physics_frame
	# 대화 시작 → 적 위치 고정 확인
	var f=FileAccess.open(TMP,FileAccess.WRITE); f.store_string(JSON.stringify({"id":"f","start":"a","nodes":{"a":{"speaker":"x","text":"멈춰라","next":null}}})); f.close()
	Dialogue.start(TMP)
	var x0:float=gob.global_position.x
	for i in range(30): await get_tree().physics_frame
	var x1:float=gob.global_position.x
	Dialogue._end()
	var frozen:bool = absf(x1-x0) < 2.0
	host.queue_free()
	if not frozen: return {"name":"enemy_freezes_in_dialogue","status":FAIL,"reason":"대화 중 적이 이동함 (%.1f→%.1f)"%[x0,x1]}
	return {"name":"enemy_freezes_in_dialogue","status":PASS,"reason":""}
func _check_npc_autostart()->Dictionary:
	if Dialogue.is_active(): Dialogue._end()
	Flags.clear()
	var f=FileAccess.open(TMP,FileAccess.WRITE); f.store_string(JSON.stringify({"id":"n","start":"a","nodes":{"a":{"speaker":"촌로","text":"왔는가","next":null}}})); f.close()
	var npc:Node2D=load("res://scenes/npc/Npc.tscn").instantiate()
	npc.dialogue_path=TMP
	add_child(npc); npc.global_position=Vector2(300,400)
	await get_tree().process_frame
	var player:Node2D=load("res://scenes/player/Player.tscn").instantiate()
	add_child(player); player.global_position=Vector2(300,400)
	# 접근(겹침)만으로 자동 시작되어야 — 입력 없음
	for i in range(20): await get_tree().physics_frame
	var started:bool = Dialogue.is_active()
	Dialogue._end(); npc.queue_free(); player.queue_free()
	if not started: return {"name":"npc_auto_dialogue","status":FAIL,"reason":"접근해도 자동 대화 시작 안 함"}
	return {"name":"npc_auto_dialogue","status":PASS,"reason":""}
