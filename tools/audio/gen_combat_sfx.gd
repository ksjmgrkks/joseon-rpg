extends SceneTree
##
## 전투 SFX 합성 — 「맞았을 때」와 「빗나갔을 때」를 귀로 구분시키기 위한 두 소리.
## 실행: godot --headless --path . --script res://tools/audio/gen_combat_sfx.gd
## 출력: assets/audio/sfx/whiff.wav · hit_heavy.wav
##
## 2026-08-22 피드백: "공격했을 때 몬스터를 맞췄을 때와 맞추지 않았을 때 효과·사운드에
## 확실히 차이가 있었으면". 기존엔 스윙음(attack)만 있고 명중 시 hit 이 얹히는 구조라
## 차이가 약했다 — **빗맞음 전용 소리**를 따로 두면 대비가 분명해진다.
##
##  · whiff     = 바람 가르는 소리. 밝은 노이즈가 빠르게 저역으로 흘러내린다(무게 없음).
##  · hit_heavy = 여럿을 한 번에 쓸었을 때 얹는 묵직한 저역 타격(기본 hit 위에 겹쳐 쓴다).
##

const SR := 22050
const OUT := "res://assets/audio/sfx/"

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 20260822
	_whiff()
	_hit_heavy()
	quit(0)


## 바람 소리 — 대역이 위에서 아래로 훑고 지나간다. 짧고 가볍게.
func _whiff() -> void:
	var n := int(0.20 * SR)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp := 0.0
	for i in range(n):
		var t := float(i) / float(SR)
		var p := float(i) / float(n)
		# 저역통과 계수를 서서히 낮춰 '쉭—' 하고 흘러내리게
		var k: float = lerpf(0.75, 0.12, p)
		lp = lp * (1.0 - k) + _rng.randf_range(-1.0, 1.0) * k
		# 앞부분이 세고 빠르게 사그라든다
		var env: float = sin(PI * pow(p, 0.55)) * exp(-3.0 * t)
		buf[i] = lp * env
	_save(buf, "whiff", 0.45)


## 묵직한 타격 — 저역 사인 스윕 + 짧은 노이즈 어택. 다중 히트에 겹쳐 얹는다.
func _hit_heavy() -> void:
	var n := int(0.26 * SR)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / float(SR)
		var f: float = lerpf(190.0, 52.0, minf(1.0, t / 0.07))
		var body := sin(TAU * f * t) * exp(-11.0 * t)
		var crack := _rng.randf_range(-1.0, 1.0) * exp(-70.0 * t) * 0.5
		buf[i] = body * 0.85 + crack
	_save(buf, "hit_heavy", 0.85)


func _save(buf: PackedFloat32Array, name: String, peak: float) -> void:
	var m := 0.0
	for v in buf:
		m = maxf(m, absf(v))
	if m > 0.0001:
		var k := peak / m
		for i in range(buf.size()):
			buf[i] *= k
	# 클릭 방지용 짧은 페이드
	var fade := int(0.004 * SR)
	for i in range(mini(fade, buf.size())):
		var g := float(i) / float(fade)
		buf[i] *= g
		buf[buf.size() - 1 - i] *= g
	var pcm := PackedByteArray()
	pcm.resize(buf.size() * 2)
	for i in range(buf.size()):
		pcm.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = SR
	st.stereo = false
	st.data = pcm
	st.save_to_wav(ProjectSettings.globalize_path(OUT + name + ".wav"))
	print("생성: %s.wav (%.2f초)" % [name, float(buf.size()) / float(SR)])
