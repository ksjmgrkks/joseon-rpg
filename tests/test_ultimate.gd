extends Node
const PASS:="PASS"; const FAIL:="FAIL"
func _ready()->void:
	print("=== test_ultimate ===")
	var r:=await _check()
	print("[%s] %s"%[r.status,r.name]); if r.status==FAIL: print("  reason: %s"%r.reason)
	print("=== %d/1 passed ==="%(1 if r.status==PASS else 0))
	get_tree().quit(0 if r.status==PASS else 1)
func _check()->Dictionary:
	PlayerStats.reset(); SkillManager.reset_cooldowns()
	if not SkillManager.is_unlocked("guichang"): return {"name":"ultimate_aoe","status":FAIL,"reason":"궁극기 미해금"}
	var host:=Node2D.new(); add_child(host)
	var player:Node2D=load("res://scenes/player/Player.tscn").instantiate(); host.add_child(player); player.global_position=Vector2(500,400)
	# 사거리 안 적 2 + 멀리 적 1
	var near1:Node2D=load("res://scenes/enemies/Goblin.tscn").instantiate(); host.add_child(near1); near1.global_position=Vector2(600,400)
	var near2:Node2D=load("res://scenes/enemies/Goblin.tscn").instantiate(); host.add_child(near2); near2.global_position=Vector2(400,400)
	var far:Node2D=load("res://scenes/enemies/Goblin.tscn").instantiate(); host.add_child(far); far.global_position=Vector2(2000,400)
	await get_tree().process_frame
	var h1:float=near1.get_node("HealthComponent").hp
	var hfar:float=far.get_node("HealthComponent").hp
	var ok:=SkillManager.try_cast("guichang")
	for i in range(10): await get_tree().physics_frame
	var near_hit:bool = near1.get_node("HealthComponent").hp < h1
	var far_safe:bool = is_equal_approx(far.get_node("HealthComponent").hp, hfar)
	var on_cd:bool = SkillManager.cooldown_left("guichang") > 30.0
	host.queue_free()
	if not ok: return {"name":"ultimate_aoe","status":FAIL,"reason":"발동 실패"}
	if not near_hit: return {"name":"ultimate_aoe","status":FAIL,"reason":"사거리 내 적 피해 없음"}
	if not far_safe: return {"name":"ultimate_aoe","status":FAIL,"reason":"사거리 밖 적이 맞음"}
	if not on_cd: return {"name":"ultimate_aoe","status":FAIL,"reason":"긴 쿨다운 미적용(%.0f)"%SkillManager.cooldown_left("guichang")}
	return {"name":"ultimate_aoe","status":PASS,"reason":""}
