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
    blips = [(0.02, 320), (0.10, 430), (0.19, 370), (0.27, 540),
             (0.35, 460), (0.42, 620)]
    for i, (t, f) in enumerate(blips):
        b = decay_exp(sine_sweep(f, f * 1.8, 0.05, "exp"), tau=0.025)
        mix_at(out, b, t, 0.8)
    fizz = gain(lowpass(noise(0.50, seed=41), 1800), 0.10)
    fizz = env_points(fizz, [(0, 0.3), (0.25, 1.0), (0.50, 0.0)])
    mix_at(out, fizz, 0.0, 1.0)
    return fade_io(trim(out, 0.50), 0.003)


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
    mix_at(out, bell(note("G5"), 0.30), 0.44, 1.00)
    return fade_io(trim(out, 1.0), 0.004)


# ════════════════════════════ BGM ════════════════════════════
def bgm_village():
    """마을 — 평조 5음계 [G3 A3 C4 D4 E4] 가야금풍 플럭, 잔잔한 4/4.
    80bpm(박 0.75s) × 32박 = 24.0s, 8마디."""
    beat = 0.75
    total = 32 * beat
    out = silence(total)
    melody = [  # (박, 음) — G 중심 평조 가락, 마지막은 여운으로 루프 연결
        (0, "G3"), (1, "A3"), (2, "C4"), (3, "D4"),
        (4, "E4"), (5, "D4"), (6, "C4"), (7, "A3"),
        (8, "C4"), (9, "D4"), (10, "E4"),
        (12, "D4"), (13, "C4"), (14, "A3"), (15, "G3"),
        (16, "A3"), (17, "C4"), (18, "D4"), (19, "E4"),
        (20, "E4"), (22, "D4"), (23, "C4"),
        (24, "A3"), (25, "G3"), (26, "A3"), (27, "C4"),
        (28, "A3"), (29, "G3"),
    ]
    rng = random.Random(7)
    for b, nm in melody:
        g = 0.80 + rng.uniform(-0.08, 0.08)        # 사람 손맛 — 미세 강약
        ring = min(1.9, total - b * beat - 0.02)
        mix_at(out, ks_pluck(note(nm), ring, decay=0.9965, bright=0.55,
                             seed=100 + b), b * beat, g)
    # 시김새 — 짧은 앞꾸밈음 2곳
    for b, nm in [(2, "A3"), (18, "C4")]:
        mix_at(out, ks_pluck(note(nm), 0.25, decay=0.994, bright=0.5,
                             seed=300 + b), b * beat - 0.07, 0.30)
    # 저음 — 마디 첫 박 G3 낮은 플럭 (둔하게)
    for bar in range(8):
        low = lowpass(ks_pluck(note("G3"), 2.2, decay=0.997, bright=0.35,
                               seed=500 + bar), 600)
        mix_at(out, low, bar * 4 * beat, 0.38)
    return fade_io(trim(out, total), 0.005)


def bgm_forest():
    """숲 — 계면조 [A3 C4 D4 E4 G4] 낮은 드론 + 드문 플럭, 긴장. 24s."""
    total = 24.0
    n = int(SR * total)
    # 드론: A2 디튠 페어 + A3 — 느린 LFO (8s 주기 → 24s 에 3회, 루프 정합)
    d1 = sine(110.0, total)
    d2 = sine(110.7, total)
    d3 = sine(220.3, total)
    out = []
    for i in range(n):
        t = i / SR
        lfo = 1.0 + 0.25 * math.sin(2 * math.pi * t / 8.0)
        out.append((0.20 * d1[i] + 0.20 * d2[i] + 0.07 * d3[i]) * lfo)
    # 드문 플럭 — 불규칙 간격, 계면조 음만
    events = [(1.2, "A3"), (3.8, "C4"), (6.4, "E4"), (8.6, "D4"),
              (11.5, "A3"), (13.9, "G4"), (16.4, "E4"), (18.8, "C4"),
              (21.0, "D4")]
    rng = random.Random(13)
    for t, nm in events:
        ring = min(2.4, total - t - 0.02)
        g = 0.62 + rng.uniform(-0.10, 0.10)
        mix_at(out, ks_pluck(note(nm), ring, decay=0.997, bright=0.45,
                             seed=int(t * 10)), t, g)
    # 긴장 — 아주 옅은 고역 노이즈 숨결
    breath = gain(lowpass(noise(total, seed=99), 900), 0.05)
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
    """보스 — 장구 '덩-기덕-쿵-덕' + 노이즈 햇 + 반음 진행 드론.
    120bpm(박 0.5s) × 32박 = 16.0s, 8마디."""
    beat = 0.5
    total = 32 * beat
    out = silence(total)
    # 드론 — A2 ↔ Bb2 2마디 단위 반음 진행 (위상 연속이라 클릭 없음)
    n = int(SR * total)
    freqs = []
    for i in range(n):
        bar = int((i / SR) / (4 * beat))
        freqs.append(110.0 if (bar // 2) % 2 == 0 else note("Bb2"))
    drone = mix(gain(sine_freqs(freqs), 0.5),
                gain(sine_freqs(freqs, mul=2.0), 0.13),
                gain(sine_freqs(freqs, mul=0.5), 0.22))
    # 드론에 느린 맥동 (마디 주기)
    drone = [s * (0.85 + 0.15 * math.sin(2 * math.pi * (i / SR) / (4 * beat)))
             for i, s in enumerate(drone)]
    mix_at(out, drone, 0.0, 0.40)
    # 장구 패턴 (8분음 위치): e0 덩 / e2 기 e3 덕 / e4 쿵 / e6 덕
    for bar in range(8):
        t0 = bar * 4 * beat
        e = beat / 2.0
        mix_at(out, _drum_kung(1.0), t0 + 0 * e)            # 덩 = 궁+채 동시
        mix_at(out, _drum_deok(0.85), t0 + 0 * e)
        mix_at(out, _drum_deok(0.50), t0 + 2 * e)           # 기
        mix_at(out, _drum_deok(0.80), t0 + 3 * e)           # 덕
        mix_at(out, _drum_kung(0.95), t0 + 4 * e)           # 쿵
        mix_at(out, _drum_deok(0.85), t0 + 6 * e)           # 덕
        for k in range(8):                                   # 햇 8분음
            mix_at(out, _drum_hat(0.10 if k % 2 == 0 else 0.06,
                                  seed=bar * 8 + k), t0 + k * e)
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
        out.append((0.22 * d1[i] + 0.10 * d2[i] + 0.07 * d3[i]) * lfo)
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
    mix_at(out, wind, 0.0, 0.55)
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
        mix_at(out, chirp(4300 + rng.uniform(-80, 80), 0), t, 0.10)
        t += 1.7 + rng.uniform(-0.15, 0.15)
    t = 1.7
    while t < 18.2:
        mix_at(out, chirp(4900 + rng.uniform(-80, 80), 1), t, 0.07)
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
    print("mani  :", m