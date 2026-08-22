extends SceneTree
##
## 1·2·3 스테이지 전용 BGM 합성 — 한 스크립트에서 세 곡을 만든다.
## 실행: godot --headless --path . --script res://tools/audio/gen_stage_bgm.gd
## 출력: assets/audio/bgm/stage1.wav · stage2.wav · stage3.wav
##
## 2026-08-22 사용자 요청: "1,2,3 스테이지 노래도 시작화면처럼 차분하고 가야금 느낌으로,
## 컨셉에 맞게 다시". 기존엔 1스테이지가 village/forest/night 를 섞어 쓰고(옛 마을 게임 잔재),
## 3스테이지는 아예 매핑이 없어 무음이었다.
##
## 공통 규칙(시작화면 곡과 같은 결):
##   · 느리게(BPM 44~58), 장구는 마디 첫 박 위주로만 — 행진이 아니라 호흡
##   · 가야금이 주선율, 대금 지속음이 바닥에 깔림
##   · 정적을 악기처럼 쓴다(빈 마디를 두려워하지 않는다)
## 스테이지마다 다른 것: 조성·템포·그 스테이지에만 있는 소리 한 가지.
##   1스테이지=물방울 / 2스테이지=아이 울음 / 3스테이지=장구 굿거리(저잣거리의 잔향)
##

const OUT_DIR := "res://assets/audio/bgm/"


func _init() -> void:
	_stage1()
	_stage2()
	_stage3()
	quit(0)


## 1스테이지 「물이 잠긴 골짜기」 — 가라앉은 것들의 곡. 가장 느리고 가장 비어 있다.
func _stage1() -> void:
	var s := KoreanSynth.new(20260822001)
	var beat := 60.0 / 44.0
	var bar := beat * 4.0
	var bars := 8
	var buf := _buffer(bar * float(bars))

	# 대금 — D 계면 근음. 물밑처럼 낮게 깔린다.
	var drone := ["D2", "D2", "F2", "D2", "C2", "D2", "F2", "D2"]
	for b in range(bars):
		s.daegeum(buf, s.note(drone[b % drone.size()]), bar * float(b), bar, 0.12)

	# 가야금 — D 계면 5음. 내려앉는 악구만, 해결하지 않는다(아직 못 풀어준 한).
	var scale := ["D4", "F4", "G4", "A4", "C5", "D5"]
	var phrases := [
		[[4, 0.0, 2.0], [3, 2.0, 2.0]],
		[[2, 0.0, 1.5], [1, 1.5, 2.5]],
		[[5, 0.0, 1.0], [4, 1.0, 1.0], [2, 2.0, 2.0]],
		[[1, 0.0, 3.0], [0, 3.0, 1.0]],
	]
	for b in range(bars):
		var ph: Array = phrases[b % phrases.size()]
		for st in ph:
			s.gayageum(buf, s.note(String(scale[int(st[0])])),
				bar * float(b) + beat * float(st[1]), beat * float(st[2]),
				0.26 if b % 2 == 0 else 0.20)

	# 장구 — 두 마디에 한 번만. 물속에서 들리는 먼 북.
	for b in range(bars):
		if b % 2 == 0:
			s.janggu_kung(buf, bar * float(b), 0.20)

	# 물방울 — 이 스테이지의 서명. 박자와 어긋나게 흩는다.
	for t in [2.1, 6.8, 11.3, 17.9, 23.4, 29.2, 35.6, 41.1]:
		s.water_drop(buf, t, 0.10)

	_finish(s, buf, "stage1")


## 2스테이지 「그슨대 숲」 — 부르는 소리. 조금 빠르고, 불안한 음이 하나 섞인다.
func _stage2() -> void:
	var s := KoreanSynth.new(20260822002)
	var beat := 60.0 / 50.0
	var bar := beat * 4.0
	var bars := 8
	var buf := _buffer(bar * float(bars))

	var drone := ["A2", "A2", "Bb2", "A2", "G2", "A2", "Bb2", "A2"]   # Bb = 반음 위, 스치는 불안
	for b in range(bars):
		s.daegeum(buf, s.note(drone[b % drone.size()]), bar * float(b), bar, 0.13)

	var scale := ["A3", "C4", "D4", "E4", "F4", "A4"]                 # F = 계면조의 어두운 6음
	var phrases := [
		[[5, 0.0, 1.5], [4, 1.5, 0.5], [3, 2.0, 2.0]],
		[[2, 0.0, 1.0], [1, 1.0, 3.0]],
		[[3, 0.0, 2.0], [4, 2.0, 1.0], [5, 3.0, 1.0]],
		[[1, 0.0, 4.0]],
	]
	for b in range(bars):
		var ph: Array = phrases[b % phrases.size()]
		for st in ph:
			s.gayageum(buf, s.note(String(scale[int(st[0])])),
				bar * float(b) + beat * float(st[1]), beat * float(st[2]),
				0.24 if b % 2 == 0 else 0.19)

	for b in range(bars):
		s.janggu_kung(buf, bar * float(b), 0.18 if b % 2 == 0 else 0.12)
	s.janggu_deok(buf, bar * 2.0 + beat * 3.0, 0.10)     # 마른 가지 밟는 소리처럼
	s.janggu_deok(buf, bar * 6.0 + beat * 1.5, 0.09)

	# 아이 울음 — 멀리서, 가끔. 그슨대가 부른다.
	for b in [1, 4, 6]:
		s.child_wail(buf, bar * float(b) + beat * 1.4, beat * 2.0, 0.06)

	_finish(s, buf, "stage2")


## 3스테이지 「저잣거리」 — 도깨비의 판. 셋 중 가장 움직이지만 여전히 차분하다.
## 굿거리 장단을 아주 눌러 깔아 "사람이 북적이던 자리"의 잔향을 남긴다.
func _stage3() -> void:
	var s := KoreanSynth.new(20260822003)
	var beat := 60.0 / 58.0
	var bar := beat * 4.0
	var bars := 8
	var buf := _buffer(bar * float(bars))

	var drone := ["G2", "G2", "D3", "G2", "F2", "G2", "D3", "G2"]
	for b in range(bars):
		s.daegeum(buf, s.note(drone[b % drone.size()]), bar * float(b), bar, 0.11)

	# 평조(밝은 5음)에 가깝게 — 도깨비는 무섭기보다 짓궂다.
	var scale := ["G3", "A3", "C4", "D4", "E4", "G4"]
	var phrases := [
		[[5, 0.0, 1.0], [3, 1.0, 1.0], [4, 2.0, 1.0], [2, 3.0, 1.0]],   # 껑충거리는 음정
		[[2, 0.0, 1.5], [4, 1.5, 1.5], [3, 3.0, 1.0]],
		[[5, 0.0, 1.0], [4, 1.0, 0.5], [5, 1.5, 0.5], [1, 2.0, 2.0]],
		[[0, 0.0, 2.0], [2, 2.0, 2.0]],
	]
	for b in range(bars):
		var ph: Array = phrases[b % phrases.size()]
		for st in ph:
			s.gayageum(buf, s.note(String(scale[int(st[0])])),
				bar * float(b) + beat * float(st[1]), beat * float(st[2]),
				0.23 if b % 2 == 0 else 0.18)

	# 굿거리 비슷하게 — 쿵 . 덕 . / 쿵 . 덕덕 . 을 아주 약하게
	for b in range(bars):
		var t0 := bar * float(b)
		s.janggu_kung(buf, t0, 0.19)
		s.janggu_deok(buf, t0 + beat * 1.5, 0.10)
		s.janggu_deok(buf, t0 + beat * 2.5, 0.08)
		if b % 2 == 1:
			s.janggu_deok(buf, t0 + beat * 3.25, 0.07)

	_finish(s, buf, "stage3")


func _buffer(seconds: float) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	buf.resize(int(seconds * KoreanSynth.SR))
	return buf


func _finish(s: KoreanSynth, buf: PackedFloat32Array, name: String) -> void:
	s.normalize(buf, 0.708)                       # -3 dBFS
	s.fade_io(buf, int(0.005 * KoreanSynth.SR))
	s.save_wav(buf, OUT_DIR + name + ".wav")
	print("생성: %s.wav (%.1f초)" % [name, float(buf.size()) / float(KoreanSynth.SR)])
