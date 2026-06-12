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


# ════════════════════════════ BGM ════════════════════════════
# 톤 방향 (2026-06-12 사용자 피드백): "가볍다" → 비장하게.
# - 선법: 계면조 (A 단조 5음계: A C D E G) — 하강 선율 위주
# - 음역 한 옥타브 하강, 깊은 드론(근음+5도) 토대
# - 북(법고)·장구 타악, 대금풍 지속음(비브라토+숨결)

def _drum_buk(g=1.0, seed=8):
    """북 — 깊은 울림 (쿵...). 서브 스윕 + 가죽 노이즈."""
    body = decay_exp(sine_sweep(82, 38, 0.45, "exp"), tau=0.16)
    skin = gain(decay_exp(lowpass(noise(0.08, seed=seed), 300), tau=0.03), 0.35)
    return gain(mix(body, skin), g)


def _daegeum(freq, dur, vib=0.009, breath=0.10):
    """대금풍 지속음 — 느린 어택, 5Hz 비브라토, 숨결 노이즈."""
    n = int(SR * dur)
    ph = 0.0
    tone = []
    for i in range(n):
        t = i / SR
        f = freq * (1.0 + vib * math.sin(2 * math.pi * 5.0 * t))
        ph += 2 * math.pi * f / SR
        tone.append(math.sin(ph) + 0.28 * math.sin(2 * ph) + 0.10 * math.sin(3 * ph))
    br = gain(lowpass(noise(dur, seed=int(freq)), freq * 3.0), breath)
    w = mix(tone, br)
    return env_points(w, [(0, 0.0), (0.28, 1.0), (dur * 0.7, 0.85), (dur, 0.0)])


def _drone_fifth(root_hz, total, lfo_period=8.0, g_root=0.30, g_fifth=0.12, g_oct=0.10):
    """근음 + 5도 + 옥타브 드론, 느린 맥동."""
    n = int(SR * total)
    d1 = sine(root_hz, total)
    d2 = sine(root_hz * 1.5, total)
    d3 = sine(root_hz * 2.0, total)
    out = []
    for i in range(n):
        t = i / SR
        lfo = 1.0 + 0.18 * math.sin(2 * math.pi * t / lfo_period)
        out.append((g_root * d1[i] + g_fifth * d2[i] + g_oct * d3[i]) * lfo)
    return out


def bgm_village():
    """마을 — 비장하게: 계면조 [A C D E G] 하강 가락, 60bpm, 깊은 드론+북.
    60bpm(박 1.0s) × 32박 = 32.0s, 8마디."""
    beat = 1.0
    total = 32 * beat
    out = silence(total)
    # 토대 — A2 드론 (근음+5도), 8s 주기 맥동 → 32s 에 4회 (루프 정합)
    mix_at(out, _drone_fifth(110.0, total, lfo_period=8.0,
                             g_root=0.26, g_fifth=0.10, g_oct=0.07), 0.0, 1.0)
    # 가락 — 낮은 가야금, 하강 위주 (한이 서린 계면조)
    melody = [
        (0, "A3"), (2, "G3"), (3, "E3"),
        (4, "A3"), (6, "C4"), (7, "A3"),
        (8, "G3"), (10, "E3"), (11, "D3"),
        (12, "E3"), (14, "A2"),
        (16, "C4"), (18, "A3"), (19, "G3"),
        (20, "E3"), (22, "G3"), (23, "A3"),
        (24, "G3"), (26, "E3"), (27, "D3"),
        (28, "C3"), (30, "A2"),
    ]
    rng = random.Random(7)
    for b, nm in melody:
        g = 0.72 + rng.uniform(-0.07, 0.07)
        ring = min(2.6, total - b * beat - 0.02)
        mix_at(out, ks_pluck(note(nm), ring, decay=0.9972, bright=0.42,
                             seed=100 + b), b * beat, g)
    # 시김새 — 앞꾸밈 (떠는 손)
    for b, nm in [(4, "G3"), (16, "D4"), (24, "A3")]:
        mix_at(out, ks_pluck(note(nm), 0.22, decay=0.994, bright=0.4,
                             seed=300 + b), b * beat - 0.08, 0.26)
    # 북 — 2마디마다 한 번, 깊게 (의식의 무게)
    for k in range(4):
        mix_at(out, _drum_buk(0.62, seed=8 + k), k * 8 * beat)
    # 대금 — 후반 8박에 긴 한숨 한 가락 (루프 직전 여운)
    mix_at(out, _daegeum(note("E3"), 3.5, breath=0.08), 24 * beat, 0.30)
    mix_at(out, _daegeum(note("A2"), 4.0, breath=0.06), 28 * beat - 0.5, 0.26)
    return fade_io(trim(out, total), 0.005)


def bgm_forest():
    """숲 — 어둑한 긴장: 디튠 드론 + 심장박동 북 + 반음(Bb) 불협 스침. 24s."""
    total = 24.0
    n = int(SR * total)
    # 드론: A2 디튠 페어 + A1 서브 — 느린 LFO (8s 주기 → 24s 에 3회)
    d1 = sine(110.0, total)
    d2 = sine(110.8, total)
    d0 = sine(55.0, total)
    out = []
    for i in range(n):
        t = i / SR
        lfo = 1.0 + 0.22 * math.sin(2 * math.pi * t / 8.0)
        out.append((0.18 * d1[i] + 0.18 * d2[i] + 0.16 * d0[i]) * lfo)
    # 심장박동 — 쿵-쿵 더블 비트, 3s 주기 (다가오는 것의 발소리처럼)
    t = 0.6
    while t < total - 1.0:
        mix_at(out, _drum_buk(0.45, seed=int(t * 7)), t)
        mix_at(out, _drum_buk(0.30, seed=int(t * 7) + 1), t + 0.42)
        t += 3.0
    # 드문 저음 플럭 — 계면조, 낮게
    events = [(1.8, "A2"), (5.6, "C3"), (9.1, "E3"), (12.6, "D3"),
              (16.2, "A2"), (19.7, "G3"), (21.8, "E3")]
    rng = random.Random(13)
    for et, nm in events:
        ring = min(2.4, total - et - 0.02)
        g = 0.55 + rng.uniform(-0.08, 0.08)
        mix_at(out, ks_pluck(note(nm), ring, decay=0.997, bright=0.38,
                             seed=int(et * 10)), et, g)
    # 반음 불협 — Bb 가 두 번 스치고 사라짐 (괴담의 한기)
    for et in (7.5, 18.4):
        mix_at(out, _daegeum(note("Bb2"), 2.2, vib=0.012, breath=0.14), et, 0.16)
    # 숨결 노이즈
    breath = gain(lowpass(noise(total, seed=99), 700), 0.05)
    breath = env_points(breath, [(0, 0.6), (12.0, 1.0), (24.0, 0.6)])
    mix_at(out, breath, 0.0, 1.0)
    return fade_io(trim(out, total), 0.005)


def _drum_kung(g=1.0):
    """장구 궁편 — 낮은 울림 (쿵)."""
    body = decay_exp(sine_sweep(135, 52, 0.20, "exp"), tau=0.06)
    return gain(body, g)


def _drum_deok(g=1.0):
    """장구 채편 — 높은 딱 (덕)."""
    snap = decay_exp(highpass(noise(0.05, seed=5), 1500), tau=0.012)
    tone = gain(decay_exp(triangle(720, 0.05), tau=0.015), 0.5)
    return gain(mix(snap, tone), g)


def _drum_hat(g=1.0, seed=6):
    """노이즈 하이햇."""
    return gain(decay_exp(highpass(noise(0.03, seed=seed), 3500), tau=0.008), g)


def bgm_boss():
    """보스 — 전고(戰鼓): 북+장구 중첩, 5도 드론 벽, 대금 하강 전호곡.
    100bpm(박 0.6s) × 32박 = 19.2s, 8마디."""
    beat = 0.6
    total = 32 * beat
    out = silence(total)
    n = int(SR * total)
    # 드론 벽 — A1+E2+A2 적층, 2마디 단위로 A↔Bb 반음 상승 긴장
    freqs = []
    for i in range(n):
        bar = int((i / SR) / (4 * beat))
        freqs.append(55.0 if (bar // 2) % 2 == 0 else note("Bb1"))
    drone = mix(gain(sine_freqs(freqs), 0.42),
                gain(sine_freqs(freqs, mul=1.5), 0.18),
                gain(sine_freqs(freqs, mul=2.0), 0.20),
                gain(sine_freqs(freqs, mul=3.0), 0.07))
    drone = [s * (0.85 + 0.15 * math.sin(2 * math.pi * (i / SR) / (4 * beat)))
             for i, s in enumerate(drone)]
    mix_at(out, drone, 0.0, 0.9)
    # 전고 — 북(법고)이 마디 머리를 치고 장구가 사이를 모는 구조
    for bar in range(8):
        t0 = bar * 4 * beat
        e = beat / 2.0
        mix_at(out, _drum_buk(1.0, seed=bar), t0)              # 쿵 (북)
        mix_at(out, _drum_deok(0.55), t0 + 0 * e)
        mix_at(out, _drum_deok(0.40), t0 + 2 * e)              # 기
        mix_at(out, _drum_deok(0.62), t0 + 3 * e)              # 덕
        mix_at(out, _drum_kung(0.75), t0 + 4 * e)              # 쿵 (장구)
        mix_at(out, _drum_deok(0.66), t0 + 6 * e)              # 덕
        if bar % 2 == 1:
            mix_at(out, _drum_buk(0.7, seed=10 + bar), t0 + 6 * e)  # 몰아치는 겹북
        for k in range(8):
            mix_at(out, _drum_hat(0.10 if k % 2 == 0 else 0.06,
                                  seed=bar * 8 + k), t0 + k * e)
    # 전호곡 — 대금풍 하강 외침 (E4→D4→C4→A3), 4마디마다
    cry = [("E4", 0), ("D4", 1.0), ("C4", 2.0), ("A3", 3.0)]
    for rep in (0, 4):
        base = rep * 4 * beat + 0.3
        for nm, dt in cry:
            mix_at(out, _daegeum(note(nm), 1.3, vib=0.014, breath=0.12),
                   base + dt * 1.05, 0.34)
    return fade_io(trim(out, total), 0.005)


def bgm_title():
    """타이틀 — 비장한 서곡: 깊은 드론 + 대금 독주 + 먼 북. 24s."""
    total = 24.0
    out = silence(total)
    # 드론 — A1 근음+5도, 12s 주기 맥동 → 2회 (루프 정합)
    mix_at(out, _drone_fifth(55.0, total, lfo_period=12.0,
                             g_root=0.34, g_fifth=0.14, g_oct=0.12), 0.0, 1.0)
    # 대금 독주 — 긴 하강 가락 (한 서린 독백)
    solo = [(1.0, "A3", 3.2), (4.6, "C4", 2.4), (7.4, "G3", 3.4),
            (11.2, "E3", 3.8), (15.6, "D3", 2.6), (18.6, "A2", 4.6)]
    for t, nm, d in solo:
        mix_at(out, _daegeum(note(nm), d, vib=0.011, breath=0.10), t, 0.42)
    # 먼 북 — 12s 마다 (산사의 법고처럼)
    mix_at(out, _drum_buk(0.55, seed=3), 0.2)
    mix_at(out, _drum_buk(0.55, seed=4), 12.2)
    # 낮은 가야금 한 줄 — 루프 이음새 부드럽게
    mix_at(out, ks_pluck(note("A2"), 3.0, decay=0.9975, bright=0.35, seed=900), 21.5, 0.30)
    return fade_io(trim(out, total), 0.005)


def bgm_night():
    """밤 — 드론 + 바람 + 풀벌레 트릴. 20s."""
    total = 20.0
    n = int(SR * total)
    # 드론: D2 + A2 + D3, 느린 LFO (10s 주기 → 2회 완주, 루프 정합)
    d1, d2, d3 = sine(note("D2"), total), sine(110.0, total), sine(note("D3"), total)
    out = []
    for i in range(n):
        t = i / SR
        lfo = 1.0 + 0.15 * math.sin(2 * math.pi * t / 10.0)
        out.append((0.28 * d1[i] + 0.13 * d2[i] + 0.09 * d3[i]) * lfo)
    # 바람 — 컷오프·세기 느린 변조 (주기 10s/(20/3)s — 20s 에 정수 회)
    wn = noise(total, seed=77)
    cut = []
    for i in range(n):
        t = i / SR
        cut.append(420 + 320 * math.sin(2 * math.pi * t / 10.0)
                   + 230 * math.sin(2 * math.pi * t * 3 / 20.0 + 1.3))
    wind = lowpass(wn, cut)
    wind = [s * (0.65 + 0.35 * math.sin(2 * math.pi * (i / SR) / 20.0))
            for i, s in enumerate(wind)]
    mix_at(out, wind, 0.0, 0.42)
    # 풀벌레 — 고음 짧은 트릴 (펄스 8개 묶음), 두 마리 교차
    def chirp(f, seed):
        c = silence(0.20)
        for k in range(8):
            p = decay_exp(sine(f, 0.013), tau=0.006)
            mix_at(c, p, k * 0.022, 1.0)
        return c
    rng = random.Random(3)
    t = 0.8
    while t < 18.6:                                   # 루프 이음새 앞은 비움
        mix_at(out, chirp(4300 + rng.uniform(-80, 80), 0), t, 0.15)
        t += 1.7 + rng.uniform(-0.15, 0.15)
    t = 1.7
    while t < 18.2:
        mix_at(out, chirp(4900 + rng.uniform(-80, 80), 1), t, 0.10)
        t += 2.3 + rng.uniform(-0.2, 0.2)
    return fade_io(trim(out, total), 0.005)


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
        (BGM, "village", bgm_village, True),
        (BGM, "forest", bgm_forest, True),
        (BGM, "boss", bgm_boss, True),
        (BGM, "night", bgm_night, True),
        (BGM, "title", bgm_title, True),
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
