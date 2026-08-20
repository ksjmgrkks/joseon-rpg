extends Node
const PASS:="PASS"; const FAIL:="FAIL"
const TMP:="user://_test_dlg_portrait.json"

func _ready()->void:
	print("=== test_dialogue_portrait ===")
	var results:Array[Dictionary]=[]
	results.append(await _check_player_shows_neutral())
	results.append(await _check_expression_meta())
	results.append(await _check_npc_hides_portrait())
	results.append(await _check_narration_hides_portrait())
	var failed:=0
	for r in results:
		print("[%s] %s"%[r.status,r.name]); if r.status==FAIL: failed+=1; print("  reason: %s"%r.reason)
	print("=== %d/%d passed ==="%[results.size()-failed,results.size()])
	get_tree().quit(0 if failed==0 else 1)

func _start(data:Dictionary)->void:
	if Dialogue.is_active(): Dialogue._end()
	var f=FileAccess.open(TMP,FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	Dialogue.start(TMP)

func _check_player_shows_neutral()->Dictionary:
	_start({"id":"p","start":"a","nodes":{"a":{"speaker":"길손","text":"게 섰거라","next":null}}})
	await get_tree().process_frame
	var visible:bool = DialogueBalloon.portrait.visible
	var tex_ok:bool = DialogueBalloon.portrait.texture != null and String(DialogueBalloon.portrait.texture.resource_path).ends_with("neutral.png")
	Dialogue._end()
	if not visible: return {"name":"player_shows_neutral_portrait","status":FAIL,"reason":"주인공 대사인데 초상화가 안 보임"}
	if not tex_ok: return {"name":"player_shows_neutral_portrait","status":FAIL,"reason":"기본 표정이 neutral.png 가 아님: %s"%[DialogueBalloon.portrait.texture]}
	return {"name":"player_shows_neutral_portrait","status":PASS,"reason":""}

func _check_expression_meta()->Dictionary:
	_start({"id":"e","start":"a","nodes":{"a":{"speaker":"길손","text":"흥","expression":"smirk","next":null}}})
	await get_tree().process_frame
	var tex_ok:bool = DialogueBalloon.portrait.visible and DialogueBalloon.portrait.texture != null and String(DialogueBalloon.portrait.texture.resource_path).ends_with("smirk.png")
	Dialogue._end()
	if not tex_ok: return {"name":"expression_meta_overrides_default","status":FAIL,"reason":"\"expression\":\"smirk\" 메타가 반영 안 됨: %s"%[DialogueBalloon.portrait.texture]}
	return {"name":"expression_meta_overrides_default","status":PASS,"reason":""}

func _check_npc_hides_portrait()->Dictionary:
	_start({"id":"n","start":"a","nodes":{"a":{"speaker":"촌로","text":"왔는가","next":null}}})
	await get_tree().process_frame
	var hidden:bool = not DialogueBalloon.portrait.visible
	Dialogue._end()
	if not hidden: return {"name":"npc_hides_protagonist_portrait","status":FAIL,"reason":"NPC 대사인데 주인공 초상화가 보임"}
	return {"name":"npc_hides_protagonist_portrait","status":PASS,"reason":""}

func _check_narration_hides_portrait()->Dictionary:
	_start({"id":"r","start":"a","nodes":{"a":{"speaker":"","text":"바람이 스산하다.","next":null}}})
	await get_tree().process_frame
	var hidden:bool = not DialogueBalloon.portrait.visible
	Dialogue._end()
	if not hidden: return {"name":"narration_hides_portrait","status":FAIL,"reason":"나레이션인데 초상화가 보임"}
	return {"name":"narration_hides_portrait","status":PASS,"reason":""}
