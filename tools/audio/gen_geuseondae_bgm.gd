extends SceneTree
##
## 2스테이지(그슨대 숲) 전용 BGM 합성 — 파이썬 없는 환경을 위해 Godot 으로 옮긴 신디사이저.
## 실행: godot --headless --path . --script res://tools/audio/gen_geuseondae_bgm.gd
## 출력: assets/audio/bgm/geuseondae.wav (22050Hz / 16bit / mono, 루프 친화)
##
## 규약은 tools/audio/synth.py 와 동일:
##   · 22050Hz 16bit mono, 피크 -3dBFS 정규화, 시작/끝 5ms 페이드
## 악기:
##   · 가야금 플럭 = Karplus-Strong (짧은 노이즈 버스트 → 지연선 평균)
##   · 대금풍 지속음 = 사인 + 5도 배음 + 느린 비브라토 + 숨소리 노이즈
##   · 장구 = 저역 '쿵'(사인 스윕) / 고역 '덕'(노이즈 감쇠)
## 정서: 그슨대 숲 — 아이 울음으로 부르는 그림자. 계면조(단조풍) 5음, 느리고 성기게.
##   멜로디를 드문드문 두고 **정적**을 악기처럼 쓴다. 낮은 지속음이 계속 깔려 압박.
##

const SR := 22050
const OUT := "res://assets/audio/bgm/geuseondae.wav"
const BPM := 52.0          # 아주 느리게 — 발이 무거워지는 템포

var _rng := RandomNumberGenerator.new()


func _init() -> void:
    _rng.seed = 20260819
    var beat := 60.0 / BPM
    var bars := 8
    var total := beat * 4.0 * float(bars)
    var n := int(total * SR)
    var buf := PackedFloat32Array()
    buf.resize(n)

    # ① 낮은 지속음(대금) — 곡 전체에 깔리는 압박. 근음 D2 ↔ 단3도 F2 를 오간다.
    var drone_notes := [_note("D2"), _note("D2"), _note("F2"), _note("D2"),
                        _note("C2"), _note("D2"), _note("F2"), _note("D2")]
    for b in range(bars):
        _daegeum(buf, drone_notes[b % drone_notes.size()], beat * 4.0 * float(b), beat * 4.0, 0.16)

    # ② 가야금 — 계면조 5음(D 계면: D F G A C). 성기게, 마디마다 두세 음만.
    var scale := ["D4", "F4", "G4", "A4", "C5", "D5"]
    var phrases := [
        [[0, 0.0, 2.0], [2, 2.0, 1.0], [1, 3.0, 1.0]],
        [[3, 0.0, 1.5], [2, 1.5, 0.5], [0, 2.0, 2.0]],
        [[4, 0.0, 1.0], [3, 1.0, 1.0], [1, 2.0, 2.0]],
        [[0, 0.0, 3.0], [1, 3.0, 1.0]],
    ]
    for b in range(bars):
        var ph: Array = phrases[b % phrases.size()]
        for step in ph:
            var f := _note(String(scale[int(step[0])]))
            var t := beat * 4.0 * float(b) + beat * float(step[1])
            var dur := beat * float(step[2])
            _gayageum(buf, f, t, dur, 0.30 if b % 2 == 0 else 0.24)

    # ③ 장구 — 굿거리 대신 아주 성긴 타점. 정적을 살리려 마디 첫 박과 3박만.
    for b in range(bars):
        var t0 := beat * 4.0 * float(b)
        _janggu_kung(buf, t0, 0.5)
        if b % 2 == 1:
            _janggu_deok(buf, t0 + beat * 2.0, 0.32)
        _janggu_deok(buf, t0 + beat * 3.5, 0.18)

    # ④ 아이 울음의 잔향 — 그슨대의 유인. 아주 작게, 가끔, 멀리서.
    #    사람 목소리를 흉내낸 게 아니라 '흉내처럼 들리는 것'이라 음정이 살짝 어긋난다.
    for b in [1, 4, 6]:
        _child_wail(buf, beat * 4.0 * float(b) + beat * 1.2, beat * 2.2, 0.07)

    _normalize(buf, 0.708)      # -3 dBFS
    _fade_io(buf, int(0.005 * SR))
    _save_wav(buf)
    print("생성: %s  (%.1f초, %d샘플)" % [OUT, total, n])
    quit(0)


# ── 악기 ───────────────────────────────────────────────

## 가야금풍 뜯는 소리 — Karplus-Strong. 짧은 노이즈를 지연선에 넣고 평균으로 감쇠시킨다.
func _gayageum(out: PackedFloat32Array, freq: float, t0: float, dur: float, gain: float) -> void:
    var start := int(t0 * SR)
    var count := int(dur * SR)
    var delay := maxi(2, int(float(SR) / freq))
    var line := PackedFloat32Array()
    line.resize(delay)
    for i in range(delay):
        line[i] = _rng.randf_range(-1.0, 1.0)
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
func _daegeum(out: PackedFloat32Array, freq: float, t0: float, dur: float, gain: float) -> void:
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
        s += _rng.randf_range(-1.0, 1.0) * 0.05                   # 숨소리
        # 완만한 들숨/날숨
        var env: float = sin(PI * float(i) / float(count))
        out[pos] += s * env * gain


## 장구 쿵 — 저역 사인 스윕(빠르게 떨어짐).
func _janggu_kung(out: PackedFloat32Array, t0: float, gain: float) -> void:
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
func _janggu_deok(out: PackedFloat32Array, t0: float, gain: float) -> void:
    var start := int(t0 * SR)
    var count := int(0.14 * SR)
    var last := 0.0
    for i in range(count):
        var pos := start + i
        if pos < 0 or pos >= out.size():
            break
        var t := float(i) / float(SR)
        var nz := _rng.randf_range(-1.0, 1.0)
        last = last * 0.55 + nz * 0.45                            # 살짝 눌러 나무 느낌
        var env: float = exp(-30.0 * t)
        out[pos] += (nz - last) * env * gain


## 아이 울음의 잔향 — 음정이 미묘하게 어긋나 '흉내'처럼 들리게.
func _child_wail(out: PackedFloat32Array, t0: float, dur: float, gain: float) -> void:
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


# ── 유틸 ───────────────────────────────────────────────

func _note(name: String) -> float:
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


func _normalize(buf: PackedFloat32Array, peak: float) -> void:
    var m := 0.0
    for v in buf:
        m = maxf(m, absf(v))
    if m <= 0.0001:
        return
    var k := peak / m
    for i in range(buf.size()):
        buf[i] *= k


func _fade_io(buf: PackedFloat32Array, fade: int) -> void:
    for i in range(mini(fade, buf.size())):
        var g := float(i) / float(fade)
        buf[i] *= g
        buf[buf.size() - 1 - i] *= g


func _save_wav(buf: PackedFloat32Array) -> void:
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
    stream.save_to_wav(ProjectSettings.globalize_path(OUT))
