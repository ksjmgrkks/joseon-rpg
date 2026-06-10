# -*- coding: utf-8 -*-
"""「호환기담」 오디오 신디사이저 — 순수 파이썬 (wave/math/struct/random 만 사용).

규약 (작업 지시서):
- 22050 Hz / 16bit / mono
- 피크 <= -3 dBFS (write_wav 가 -3.2 dBFS 로 정규화 — 클리핑 절대 금지)
- BGM 은 루프 친화: 시작/끝 5ms 페이드 (fade_io)

구성:
- 오실레이터: sine / sine_sweep(지수·선형) / triangle / noise
- 가야금풍 플럭: Karplus-Strong (ks_pluck)
- 엔벨로프: env_points(브레이크포인트) / decay_exp / adsr
- 필터: 1-pole lowpass (컷오프 고정 또는 샘플별 배열), highpass = 원음 - lowpass
- 믹스: mix_at(시간 오프셋 합산)
"""
import math
import os
import random
import struct
import wave

SR = 22050

# ── 음이름 → 주파수 (A4 = 440) ──────────────────────────────
_SEMI = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def note(name: str) -> float:
    """'G3' / 'Bb2' / 'C#4' → Hz."""
    letter = name[0].upper()
    rest = name[1:]
    acc = 0
    while rest and rest[0] in "#b":
        acc += 1 if rest[0] == "#" else -1
        rest = rest[1:]
    octave = int(rest)
    midi = 12 * (octave + 1) + _SEMI[letter] + acc
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


# ── 오실레이터 ───────────────────────────────────────────────
def silence(dur: float):
    return [0.0] * int(SR * dur)


def sine(freq: float, dur: float, phase: float = 0.0):
    n = int(SR * dur)
    w = 2.0 * math.pi * freq / SR
    return [math.sin(phase + w * i) for i in range(n)]


def sine_sweep(f0: float, f1: float, dur: float, curve: str = "exp"):
    """주파수 스윕 — 위상 적분이라 끊김 없음. curve: 'exp' | 'lin'."""
    n = int(SR * dur)
    out = []
    ph = 0.0
    ratio = f1 / f0
    for i in range(n):
        u = i / max(1, n - 1)
        f = f0 * ratio ** u if curve == "exp" else f0 + (f1 - f0) * u
        ph += 2.0 * math.pi * f / SR
        out.append(math.sin(ph))
    return out


def sine_freqs(freqs, mul: float = 1.0):
    """샘플별 주파수 배열로 위상 연속 사인 — 드론 반음 진행 등."""
    out = []
    ph = 0.0
    for f in freqs:
        ph += 2.0 * math.pi * (f * mul) / SR
        out.append(math.sin(ph))
    return out


def triangle(freq: float, dur: float):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = (i * freq / SR) % 1.0
        out.append(4.0 * abs(t - 0.5) - 1.0)
    return out


def noise(dur: float, seed: int = 0):
    rng = random.Random(seed)
    return [rng.uniform(-1.0, 1.0) for _ in range(int(SR * dur))]


def ks_pluck(freq: float, dur: float, decay: float = 0.996,
             bright: float = 0.6, seed: int = 0):
    """Karplus-Strong 현 플럭 — 가야금풍 (빠른 어택 + 긴 감쇠)."""
    n = int(SR * dur)
    period = max(2, int(SR / freq))
    rng = random.Random(seed)
    buf = [rng.uniform(-1.0, 1.0) for _ in range(period)]
    # 초기 버퍼를 한 번 저역 통과 → 금속성 잡음 완화 (bright 낮을수록 부드러움)
    prev = buf[-1]
    for i in range(period):
        buf[i] = bright * buf[i] + (1.0 - bright) * prev
        prev = buf[i]
    out = []
    i = 0
    for _ in range(n):
        cur = buf[i]
        nxt = buf[(i + 1) % period]
        buf[i] = decay * 0.5 * (cur + nxt)
        out.append(cur)
        i = (i + 1) % period
    return out


# ── 필터 ─────────────────────────────────────────────────────
def lowpass(x, cutoff):
    """1-pole LPF. cutoff: 스칼라(Hz) 또는 샘플별 리스트."""
    out = []
    y = 0.0
    if isinstance(cutoff, (int, float)):
        a = 1.0 - math.exp(-2.0 * math.pi * cutoff / SR)
        for s in x:
            y += a * (s - y)
            out.append(y)
    else:
        for i, s in enumerate(x):
            a = 1.0 - math.exp(-2.0 * math.pi * max(1.0, cutoff[i]) / SR)
            y += a * (s - y)
            out.append(y)
    return out


def highpass(x, cutoff):
    lp = lowpass(x, cutoff)
    return [s - l for s, l in zip(x, lp)]


# ── 엔벨로프 / 게인 ─────────────────────────────────────────
def env_points(x, pts):
    """브레이크포인트 [(t초, 레벨), ...] 선형 보간 엔벨로프."""
    out = []
    n = len(x)
    j = 0
    for i in range(n):
        t = i / SR
        while j + 1 < len(pts) and pts[j + 1][0] <= t:
            j += 1
        if j + 1 >= len(pts):
            v = pts[-1][1]
        else:
            t0, v0 = pts[j]
            t1, v1 = pts[j + 1]
            v = v0 if t <= t0 else v0 + (v1 - v0) * (t - t0) / (t1 - t0)
        out.append(x[i] * v)
    return out


def decay_exp(x, tau: float, attack: float = 0.002):
    """빠른 어택 + 지수 감쇠 — 타악/딩 소리용."""
    out = []
    an = max(1, int(attack * SR))
    for i, s in enumerate(x):
        a = min(1.0, i / an)
        out.append(s * a * math.exp(-(i / SR) / tau))
    return out


def adsr(x, a=0.01, d=0.05, s=0.7, r=0.05):
    n = len(x)
    an, dn, rn = int(a * SR), int(d * SR), int(r * SR)
    sn = max(0, n - an - dn - rn)
    out = []
    for i in range(n):
        if i < an:
            v = i / max(1, an)
        elif i < an + dn:
            v = 1.0 - (1.0 - s) * (i - an) / max(1, dn)
        elif i < an + dn + sn:
            v = s
        else:
            v = s * (1.0 - (i - an - dn - sn) / max(1, rn))
        out.append(x[i] * max(0.0, v))
    return out


def gain(x, g: float):
    return [s * g for s in x]


def fade_io(x, fade_s: float = 0.005):
    """시작/끝 페이드 — 루프 이음새·클릭 방지."""
    fn = max(1, int(fade_s * SR))
    n = len(x)
    out = list(x)
    for i in range(min(fn, n)):
        out[i] *= i / fn
        out[n - 1 - i] *= i / fn
    return out


# ── 믹스 ─────────────────────────────────────────────────────
def mix_at(dst, src, t: float, g: float = 1.0):
    """dst 리스트에 src 를 t초 위치부터 합산 (필요 시 dst 확장)."""
    off = int(t * SR)
    need = off + len(src)
    if need > len(dst):
        dst.extend([0.0] * (need - len(dst)))
    for i, s in enumerate(src):
        dst[off + i] += s * g
    return dst


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, s in enumerate(t):
            out[i] += s
    return out


def trim(x, dur: float):
    return x[: int(dur * SR)]


# ── 저장 + 스펙 ──────────────────────────────────────────────
def write_wav(path: str, samples, peak_db: float = -3.2):
    """피크를 peak_db(dBFS)로 정규화해 16bit mono WAV 저장. 스펙 dict 반환."""
    peak = max(abs(s) for s in samples)
    if peak <= 0.0:
        raise ValueError("무음 신호: %s" % path)
    target = 10.0 ** (peak_db / 20.0)
    g = target / peak
    ints = [int(round(max(-1.0, min(1.0, s * g)) * 32767.0)) for s in samples]
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(struct.pack("<%dh" % len(ints), *ints))
    peak_i = max(abs(v) for v in ints)
    rms_i = math.sqrt(sum(v * v for v in ints) / len(ints))
    spec = {
        "path": path,
        "duration_s": round(len(ints) / SR, 3),
        "peak_dbfs": round(20.0 * math.log10(peak_i / 32768.0), 2),
        "rms_dbfs": round(20.0 * math.log10(max(rms_i, 1e-9) / 32768.0), 2),
        "samples": len(ints),
    }
    if spec["peak_dbfs"] > -3.0:
        raise ValueError("피크 한도 초과(> -3 dBFS): %s %s" % (path, spec["peak_dbfs"]))
    return spec
