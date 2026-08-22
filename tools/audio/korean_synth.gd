extends RefCounted
class_name KoreanSynth
##
## 국악기풍 소프트 신디사이저 — BGM 생성 스크립트들이 공유하는 악기·유틸 모음.
##
## 2026-08-22: `gen_geuseondae_bgm.gd` 안에만 있던 악기 구현을 여기로 빼서 재사용한다
## (시작화면 BGM 을 만들며 150줄을 복사할 뻔했다). 두 생성기가 같은 소리를 내야
## 스테이지마다 음색이 따로 놀지 않는다.
##
## 규약(tools/audio/synth.py 와 동일):
##   · 22050Hz / 16bit / mono, 피크 -3dBFS 정규화, 시작·끝 5ms 페이드, 루프 플래그 on
## 악기:
##   · 가야금 플럭 = Karplus-Strong (짧은 노이즈 버스트 → 지연선 평균)
##   · 대금풍 지속음 = 사인 + 5도 배음 + 느린 비브라토 + 숨소리 노이즈
##   · 장구 = 저역 '쿵'(사인 스윕) / 고역 '덕'(노이즈 감쇠)
##
## ⚠ 난수를 쓰는 악기(가야금·장구덕·대금 숨소리)는 **호출 순서가 곧 결과**다.
##   기존 곡을 재생성할 때 순서를 바꾸면 파일이 달라진다.
##

const SR := 22050

var rng := RandomNumberGenerator.new()


func _init(seed_value: int = 0) -> void:
	rng.seed = seed_value


# ── 악기 ───────────────────────────────────────────────

## 가야금풍 뜯는 소리 — Karplus-Strong. 짧은 노이즈를 지연선에 넣고 평균으로 감쇠시킨다.
func gayageum(out: PackedFloat32Array, freq: float, t0: float, dur: float, gain: float) -> void:
	var start := int(t0 * SR)
	var count := int(dur * SR)
	var delay := maxi(2, int(float(SR) / freq))
	var line := PackedFloat32Array()
	line.resize(delay)
	for i in range(delay):
		line[i] = rng.randf_range(-1.0, 1.0)
	var idx := 0
	for i in range(count):
		var pos := start + i
		if pos < 0 or pos >= out.size():
			break
		var nxt := (idx + 1) % delay
		var v: float = (line[idx] + line[nxt]) * 0.5 * 0.996      # 감쇠
		line[idx] = v
		idx = nxt
		# 뜯은 직후가 가장 밝고 점점 사그라든다
		var env: float = exp(-3.2 * float(i) / float(count))
		out[pos] += v * env * gain


## 대금풍 지속음 — 사인 + 5도 배음 + 느린 비브라토 + 숨소리.
func daegeum(out: PackedFloat32Array, freq: float, t0: float, dur: float, gain: float) -> void:
	var start := int(t0 * SR)
	var count := int(dur * SR)
	for i in range(count):
		var pos := start + i
		if pos < 0 or pos >= out.size():
			break
		var t := float(i) / float(SR)
		var vib := 1.0 + 0.006 * sin(TAU * 4.2 * t)               # 느린 떨림
		var s := sin(TAU * freq * vib * t) * 0.7
		s += sin(TAU * freq * 1.5 * vib * t) * 0.18               # 5도
		s += rng.randf_range(-1.0, 1.0) * 0.05                    # 숨소리
		# 완만한 들숨/날숨
		var env: float = sin(PI * float(i) / float(count))
		out[pos] += s * env * gain


## 장구 쿵 — 저역 사인 스윕(빠르게 떨어짐).
func janggu_kung(out: PackedFloat32Array, t0: float, gain: float) -> void:
	var start := int(t0 * SR)
	var count := int(0.28 * SR)
	for i in range(count):
		var pos := start + i
		if pos < 0 or pos >= out.size():
			break
		var t := float(i) / float(SR)
		var f := lerpf(120.0, 55.0, minf(1.0, t / 0.09))
		var env: float = exp(-14.0 * t)
		out[pos] += sin(TAU * f * t) * env * gain


## 장구 덕 — 고역 노이즈가 짧게 탁.
func janggu_deok(out: PackedFloat32Array, t0: float, gain: float) -> void:
	var start := int(t0 * SR)
	var count := int(0.14 * SR)
	var last := 0.0
	for i in range(count):
		var pos := start + i
		if pos < 0 or pos >= out.size():
			break
		var t := float(i) / float(SR)
		var nz := rng.randf_range(-1.0, 1.0)
		last = last * 0.55 + nz * 0.45                            # 살짝 눌러 나무 느낌
		var env: float = exp(-30.0 * t)
		out[pos] += (nz - last) * env * gain


## 아이 울음의 잔향 — 음정이 미묘하게 어긋나 '흉내'처럼 들리게.
func child_wail(out: PackedFloat32Array, t0: float, dur: float, gain: float) -> void:
	var start := int(t0 * SR)
	var count := int(dur * SR)
	for i in range(count):
		var pos := start + i
		if pos < 0 or pos >= out.size():
			break
		var t := float(i) / float(SR)
		var p := float(i) / float(count)
		var f := lerpf(560.0, 430.0, p) * (1.0 + 0.02 * sin(TAU * 5.5 * t))
		var s := sin(TAU * f * t) * 0.6 + sin(TAU * f * 2.02 * t) * 0.25   # 2.02배 = 살짝 어긋난 옥타브
		var env: float = sin(PI * p)
		env *= env
		out[pos] += s * env * gain


## 물방울 — 시작화면(물에 잠긴 골짜기)용. 짧게 떨어지는 고음 사인 + 잔물결.
## 음높이가 위에서 아래로 빠르게 미끄러져 '똑' 하고 수면에 닿는 느낌을 만든다.
func water_drop(out: PackedFloat32Array, t0: float, gain: float) -> void:
	var start := int(t0 * SR)
	var count := int(0.42 * SR)
	for i in range(count):
		var pos := start + i
		if pos < 0 or pos >= out.size():
			break
		var t := float(i) / float(SR)
		var f := lerpf(1500.0, 620.0, minf(1.0, t / 0.05))
		var env: float = exp(-11.0 * t)
		out[pos] += sin(TAU * f * t) * env * gain


# ── 유틸 ───────────────────────────────────────────────

## "D2" "F#4" "Bb3" 같은 음이름 → 주파수(Hz)
func note(name: String) -> float:
	var semi := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
	var letter := name.substr(0, 1).to_upper()
	var rest := name.substr(1)
	var acc := 0
	if rest.begins_with("#"):
		acc = 1; rest = rest.substr(1)
	elif rest.begins_with("b"):
		acc = -1; rest = rest.substr(1)
	var octave := int(rest)
	var n: int = int(semi[letter]) + acc + (octave + 1) * 12
	return 440.0 * pow(2.0, (float(n) - 69.0) / 12.0)


func normalize(buf: PackedFloat32Array, peak: float) -> void:
	var m := 0.0
	for v in buf:
		m = maxf(m, absf(v))
	if m <= 0.0001:
		return
	var k := peak / m
	for i in range(buf.size()):
		buf[i] *= k


func fade_io(buf: PackedFloat32Array, fade: int) -> void:
	for i in range(mini(fade, buf.size())):
		var g := float(i) / float(fade)
		buf[i] *= g
		buf[buf.size() - 1 - i] *= g


func save_wav(buf: PackedFloat32Array, out_path: String) -> void:
	var pcm := PackedByteArray()
	pcm.resize(buf.size() * 2)
	for i in range(buf.size()):
		var s := int(clampf(buf[i], -1.0, 1.0) * 32767.0)
		pcm.encode_s16(i * 2, s)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SR
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = buf.size()
	stream.save_to_wav(ProjectSettings.globalize_path(out_path))
