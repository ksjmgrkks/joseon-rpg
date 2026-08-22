extends SceneTree
## 4스테이지 「끊긴 상여길」 BGM과 상여귀의 세 박 종소리를 생성한다.
## 실행: godot --headless --path . --script res://tools/audio/gen_stage4_audio.gd


func _init() -> void:
	_make_bgm()
	_make_bell_sfx()
	quit(0)


func _make_bgm() -> void:
	var synth := KoreanSynth.new(20260822004)
	var beat := 60.0 / 46.0
	var bar := beat * 4.0
	var bars := 8
	var buf := _buffer(bar * float(bars))
	var drone := ["E2", "E2", "G2", "E2", "D2", "E2", "G2", "E2"]
	for b in range(bars):
		synth.daegeum(buf, synth.note(drone[b]), bar * float(b), bar, 0.105)
	var scale := ["E3", "G3", "A3", "B3", "D4", "E4"]
	var phrases := [
		[[5, 0.0, 1.0], [4, 1.0, 1.0], [2, 2.0, 2.0]],
		[[3, 0.0, 1.5], [1, 1.5, 2.5]],
		[[4, 0.0, 1.0], [3, 1.0, 1.0], [0, 2.0, 2.0]],
		[[1, 0.0, 3.0]],
	]
	for b in range(bars):
		for step in phrases[b % phrases.size()]:
			synth.gayageum(buf, synth.note(String(scale[int(step[0])])),
				bar * float(b) + beat * float(step[1]), beat * float(step[2]),
				0.22 if b % 2 == 0 else 0.17)
		if b % 2 == 0:
			synth.janggu_kung(buf, bar * float(b), 0.14)
	# 매 네 마디 끝의 세 종. 보스 기믹을 음악에서 먼저 익힌다.
	for anchor in [bar * 3.0, bar * 7.0]:
		for i in range(3):
			synth.funeral_bell(buf, anchor + beat * (2.2 + float(i) * 0.48), 0.055 + i * 0.008, 164.8)
	synth.normalize(buf, 0.708)
	synth.fade_io(buf, int(0.005 * KoreanSynth.SR))
	synth.save_wav(buf, "res://assets/audio/bgm/stage4.wav")
	print("생성: stage4.wav (%.1f초)" % (float(buf.size()) / KoreanSynth.SR))


func _make_bell_sfx() -> void:
	var synth := KoreanSynth.new(20260822444)
	var buf := _buffer(2.8)
	synth.funeral_bell(buf, 0.0, 0.5, 196.0)
	synth.normalize(buf, 0.708)
	synth.fade_io(buf, int(0.005 * KoreanSynth.SR))
	synth.save_wav(buf, "res://assets/audio/sfx/funeral_bell.wav")
	print("생성: funeral_bell.wav")


func _buffer(seconds: float) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	buf.resize(int(seconds * KoreanSynth.SR))
	return buf
