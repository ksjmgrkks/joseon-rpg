extends Node
const PASS:="PASS"; const FAIL:="FAIL"
const TMP:="user://_test_dlg_keys.json"
func _ready()->void:
	print("=== test_dialogue_keys ===")
	var r:=await _check()
	print("[%s] %s"%[r.status,r.name]); if r.status==FAIL: print("  reason: %s"%r.reason)
	print("=== %d/1 passed ==="%(1 if r.status==PASS else 0))
	get_tree().quit(0 if r.status==PASS else 1)
func _check()->Dictionary:
	Flags.clear()
	var d={"id":"k","start":"a","nodes":{
		"a":{"speaker":"x","text":"고르시오","choices":[
			{"text":"하나","next":"b1"},{"text":"둘","next":"b2"}]},
		"b1":{"speaker":"x","text":"1","actions":[{"type":"set_flag","key":"picked_a","value":true}],"next":null},
		"b2":{"speaker":"x","text":"2","actions":[{"type":"set_flag","key":"picked_b","value":true}],"next":null}}}
	var f=FileAccess.open(TMP,FileAccess.WRITE); f.store_string(JSON.stringify(d)); f.close()
	Dialogue.start(TMP)
	await get_tree().process_frame
	await get_tree().process_frame
	# 숫자 '2' 키로 둘째 선택지 선택
	var ev:=InputEventKey.new(); ev.keycode=KEY_2; ev.pressed=true
	DialogueBalloon._unhandled_input(ev)
	await get_tree().process_frame
	if not Flags.has_flag("picked_b"):
		return {"name":"number_key_picks_choice","status":FAIL,"reason":"숫자2 키로 둘째 선택지 선택 안 됨"}
	if Flags.has_flag("picked_a"):
		return {"name":"number_key_picks_choice","status":FAIL,"reason":"잘못된 선택지 선택됨"}
	return {"name":"number_key_picks_choice","status":PASS,"reason":""}
