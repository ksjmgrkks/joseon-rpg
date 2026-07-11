extends Node
const PASS:="PASS"; const FAIL:="FAIL"
const TMP:="user://_freeze.json"
func _ready()->void:
	print("=== test_dialogue_freeze ===")
	var results:Array[Dictionary]=[]
	results.append(await _check_enemy_freezes())
	results.append(await _check_player_freezes())
	results.append(await _check_dodge_resets())
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
func _check_player_freezes()->Dictionary:
	if Dialogue.is_active(): Dialogue._end()
	var host:=Node2D.new(); add_child(host)
	var ground:=StaticBody2D.new(); var cs:=CollisionShape2D.new(); var sh:=RectangleShape2D.new()
	sh.size=Vector2(2000,40); cs.shape=sh; ground.add_child(cs); ground.position=Vector2(600,520); host.add_child(ground)
	var player:Node2D=load("res://scenes/player/Player.tscn").instantiate(); host.add_child(player); player.global_position=Vector2(400,480)
	for i in range(20): await get_tree().physics_frame
	# 오른쪽 이동 입력을 누른 채 대화 시작 → 주인공이 움직이지 않아야 한다.
	Input.action_press("move_right")
	var f=FileAccess.open(TMP,FileAccess.WRITE); f.store_string(JSON.stringify({"id":"p","start":"a","nodes":{"a":{"speaker":"x","text":"게 섰거라","next":null}}})); f.close()
	Dialogue.start(TMP)
	var x0:float=player.global_position.x
	for i in range(30): await get_tree().physics_frame
	var x1:float=player.global_position.x
	var frozen:bool = absf(x1-x0) < 2.0
	# 대화 종료 후엔 같은 입력으로 다시 움직여야 한다(잠금이 영구가 아님).
	Dialogue._end()
	for i in range(20): await get_tree().physics_frame
	var x2:float=player.global_position.x
	Input.action_release("move_right")
	var moves_after:bool = (x2-x1) > 8.0
	host.queue_free()
	if not frozen: return {"name":"player_freezes_in_dialogue","status":FAIL,"reason":"대화 중 주인공이 이동함 (%.1f→%.1f)"%[x0,x1]}
	if not moves_after: return {"name":"player_freezes_in_dialogue","status":FAIL,"reason":"대화 종료 후 이동 복구 안 됨 (%.1f→%.1f)"%[x1,x2]}
	return {"name":"player_freezes_in_dialogue","status":PASS,"reason":""}
func _check_dodge_resets()->Dictionary:
	# 구르는(회피) 도중 대화가 시작되면 구르기 상태가 즉시 해제되어
	# 바른 자세(idle)로 대화해야 한다 — 어색한 구르기 포즈로 얼어붙지 않게.
	if Dialogue.is_active(): Dialogue._end()
	var host:=Node2D.new(); add_child(host)
	var ground:=StaticBody2D.new(); var cs:=CollisionShape2D.new(); var sh:=RectangleShape2D.new()
	sh.size=Vector2(2000,40); cs.shape=sh; ground.add_child(cs); ground.position=Vector2(600,520); host.add_child(ground)
	var player:Node2D=load("res://scenes/player/Player.tscn").instantiate(); host.add_child(player); player.global_position=Vector2(400,480)
	for i in range(20): await get_tree().physics_frame
	# 회피 구르기 시작
	Input.action_press("dodge")
	await get_tree().physics_frame
	Input.action_release("dodge")
	await get_tree().physics_frame
	var rolling:bool = player._dodging
	# 구르는 도중 대화 시작
	var f=FileAccess.open(TMP,FileAccess.WRITE); f.store_string(JSON.stringify({"id":"d","start":"a","nodes":{"a":{"speaker":"x","text":"멈추어라","next":null}}})); f.close()
	Dialogue.start(TMP)
	for i in range(4): await get_tree().physics_frame
	var reset:bool = not player._dodging
	var hurt_on:bool = player.hurtbox == null or player.hurtbox.monitoring   # 무적 해제(피격 정상화)
	Dialogue._end(); host.queue_free()
	if not rolling: return {"name":"dodge_resets_on_dialogue","status":FAIL,"reason":"회피 시작이 안 됨(테스트 전제 실패)"}
	if not reset: return {"name":"dodge_resets_on_dialogue","status":FAIL,"reason":"대화 중에도 구르기 상태 유지(어색한 포즈)"}
	if not hurt_on: return {"name":"dodge_resets_on_dialogue","status":FAIL,"reason":"구르기 해제됐으나 무적(hurtbox off) 잔존"}
	return {"name":"dodge_resets_on_dialogue","status":PASS,"reason":""}
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
