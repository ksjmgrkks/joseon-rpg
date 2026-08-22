extends SceneTree
##
## 시작 화면 BGM 합성 — `BgmDirector` 가 MainMenu 에서 찾는 title.wav 를 만든다.
## 실행: godot --headless --path . --script res://tools/audio/gen_title_bgm.gd
## 출력: assets/audio/bgm/title.wav (22050Hz / 16bit / mono, 루프)
##
## 악기·유틸은 tools/audio/korean_synth.gd 공유(2스테이지 BGM 과 같은 음색).
##
## 정서: 시작 화면은 「물에 잠긴 골짜기에 등불이 떠 있는 밤」이다. 전투곡이 아니라
##   **애도와 채비**의 음악 — 느리고 성기게, 정적을 악기처럼 쓴다.
##   · 장구는 마디 첫 박에만 아주 약하게(행진이 아니라 심장 박동처럼)
##   · 가야금은 내려앉는 한숨 같은 악구를 두다가, 마지막 마디에서 한 번 **올라가며 끝낸다**
##     — "그래도 간다"는 결의. 이 한 음이 곡 전체의 방향을 정한다.
##   · 물방울은 화면의 물등·수면과 맞물리는 소리. 박자에 안 맞게 흩어 놓아야 자연스럽다.
##

const OUT := "res://assets/audio/bgm/title.wav"
const BPM := 46.0          # 2스테이지(52)보다 더 느리게 — 시작 화면은 머무는 곳이다
const BARS := 8

var _synth := KoreanSynth.new()


func _init() -> void:
	_synth.rng.seed = 20260822
	var beat := 60.0 / BPM
	var bar := beat * 4.0
	var total := bar * float(BARS)
	var n := int(total * KoreanSynth.SR)
	var buf := PackedFloat32Array()
	buf.resize(n)

	# ① 저음 지속음(대금) — A 계면의 근음. 곡 내내 물처럼 깔린다.
	#    2스테이지의 압박(0.16)보다 약하게 잡아 '무섭다'가 아니라 '가라앉는다'로.
	var drone := ["A2", "A2", "G2", "A2", "C3", "A2", "G2", "A2"]
	for b in range(BARS):
		_synth.daegeum(buf, _synth.note(drone[b % drone.size()]), bar * float(b), bar, 0.13)

	# ② 가야금 — A 계면 5음(A C D E G). [음 인덱스, 시작 박, 길이 박]
	#    앞 6마디는 내려앉는 악구, 7~8마디에서 한 번 올라가며 맺는다.
	var scale := ["A3", "C4", "D4", "E4", "G4", "A4", "C5"]
	var phrases := [
		[[5, 0.0, 2.0], [4, 2.0, 1.0], [3, 3.0, 1.0]],      # 라 — 솔 미
		[[2, 0.0, 1.5], [1, 1.5, 2.5]],                      # 레 — 도(길게)
		[[4, 0.0, 1.0], [5, 1.0, 1.0], [3, 2.0, 2.0]],      # 솔 라 — 미
		[[1, 0.0, 3.0], [0, 3.0, 1.0]],                      # 도 — 라(낮게 내려앉음)
		[[5, 0.0, 2.0], [6, 2.0, 2.0]],                      # 라 — 높은 도
		[[4, 0.0, 1.5], [3, 1.5, 1.5], [2, 3.0, 1.0]],      # 솔 미 레
		[[1, 0.0, 2.0], [3, 2.0, 1.0], [5, 3.0, 1.0]],      # 도 미 라 — 오르기 시작
		[[6, 0.0, 4.0]],                                     # 높은 도 하나로 길게 맺는다
	]
	for b in range(BARS):
		var ph: Array = phrases[b % phrases.size()]
		for step in ph:
			var f := _synth.note(String(scale[int(step[0])]))
			var t := bar * float(b) + beat * float(step[1])
			var dur := beat * float(step[2])
			# 마지막 마디의 맺는 음만 조금 세게 — 결의가 들리도록.
			var gain := 0.34 if b == BARS - 1 else (0.26 if b % 2 == 0 else 0.21)
			_synth.gayageum(buf, f, t, dur, gain)

	# ③ 장구 — 심장 박동처럼 마디 첫 박에만, 아주 약하게.
	for b in range(BARS):
		_synth.janggu_kung(buf, bar * float(b), 0.26 if b % 4 == 0 else 0.17)
	_synth.janggu_deok(buf, bar * 3.0 + beat * 3.5, 0.12)
	_synth.janggu_deok(buf, bar * 7.0 + beat * 2.5, 0.10)

	# ④ 물방울 — 박자에서 일부러 어긋난 자리에 흩어 놓는다(등불이 떠다니는 수면).
	for t in [1.7, 5.3, 9.1, 14.6, 19.2, 25.8, 31.4, 36.9]:
		_synth.water_drop(buf, t, 0.09)

	_synth.normalize(buf, 0.708)      # -3 dBFS
	_synth.fade_io(buf, int(0.005 * KoreanSynth.SR))
	_synth.save_wav(buf, OUT)
	print("생성: %s  (%.1f초, %d샘플)" % [OUT, total, n])
	quit(0)
