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

var _synth := KoreanSynth.new()


func _init() -> void:
    _synth.rng.seed = 20260819
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

# 악기·유틸 구현은 tools/audio/korean_synth.gd 로 옮겼다(시작화면 BGM 과 공유).
# 아래는 기존 호출부를 그대로 두기 위한 얇은 위임 — 난수 호출 순서가 바뀌지 않아
# 같은 시드면 예전과 **바이트 단위로 동일한** wav 가 나온다(재생성해서 해시로 확인함).

func _gayageum(out: PackedFloat32Array, freq: float, t0: float, dur: float, gain: float) -> void:
    _synth.gayageum(out, freq, t0, dur, gain)


func _daegeum(out: PackedFloat32Array, freq: float, t0: float, dur: float, gain: float) -> void:
    _synth.daegeum(out, freq, t0, dur, gain)


func _janggu_kung(out: PackedFloat32Array, t0: float, gain: float) -> void:
    _synth.janggu_kung(out, t0, gain)


func _janggu_deok(out: PackedFloat32Array, t0: float, gain: float) -> void:
    _synth.janggu_deok(out, t0, gain)


func _child_wail(out: PackedFloat32Array, t0: float, dur: float, gain: float) -> void:
    _synth.child_wail(out, t0, dur, gain)


func _note(name: String) -> float:
    return _synth.note(name)


func _normalize(buf: PackedFloat32Array, peak: float) -> void:
    _synth.normalize(buf, peak)


func _fade_io(buf: PackedFloat32Array, fade: int) -> void:
    _synth.fade_io(buf, fade)


func _save_wav(buf: PackedFloat32Array) -> void:
    _synth.save_wav(buf, OUT)
