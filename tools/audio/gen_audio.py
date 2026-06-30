# -*- coding: utf-8 -*-
"""「호환기담」 오디오 에셋 일괄 생성 — SFX 10종 + BGM 4종.

실행: python tools/audio/gen_audio.py
산출:
  assets/audio/sfx/*.wav, assets/audio/bgm/*.wav  (22050Hz 16bit mono)
  assets/audio/manifest.json
  shots/sheets/audio_spec.txt        (duration / peak dBFS / RMS 표 — 검수 시트)
  shots/sheets/audio_waveforms.png   (파형 오버뷰 — 눈 검수용, Pillow 있으면)
"""
import json
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
import synth as S
from synth import (SR, note, silence, sine, sine_sweep, sine_freqs, triangle,
                   noise, ks_pluck, lowpass, highpass, env_points, decay_exp,
                   adsr, gain, fade_io, mix_at, mix, trim, write_wav)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SFX = os.path.join(ROOT, "assets", "audio", "sfx")
BGM = os.path.join(ROOT, "assets", "audio", "bgm")
SHEETS = os.path.join(ROOT, "shots", "sheets")


# ════════════════════════════ SFX ════════════════════════════
def sfx_attack():
    """칼 휘두름 — 노이즈 스윕 휘익 (컷오프 상승→하강, 저역 제거)."""
    dur = 0.30
    n = noise(dur, seed=11)
    cut = []
    for i in range(len(n)):
        t = i / SR
        if t < 0.10:
            c = 1200 + (6500 - 1200) * (t / 0.10)
        else:
            c = 6500 - (6500 - 700) * ((t - 0.10) / (dur - 0.10))
        cut.append(c)
    w = lowpass(n, cut)
    w = highpass(w, 350)                      # 럼블 제거 → 바람가르는 소리
    w = env_points(w, [(0, 0.0), (0.08, 1.0), (0.14, 0.8), (dur, 0.0)])
    return fade_io(w, 0.003)


def sfx_hurt():
    """피격 — 낮은 둔탁."""
    body = decay_exp(sine_sweep(160, 70, 0.22, "exp"), tau=0.07)
    thud = gain(decay_exp(lowpass(noise(0.06, seed=21), 500), tau=0.02), 0.45)
    return fade_io(mix(body, thud), 0.002)


def sfx_hit():
    """타격 명중 — 짧은 톡."""
    tone = decay_exp(sine_sweep(750, 240, 0.12, "exp"), tau=0.035)
    click = gain(decay_exp(lowpass(noise(0.025, seed=31), 3200), tau=0.008), 0.6)
    return fade_io(mix(tone, click), 0.002)


def sfx_die():
    """적 사망 — 하강 음 (비브라토 + 서브 옥타브)."""
    dur = 0.60
    nlen = int(SR * dur)
    ph1 = ph2 = 0.0
    out = []
    for i in range(nlen):
        t = i / SR
        u = t / dur
        f = 392.0 * (65.0 / 392.0) ** u
        f *= 1.0 + 0.012 * math.sin(2 * math.pi * 5.5 * t)   # 흔들리는 숨
        ph1 += 2 * math.pi * f / SR
        ph2 += 2 * math.pi * (f * 0.5) / SR
        out.append(math.sin(ph1) + 0.35 * math.sin(ph2))
    out = env_points(out, [(0, 0.0), (0.01, 1.0), (0.35, 0.65), (dur, 0.0)])
    return fade_io(out, 0.003)


def sfx_pickup():
    """엽전 줍기 — 5음계 딩 2음 (D5 → G5)."""
    def ding(f, tau):
        a = decay_exp(sine(f, 0.20), tau=tau)
        b = gain(decay_exp(sine(f * 2.0, 0.20), tau=tau * 0.5), 0.30)
        return mix(a, b)
    out = silence(0.30)
    mix_at(out, ding(note("D5"), 0.06), 0.00, 0.9)
    mix_at(out, ding(note("G5"), 0.08), 0.09, 1.0)
    out = trim(out, 0.30)
    out = env_points(out, [(0, 1.0), (0.24, 1.0), (0.30, 0.0)])  # 끝 정리
    return fade_io(out, 0.002)


def sfx_potion():
    """물약 — 보글보글 (상승 블립 연속 + 옅은 거품 노이즈)."""
    out = silence(0.50)
    blips = [(0.02, 320), (0.10, 430), (0.18, 370), (0.26, 540),
             (0.33, 460), (0.40, 620)]
    for i, (t, f) in enumerate(blips):
        b = decay_exp(sine_sweep(f, f * 1.8, 0.05, "exp"), tau=0.025)
        mix_at(out, b, t, 0.8)
    fizz = gain(lowpass(noise(0.50, seed=41), 1800), 0.10)
    fizz = env_points(fizz, [(0, 0.3), (0.25, 1.0), (0.50, 0.0)])
    mix_at(out, fizz, 0.0, 1.0)
    out = trim(out, 0.50)
    out = env_points(out, [(0, 1.0), (0.44, 1.0), (0.50, 0.0)])  # 끝 정리
    return fade_io(out, 0.003)


def sfx_jump():
    """점프 — 짧은 상승."""
    tone = sine_sweep(280, 660, 0.16, "exp")
    tone = env_points(tone, [(0, 0.0), (0.01, 1.0), (0.10, 0.7), (0.16, 0.0)])
    tick = gain(decay_exp(lowpass(noise(0.02, seed=51), 2500), tau=0.006), 0.3)
    return fade_io(mix(tone, tick), 0.002)


def sfx_dodge():
    """회피 구르기 — 슉 (빠른 고역 노이즈)."""
    dur = 0.16
    n = noise(dur, seed=61)
    cut = [2000 + 6000 * (i / (SR * dur)) for i in range(len(n))]
    w = highpass(lowpass(n, cut), 900)
    w = env_points(w, [(0, 0.0), (0.025, 1.0), (0.07, 0.55), (dur, 0.0)])
    return fade_io(w, 0.002)


def sfx_ui_click():
    """UI 틱 — 아주 짧은 블립."""
    tone = decay_exp(sine(1300, 0.05), tau=0.012)
    click = gain(decay_exp(lowpass(noise(0.012, seed=71), 5000), tau=0.004), 0.5)
    out = silence(0.10)
    mix_at(out, mix(tone, click), 0.0, 1.0)
    return fade_io(trim(out, 0.10), 0.002)


def sfx_jingle_quest():
    """퀘스트 징글 — 5음계 상승 3음 (C5 D5 G5), 1초."""
    def bell(f, tau):
        a = decay_exp(sine(f, 0.6), tau=tau)
        b = gain(decay_exp(sine(f * 2.0, 0.6), tau=tau * 0.45), 0.25)
        return mix(a, b)
    out = silence(1.0)
    mix_at(out, bell(note("C5"), 0.16), 0.00, 0.85)
    mix_at(out, bell(note("D5"), 0.16), 0.22, 0.90)
    mix_at(out, bell(note("G5"), 0.28), 0.44, 1.00)
    out = trim(out, 1.0)
    out = env_points(out, [(0, 1.0), (0.85, 1.0), (1.0, 0.0)])  # 여운 마무리
    return fade_io(out, 0.004)


def sfx_ultimate():
    """궁극기 '귀창 강림' — 어둡고 묵직한 마기 충격 + 쏟아지는 귀신 창.
    밝은 종소리(jingle) 대체: 저역 임팩트 + 마기 우르릉 + 하강 휘몰이 + 창 꽂힘.
    평타(attack swing) 위에 겹쳐 궁극기의 무게를 준다."""
    dur = 1.15
    out = silence(dur)
    # 1) 저역 임팩트(쿵) — 북 몸통 + 서브
    boom = decay_exp(sine_sweep(120, 42, 0.5, "exp"), tau=0.22)
    sub = gain(decay_exp(sine(46, 0.5), tau=0.30), 0.5)
    mix_at(out, mix(boom, sub), 0.0, 0.95)
    # 2) 마기 우르릉 — 저역 노이즈 베드(살짝 늦게 들어와 길게 깔림)
    rumble = lowpass(noise(0.95, seed=91), 220)
    rumble = env_points(rumble, [(0, 0.0), (0.10, 0.7), (0.5, 0.45), (0.95, 0.0)])
    mix_at(out, gain(rumble, 0.5), 0.04, 1.0)
    # 3) 하강 마기 휘몰이 — 고→저 스윕(어두운 톤 + 5도 위 배음 옅게)
    howl = decay_exp(sine_sweep(900, 130, 0.6, "exp"), tau=0.28)
    howl = mix(howl, gain(sine_sweep(1350, 195, 0.6, "exp"), 0.28))
    mix_at(out, gain(howl, 0.5), 0.02, 1.0)
    # 4) 쏟아지는 귀신 창 — 금속 스침 burst 6개를 시차로(차차창)
    for t, sd in [(0.10, 12), (0.18, 22), (0.25, 33), (0.33, 44), (0.42, 55), (0.52, 66)]:
        spear = highpass(decay_exp(noise(0.10, seed=sd), tau=0.03), 2500)
        ring = gain(decay_exp(sine(1700 + sd * 5, 0.08), tau=0.022), 0.22)
        mix_at(out, gain(mix(spear, ring), 0.42), t, 1.0)
    out = trim(out, dur)
    out = env_points(out, [(0, 1.0), (dur - 0.14, 1.0), (dur, 0.0)])  # 끝 정리
    return fade_io(out, 0.004)


# ════════════════════════════ BGM ════════════════════════════
# 2026-06-12 전면 재작곡(사용자: '음악이 마음에 안 든다, 새로') —
# 드론 위주 → 또렷한 가야금 가락 + 굿거리/세마치/자진모리 장단 + 시김새(꺾는 음).
# 음계: 평조(장조풍 G A C D E) / 계면조(단조풍 A C D E G). 옥타브를 높여 선율을 살림.

def _giong(freq, dur, g=1.0, bright=0.5, seed=0):
    """가야금 한 음 — 빠른 어택 + 긴 감쇠."""
    return gain(ks_pluck(freq, dur, decay=0.9968, bright=bright, seed=seed), g)


def _bend(f0, f1, dur, g=0.8, seed=1):
    """시김새 — 음을 살짝 끌어 꺾는 음(2음 빠른 플럭)."""
    out = silence(dur)
    mix_at(out, _giong(f0, dur * 0.45, g * 0.7, 0.45, seed), 0.0, 1.0)
    mix_at(out, _giong(f1, dur * 0.7, g, 0.5, seed + 1), dur * 0.32, 1.0)
    return trim(out, dur)


def _melody(out, phrase, beat, base_seed=0, gmul=1.0):
    """phrase: [(beat, note, dur_beats[, gain]), ...] 를 out 에 얹는다."""
    total = len(out) / SR
    for i, ev in enumerate(phrase):
        b, nm, db = ev[0], ev[1], ev[2]
        g = (ev[3] if len(ev) > 3 else 0.8) * gmul
        t = b * beat
        if t >= total:
            continue
        ring = min(db * beat + 0.8, total - t - 0.02)
        if ring <= 0.05:
            continue
        mix_at(out, _giong(note(nm), ring, g, 0.5, base_seed + i), t, 1.0)


def _janggu_kung(g=1.0):
    return gain(decay_exp(sine_sweep(150, 60, 0.22, "exp"), tau=0.07), g)


def _janggu_deok(g=1.0):
    snap = decay_exp(highpass(noise(0.05, seed=4), 1400), tau=0.014)
    tone = gain(decay_exp(triangle(560, 0.05), tau=0.02), 0.5)
    return gain(mix(snap, tone), g)


def _gutgeori(out, beat, bars, t0=0.0, g=1.0):
    """굿거리 장단(12/8 단순화) — 마디마다 궁/채 배치."""
    cyc = beat * 4
    for bar in range(bars):
        base = t0 + bar * cyc
        if base >= len(out) / SR:
            break
        mix_at(out, _janggu_kung(0.85 * g), base + 0 * beat)
        mix_at(out, _janggu_deok(0.5 * g), base + 1 * beat)
        mix_at(out, _janggu_deok(0.4 * g), base + 1.5 * beat)
        mix_at(out, _janggu_kung(0.7 * g), base + 2 * beat)
        mix_at(out, _janggu_deok(0.55 * g), base + 3 * beat)
        mix_at(out, _janggu_deok(0.35 * g), base + 3.5 * beat)


def _soft_bass(out, roots, beat, bars_per=4):
    """마디 첫 박 저음 플럭 — 상시 드론 대신 은은한 토대."""
    total = len(out) / SR
    i = 0
    t = 0.0
    while t < total - 0.5:
        nm = roots[i % len(roots)]
        mix_at(out, lowpass(_giong(note(nm), 2.0, 0.5, 0.3, 700 + i), 500), t, 0.5)
        t += beat * bars_per
        i += 1


def bgm_village():
    """마을 — 평조 가야금 가락 + 굿거리 장단. 밝고 한적. 84박."""
    beat = 0.34
    total = round(84 * beat, 2)
    out = silence(total)
    P = [
        (0, "G4", 1, .85), (1, "A4", 1, .8), (2, "C5", 2, .9), (4, "D5", 1, .85), (5, "C5", 1, .8), (6, "A4", 2, .8),
        (8, "G4", 1, .8), (9, "A4", 1, .8), (10, "C5", 1, .85), (11, "D5", 1, .85), (12, "E5", 2, .95), (14, "D5", 2, .85),
        (16, "C5", 1, .85), (17, "A4", 1, .8), (18, "G4", 2, .85), (20, "E4", 1, .8), (21, "G4", 1, .8), (22, "A4", 2, .85),
        (24, "C5", 1, .85), (25, "D5", 1, .85), (26, "C5", 1, .8), (27, "A4", 1, .8), (28, "G4", 4, .9),
        (36, "D5", 1, .8), (37, "E5", 1, .85), (38, "D5", 1, .8), (39, "C5", 1, .8), (40, "A4", 2, .85), (42, "G4", 2, .85),
        (44, "C5", 2, .85), (46, "D5", 2, .85), (48, "E5", 1, .9), (49, "D5", 1, .8), (50, "C5", 2, .85),
        (52, "A4", 1, .8), (53, "G4", 1, .8), (54, "A4", 1, .8), (55, "C5", 1, .8), (56, "G4", 4, .9),
        (64, "C5", 2, .8), (66, "A4", 2, .8), (68, "G4", 2, .8), (70, "E4", 2, .8), (72, "G4", 4, .85),
        (80, "A4", 2, .7), (82, "G4", 2, .75),
    ]
    _melody(out, P, beat, base_seed=10)
    for b, (f0, f1) in [(12, ("D5", "E5")), (28, ("F4", "G4")), (48, ("D5", "E5"))]:
        mix_at(out, _bend(note(f0), note(f1), beat * 1.5, 0.5, b), b * beat - 0.05, 0.6)
    _gutgeori(out, beat, 21, g=0.7)
    _soft_bass(out, ["G3", "C3", "D3", "G3"], beat, 4)
    return fade_io(trim(out, total), 0.006)


def bgm_forest():
    """깊은 숲 — 계면조 그늘진 가락 + 느린 세마치(3박). 63박."""
    beat = 0.4
    total = round(63 * beat, 2)
    out = silence(total)
    G = [
        (0, "A4", 2, .8), (2, "C5", 1, .8), (3, "A4", 1, .75), (4, "G4", 2, .8), (6, "E4", 2, .75),
        (9, "A4", 1, .8), (10, "C5", 2, .85), (12, "D5", 1, .8), (13, "C5", 1, .75), (14, "A4", 3, .8),
        (18, "E4", 2, .75), (20, "G4", 1, .75), (21, "A4", 1, .8), (22, "C5", 2, .8),
        (27, "D5", 2, .85), (29, "E5", 1, .85), (30, "D5", 1, .8), (31, "C5", 2, .8), (33, "A4", 3, .8),
        (39, "G4", 2, .75), (41, "E4", 2, .75), (45, "A4", 2, .8), (47, "G4", 1, .75), (48, "E4", 3, .8),
        (54, "A4", 2, .7), (56, "C5", 2, .7), (58, "A4", 3, .75),
    ]
    _melody(out, G, beat, base_seed=30, gmul=0.92)
    for b, (f0, f1) in [(14, ("B4", "C5")), (33, ("B4", "C5")), (48, ("F4", "E4"))]:
        mix_at(out, _bend(note(f0), note(f1), beat * 1.6, 0.45, b), b * beat - 0.05, 0.55)
    cyc = beat * 3
    t = 0.0
    while t < total - 0.4:
        mix_at(out, _janggu_kung(0.6), t)
        mix_at(out, _janggu_deok(0.4), t + beat * 1)
        mix_at(out, _janggu_deok(0.45), t + beat * 2)
        t += cyc
    _soft_bass(out, ["A2", "E3", "A2", "D3"], beat, 3)
    return fade_io(trim(out, total), 0.006)


def bgm_boss():
    """절벽/제단 — 계면조 자진모리(빠른 4박) 몰이 + 전고. 80박."""
    beat = 0.273
    total = round(80 * beat, 2)
    out = silence(total)
    M = [
        (0, "A4", 1, .9), (1, "E4", 1, .8), (2, "A4", 1, .85), (3, "C5", 1, .85), (4, "D5", 2, .95), (6, "C5", 1, .85), (7, "A4", 1, .8),
        (8, "E4", 1, .8), (9, "G4", 1, .8), (10, "A4", 1, .85), (11, "C5", 1, .85), (12, "E5", 2, 1.0), (14, "D5", 2, .9),
        (16, "C5", 1, .85), (17, "A4", 1, .8), (18, "E4", 1, .8), (19, "G4", 1, .8), (20, "A4", 4, .95),
        (32, "D5", 1, .85), (33, "E5", 1, .9), (34, "D5", 1, .85), (35, "C5", 1, .8), (36, "A4", 2, .9), (38, "E4", 2, .85),
        (40, "A4", 1, .85), (41, "C5", 1, .85), (42, "D5", 1, .85), (43, "E5", 1, .9), (44, "A5", 4, 1.0),
        (56, "E5", 1, .9), (57, "D5", 1, .85), (58, "C5", 1, .8), (59, "A4", 1, .8), (60, "E4", 4, .9),
        (68, "A4", 2, .85), (70, "C5", 2, .85), (72, "A4", 4, .9),
    ]
    _melody(out, M, beat, base_seed=50, gmul=0.95)
    t = 0.0
    i = 0
    while t < total - 0.3:
        mix_at(out, _janggu_kung(0.8 if i % 4 == 0 else 0.5), t)
        mix_at(out, _janggu_deok(0.5), t + beat * 0.5)
        if i % 2 == 1:
            mix_at(out, _drum_buk(0.7, seed=i), t)
        t += beat
        i += 1
    _soft_bass(out, ["A2", "A2", "E2", "A2"], beat, 4)
    return fade_io(trim(out, total), 0.006)


def bgm_title():
    """타이틀 — 평조 가야금 독주, 느리고 단아하게. 52박."""
    beat = 0.5
    total = round(52 * beat, 2)
    out = silence(total)
    T = [
        (0, "G4", 2, .85), (2, "A4", 1, .8), (3, "C5", 1, .8), (4, "D5", 3, .9), (7, "C5", 1, .8),
        (8, "A4", 2, .8), (10, "G4", 2, .8), (12, "E4", 4, .85),
        (16, "G4", 1, .8), (17, "A4", 1, .8), (18, "C5", 2, .85), (20, "D5", 2, .85), (22, "E5", 3, .95), (25, "D5", 1, .85),
        (26, "C5", 2, .85), (28, "A4", 2, .8), (30, "G4", 4, .9),
        (36, "C5", 2, .8), (38, "D5", 2, .8), (40, "C5", 1, .8), (41, "A4", 1, .8), (42, "G4", 4, .9),
        (48, "A4", 2, .7), (50, "G4", 2, .75),
    ]
    _melody(out, T, beat, base_seed=70)
    for b, (f0, f1) in [(4, ("C5", "D5")), (22, ("D5", "E5"))]:
        mix_at(out, _bend(note(f0), note(f1), beat * 1.4, 0.5, b), b * beat - 0.05, 0.6)
    _soft_bass(out, ["G3", "C3", "G3", "E3"], beat, 4)
    mix_at(out, _drum_buk(0.45, seed=2), 0.3)
    mix_at(out, _drum_buk(0.45, seed=3), total * 0.5)
    return fade_io(trim(out, total), 0.006)


def bgm_night():
    """밤(고을 야경/폐사지) — 계면조 느린 가락 + 풀벌레. 51박."""
    beat = 0.47
    total = round(51 * beat, 2)
    out = silence(total)
    N = [
        (0, "A4", 3, .7), (3, "G4", 1, .65), (4, "E4", 3, .7), (7, "G4", 1, .65),
        (8, "A4", 2, .72), (10, "C5", 2, .75), (12, "A4", 4, .7),
        (16, "E4", 2, .65), (18, "G4", 2, .68), (20, "A4", 3, .72), (23, "C5", 1, .7),
        (24, "D5", 2, .75), (26, "C5", 2, .7), (28, "A4", 4, .72),
        (36, "G4", 2, .66), (38, "E4", 2, .66), (40, "A4", 4, .7), (48, "A4", 2, .6),
    ]
    _melody(out, N, beat, base_seed=90, gmul=0.85)
    _soft_bass(out, ["A2", "D3", "A2", "E3"], beat, 4)
    rng = random.Random(3)
    t = 1.0
    while t < total - 1.2:
        c = silence(0.2)
        for k in range(8):
            mix_at(c, decay_exp(sine(4300 + rng.uniform(-60, 60), 0.012), tau=0.006), k * 0.022, 1.0)
        mix_at(out, c, t, 0.13)
        t += 2.0 + rng.uniform(-0.2, 0.3)
    return fade_io(trim(out, total), 0.006)


def _drum_buk(g=1.0, seed=8):
    body = decay_exp(sine_sweep(82, 38, 0.45, "exp"), tau=0.16)
    skin = gain(decay_exp(lowpass(noise(0.08, seed=seed), 300), tau=0.03), 0.35)
    return gain(mix(body, skin), g)


# ════════════════════════ 해원(解冤) 전용 BGM ════════════════════════
# 서사 정서: 산나비식 비장미 · 강·물·등불 모티프 · 계면조(단조풍) 중심.
# 음계 핵심: 계면조 A C D E G (A 단조풍). 시김새(꺾는 음) 적극 사용.
# 장단: river/grief → 느린 3박 세마치 또는 무박 독주.
#        requiem → 중간 4박 굿거리 → 후반 잔잔.

def _water_shimmer(dur, g=0.06, seed=200):
    """물 흐름 배경 — 고역 노이즈를 아주 낮게 깔아 강물 감촉 표현.
    lowpass 800Hz 로 쉿쉿 소리 죽이고, 매우 낮은 게인으로 적막감 유지."""
    n = noise(dur, seed=seed)
    n = lowpass(n, 800)
    env = []
    total = int(SR * dur)
    for i in range(total):
        t = i / SR
        # 숨결처럼 천천히 오가는 진폭 변동 (주기 ~7초)
        env.append(n[i] * (0.7 + 0.3 * math.sin(2 * math.pi * t / 7.0)))
    return gain(env, g)


def _jinggling_drone(freq, dur, g=0.18):
    """느린 드론 — sine 에 삼각파 살짝 섞어 가야금 공명함 질감 추가."""
    s = sine(freq, dur)
    t = gain(triangle(freq * 0.998, dur), 0.15)   # 미세 이조로 살짝 떨림
    return gain(mix(s, t), g)


def _seomachi_janggu(out, beat, bars, t0=0.0, g=1.0):
    """세마치 장단(3박 단위) — 느린 진혼 장단.
    궁(1박) · 공박(2박) · 채(3박) 구조로 성기고 무거움."""
    cyc = beat * 3
    for bar in range(bars):
        base = t0 + bar * cyc
        if base >= len(out) / SR:
            break
        mix_at(out, _janggu_kung(0.8 * g), base + 0.0 * beat)
        mix_at(out, _janggu_deok(0.45 * g), base + 2.0 * beat)


def _hollow_wind(dur, g=0.05, seed=300):
    """텅 빈 바람 — 5굽이용 극저음 노이즈 베드.
    highpass 120Hz → 중역 잡소리 없는 바람 질감."""
    n = noise(dur, seed=seed)
    n = highpass(n, 120)
    n = lowpass(n, 600)
    # 2~4초 주기 완만한 숨결
    total = int(SR * dur)
    env = []
    for i in range(total):
        t = i / SR
        env.append(n[i] * (0.5 + 0.5 * abs(math.sin(math.pi * t / 3.2))))
    return gain(env, g)


def bgm_haewon_river():
    """강가 진혼 — 프롤로그·1굽이·2굽이.
    계면조 A C D E G 느린 가야금 독주 + 옅은 세마치 장단 + 물 흐름 질감.
    정서: 비장+쓸쓸. 혼 달래는 강가 새벽.
    구조: 전반(0~20s) 독주 위주, 후반(20s~) 장단 합류 → 감쇠 마무리. 약 40s."""
    beat = 0.52           # 느린 세마치 — 1박 0.52s, 3박 = 1.56s
    total = 40.0
    out = silence(total)

    # 선율: 계면조 A 중심. 낮은 음역(E4~D5)으로 무게감.
    # 시김새 강조 — 꺾는 음을 4~5곳에 배치.
    R = [
        # 1절 (0~15s): 홀로 강가에 선 느낌. 음들 사이 공백 넓게.
        (0,  "A4", 3, .80),
        (3,  "G4", 1, .72),
        (4,  "E4", 4, .78),
        (8,  "A4", 2, .80),
        (10, "C5", 2, .82),
        (12, "A4", 3, .75),
        (15, "G4", 1, .70),
        # 2절 (16~28s): 조금 더 움직임. 강물 위 등불이 흔들리듯.
        (16, "E4", 2, .72),
        (18, "G4", 1, .75),
        (19, "A4", 2, .80),
        (21, "C5", 1, .80),
        (22, "D5", 2, .82),
        (24, "C5", 1, .78),
        (25, "A4", 2, .76),
        (27, "G4", 2, .70),
        # 3절 (29~39s): 점차 수그러듦 — 혼 가라앉음.
        (29, "E4", 2, .68),
        (31, "A4", 3, .72),
        (34, "G4", 2, .64),
        (36, "E4", 3, .60),
    ]
    _melody(out, R, beat, base_seed=110, gmul=0.90)

    # 시김새: G4→A4, A4→C5, C5→D5 — 계면조 특유의 상행 꺾음
    for b, (f0, f1) in [
        (4,  ("F#4", "G4")),   # E4 뒤 G4 진입 꺾음 (F#4는 계면 경과음)
        (12, ("B4",  "C5")),   # A4→C5 꺾음
        (22, ("C#5", "D5")),   # D5 진입 꺾음
        (34, ("A4",  "G4")),   # 하행 꺾음 — 내려놓음
    ]:
        mix_at(out, _bend(note(f0), note(f1), beat * 1.6, 0.45, b + 100), b * beat - 0.04, 0.50)

    # 세마치 장단 — 20s 이후부터 합류, 아주 가볍게 (g=0.45)
    _seomachi_janggu(out, beat, bars=13, t0=20.0, g=0.45)

    # 저음 토대: A2 E2 D2 A2 — 계면조 뿌리음
    _soft_bass(out, ["A2", "E2", "D2", "A2"], beat, bars_per=3)

    # 물 흐름 질감 — 전체 깔기
    mix_at(out, _water_shimmer(total, g=0.055, seed=211), 0.0, 1.0)

    # 저음 드론 — A2 옥타브. 아주 낮게 공간감.
    mix_at(out, _jinggling_drone(note("A2"), total, g=0.12), 0.0, 1.0)

    return fade_io(trim(out, total), 0.008)


def bgm_haewon_grief():
    """3굽이 죄의 확인 — 더 어둡고 가라앉은 진혼.
    계면조 A 낮은 음역(E3~A4). 느린 세마치. 시김새(하행 꺾음) 강조.
    정서: 무겁게 가라앉음. 고개 숙인 채 걷는 음악.
    구조: 전반 거의 단음 독주(공백 극대화), 후반 장단+저음 드론. 약 38s."""
    beat = 0.58           # 더 느림 — 무게감
    total = 38.0
    out = silence(total)

    # 선율: A3 옥타브 낮춤. E3~A4 좁은 음역.
    # 공백을 넓게 — 침묵이 죄책감.
    GR = [
        (0,  "E4", 4, .78),
        (4,  "A4", 2, .80),
        (6,  "G4", 2, .72),
        (8,  "E4", 4, .75),
        (13, "A4", 3, .78),
        (16, "G4", 2, .70),
        (18, "E4", 2, .72),
        (20, "D4", 4, .75),    # D4 — 계면조 하행의 무게
        (25, "A3", 3, .70),    # A3 저음 — 최저점 도달
        (28, "C4", 2, .72),
        (30, "E4", 2, .74),
        (32, "A4", 3, .72),
        (35, "G4", 2, .62),    # 수그러듦
    ]
    _melody(out, GR, beat, base_seed=120, gmul=0.88)

    # 시김새: 하행 꺾음 강조(내려놓음·죄책)
    for b, (f0, f1) in [
        (4,  ("B4",  "A4")),   # A4 도달 꺾음
        (13, ("Bb4", "A4")),   # 반음 하행 — 더 쓸쓸
        (28, ("Db4", "C4")),   # C4 진입 반음 꺾음
        (32, ("B4",  "A4")),
    ]:
        mix_at(out, _bend(note(f0), note(f1), beat * 1.8, 0.50, b + 120), b * beat - 0.04, 0.55)

    # 세마치 — 처음부터 있되 극히 낮게(g=0.35), 15s 이후 약간 강해짐
    _seomachi_janggu(out, beat, bars=8, t0=0.0, g=0.35)
    _seomachi_janggu(out, beat, bars=8, t0=14.0, g=0.50)

    # 저음 토대: E2 A2 D2 A2 — 계면조 뿌리. 더 저음.
    _soft_bass(out, ["E2", "A2", "D2", "A2"], beat, bars_per=3)

    # 아주 저음 드론 — E2. 죄책감의 무게.
    mix_at(out, _jinggling_drone(note("E2"), total, g=0.10), 0.0, 1.0)

    # 물 흐름 — 더 옅게 (강이 멀어진 느낌)
    mix_at(out, _water_shimmer(total, g=0.035, seed=220), 0.0, 1.0)

    return fade_io(trim(out, total), 0.008)


def bgm_haewon_hollow():
    """5굽이 빈 고을·빈 집 — 공허·적막.
    선율 최소화: 띄엄띄엄 단음만. 장단 없음.
    침묵과 바람 노이즈가 핵심. 약 42s.
    정서: 희생이 헛됨. 텅 빈 안방, 윤슬의 비녀."""
    beat = 0.65          # 쓰지만 음표 간격이 넓어 장단 느낌 없음
    total = 42.0
    out = silence(total)

    # 선율: 극소수 음표, 간격 넓게, 낮은 음역, 낮은 게인
    # 각 음 뒤 긴 침묵 — 빈 공간이 표현의 핵심.
    HL = [
        (0,  "E4",  5, .62),
        (6,  "A4",  3, .60),
        (11, "G4",  4, .55),
        (17, "E4",  3, .58),
        (22, "A3",  5, .55),   # A3 저음 — 텅 빈 방
        (30, "C4",  3, .52),
        (35, "E4",  4, .50),
        (40, "A3",  2, .45),   # 마지막 — 사라지듯
    ]
    _melody(out, HL, beat, base_seed=130, gmul=0.80)

    # 시김새 단 2곳 — 위로가 아니라 탄식
    for b, (f0, f1) in [
        (6,  ("Bb4", "A4")),   # 반음 하행 탄식
        (30, ("Db4", "C4")),
    ]:
        mix_at(out, _bend(note(f0), note(f1), beat * 2.0, 0.40, b + 130), b * beat - 0.04, 0.40)

    # 바람 노이즈 베드 — 전체. 선율보다 이게 주인공.
    mix_at(out, _hollow_wind(total, g=0.055, seed=310), 0.0, 1.0)

    # 드론 없음 — 진짜 공허. 저음 토대도 없음.
    # 단, 아주 낮은 A2 sine 한 번 — 윤슬 이름이 처음 또렷이 떠오르는 순간(22s)
    yun_moment = silence(8.0)
    mix_at(yun_moment, gain(sine(note("A2"), 6.0), 0.10), 0.0, 1.0)
    yun_moment = env_points(yun_moment, [(0, 0.0), (1.5, 1.0), (6.0, 1.0), (8.0, 0.0)])
    mix_at(out, yun_moment, 22.0, 1.0)

    return fade_io(trim(out, total), 0.010)


def bgm_haewon_requiem():
    """6굽이·엔딩 최종 진혼 — 비장하게 흐르다 승화.
    계면조 A. 전반(0~22s): 가야금 + 굿거리 장단 + 북. 비장한 클라이맥스.
    후반(22s~): 장단 빠지고 가야금 독주만 → 잔잔히 마무리. 약 44s.
    정서: 용서·놓아줌·승화. 첫 햇살이 강에 닿음."""
    beat = 0.40           # 굿거리 4박 = 1.6s. 전반은 단호하게.
    total = 44.0
    out = silence(total)

    # 전반 선율(0~22s): 계면조 A — 비장하되 흔들림 없이.
    # 보스곡(bgm_boss)보다 느리고 숙연함. E5까지 상행 → 절정.
    RQ1 = [
        (0,  "A4", 2, .88),
        (2,  "C5", 1, .85),
        (3,  "A4", 1, .80),
        (4,  "G4", 2, .82),
        (6,  "E4", 2, .80),
        (8,  "A4", 2, .88),
        (10, "D5", 2, .90),
        (12, "E5", 3, .95),   # 절정 1 — 비장의 정점
        (15, "D5", 1, .88),
        (16, "C5", 2, .85),
        (18, "A4", 4, .88),   # 넓은 여운
        # 재현부 (22s≒22/beat 박)
        (28, "E4", 2, .80),
        (30, "G4", 1, .78),
        (31, "A4", 2, .82),
        (33, "C5", 2, .80),
        (35, "A4", 3, .78),
    ]
    _melody(out, RQ1, beat, base_seed=140, gmul=0.95)

    # 후반 선율(~38s): 게인 낮추고 음 성기게 — 승화·고요
    RQ2 = [
        (39, "G4", 2, .65),
        (41, "E4", 2, .62),
        (43, "A3", 2, .55),   # A3 — 마지막 내려놓음
        (46, "A4", 3, .50),   # 아주 낮게 사라지듯
    ]
    _melody(out, RQ2, beat, base_seed=145, gmul=0.80)

    # 시김새
    for b, (f0, f1) in [
        (0,  ("G4",  "A4")),   # 첫 A4 진입 꺾음
        (10, ("C#5", "D5")),   # D5 상행 꺾음
        (12, ("D#5", "E5")),   # 절정 E5 꺾음
        (33, ("B4",  "C5")),
    ]:
        mix_at(out, _bend(note(f0), note(f1), beat * 1.5, 0.50, b + 140), b * beat - 0.04, 0.55)

    # 전반 굿거리 장단(0~22s) — bgm_forest 수준 게인
    _gutgeori(out, beat, bars=14, t0=0.0, g=0.65)

    # 북(전고) — 비장한 포인트: 4박마다 한 번
    t_buk = 0.0
    bi = 0
    while t_buk < 22.0:
        mix_at(out, _drum_buk(0.55, seed=bi + 10), t_buk)
        t_buk += beat * 4
        bi += 1

    # 저음 토대(전반)
    _soft_bass(out, ["A2", "E2", "A2", "D2"], beat, bars_per=4)

    # 후반(22s~) — 드론 빠지고 물 질감 + 아주 낮은 A2 드론만
    mix_at(out, _water_shimmer(total - 22.0, g=0.06, seed=230), 22.0, 1.0)
    ending_drone = gain(sine(note("A2"), total - 22.0), 0.08)
    ending_drone = env_points(ending_drone, [(0, 0.0), (3.0, 1.0), (total - 24.0, 1.0), (total - 22.0, 0.0)])
    mix_at(out, ending_drone, 22.0, 1.0)

    return fade_io(trim(out, total), 0.010)


# ═══════════════════════ 파형 오버뷰 PNG ═══════════════════════
def waveform_sheet(specs, png_path):
    """파형 미리보기 — 눈으로 엔벨로프/클릭/무음 검수 (Pillow 있을 때만)."""
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        return None
    import wave as wv
    import struct as st
    W, ROW, GAP = 1100, 64, 14
    H = (ROW + GAP) * len(specs) + GAP
    img = Image.new("RGB", (W, H), (26, 22, 18))
    dr = ImageDraw.Draw(img)
    for r, sp in enumerate(specs):
        with wv.open(sp["path"], "rb") as f:
            data = st.unpack("<%dh" % f.getnframes(), f.readframes(f.getnframes()))
        y0 = GAP + r * (ROW + GAP)
        mid = y0 + ROW // 2
        dr.rectangle([150, y0, W - 10, y0 + ROW], outline=(75, 64, 53))
        dr.line([150, mid, W - 10, mid], fill=(46, 40, 32))
        cols = W - 162
        step = max(1, len(data) // cols)
        for cx in range(cols):
            seg = data[cx * step:(cx + 1) * step]
            if not seg:
                break
            hi = max(seg) / 32768.0
            lo = min(seg) / 32768.0
            dr.line([152 + cx, mid - int(hi * (ROW // 2 - 2)),
                     152 + cx, mid - int(lo * (ROW // 2 - 2))],
                    fill=(201, 168, 86))
        name = os.path.basename(sp["path"])
        dr.text((10, y0 + 8), name, fill=(245, 235, 216))
        dr.text((10, y0 + 26), "%.2fs  pk %.1f  rms %.1f" %
                (sp["duration_s"], sp["peak_dbfs"], sp["rms_dbfs"]),
                fill=(140, 126, 111))
    img.save(png_path)
    return png_path


# ════════════════════════════ main ════════════════════════════
def main():
    jobs = [
        # (디렉터리, 이름, 생성함수, 루프 여부)
        (SFX, "attack", sfx_attack, False),
        (SFX, "hurt", sfx_hurt, False),
        (SFX, "hit", sfx_hit, False),
        (SFX, "die", sfx_die, False),
        (SFX, "pickup", sfx_pickup, False),
        (SFX, "potion", sfx_potion, False),
        (SFX, "jump", sfx_jump, False),
        (SFX, "dodge", sfx_dodge, False),
        (SFX, "ui_click", sfx_ui_click, False),
        (SFX, "jingle_quest", sfx_jingle_quest, False),
        (SFX, "ultimate", sfx_ultimate, False),
        (BGM, "village", bgm_village, True),
        (BGM, "forest", bgm_forest, True),
        (BGM, "boss", bgm_boss, True),
        (BGM, "night", bgm_night, True),
        (BGM, "title", bgm_title, True),
        # 해원(解冤) 전용 BGM — 굽이별 정서 분화
        (BGM, "haewon_river",   bgm_haewon_river,   True),
        (BGM, "haewon_grief",   bgm_haewon_grief,   True),
        (BGM, "haewon_hollow",  bgm_haewon_hollow,  True),
        (BGM, "haewon_requiem", bgm_haewon_requiem, True),
    ]
    specs = []
    lines = ["hohwan-gidam audio spec  (22050 Hz / 16-bit / mono, peak limit -3 dBFS)",
             "%-22s %9s %10s %10s  %s" % ("file", "dur(s)", "peak dBFS", "rms dBFS", "loop"),
             "-" * 68]
    manifest = {"sample_rate": SR, "bit_depth": 16, "channels": 1,
                "sfx": {}, "bgm": {}}
    for d, name, fn, loop in jobs:
        path = os.path.join(d, name + ".wav")
        sp = write_wav(path, fn())
        sp["loop"] = loop
        specs.append(sp)
        rel = os.path.relpath(path, ROOT).replace("\\", "/")
        lines.append("%-22s %9.3f %10.2f %10.2f  %s" %
                     (rel.split("audio/")[-1], sp["duration_s"],
                      sp["peak_dbfs"], sp["rms_dbfs"], "yes" if loop else "no"))
        entry = {"file": rel.split("audio/")[-1], "duration_s": sp["duration_s"],
                 "peak_dbfs": sp["peak_dbfs"], "rms_dbfs": sp["rms_dbfs"],
                 "loop": loop}
        manifest["bgm" if loop else "sfx"][name] = entry
        print(lines[-1])
    os.makedirs(SHEETS, exist_ok=True)
    spec_path = os.path.join(SHEETS, "audio_spec.txt")
    with open(spec_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    mani_path = os.path.join(ROOT, "assets", "audio", "manifest.json")
    with open(mani_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    png = waveform_sheet(specs, os.path.join(SHEETS, "audio_waveforms.png"))
    print("spec  :", spec_path)
    print("mani  :", mani_path)
    if png:
        print("waves :", png)


if __name__ == "__main__":
    main()
