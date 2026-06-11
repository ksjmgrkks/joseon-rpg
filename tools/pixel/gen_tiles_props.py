# -*- coding: utf-8 -*-
"""tiles_props — 「호환기담」 마을/들판 타일(32x32, 4종) + 소품(8종).

STYLE_BIBLE v1 팔레트 25색 강제. 광원 좌상단. 검정 단색 외곽선 금지.
타일은 상하좌우 이어붙여도 자연스럽게 (점 패턴은 modulo wrap).
출력: assets/tilesets/<이름>.png (+ .preview.png 자동)
"""
import sys, os, json, random
sys.path.insert(0, os.path.dirname(__file__))
import palette as P
from core import Canvas, contact_sheet
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "tilesets")
SHEET_DIR = os.path.join(ROOT, "shots", "sheets")


def ell(c, cx, cy, rx, ry, col):
    """채운 타원 — 소나무 잎뭉치/오리 몸통용."""
    rx = max(rx, 1); ry = max(ry, 1)
    for yy in range(cy - ry, cy + ry + 1):
        for xx in range(cx - rx, cx + rx + 1):
            if ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 <= 1.0 + 0.5 / max(rx, ry):
                c.px(xx, yy, col)


# ════════════════════════════════ 타일 32x32 ════════════════════════════════

def dirt_fill(c, y0=0):
    """PAPER_DEEP 바탕 + WOOD 점 (modulo wrap — 사방 타일링)."""
    c.rect(0, y0, 32, 32 - y0, P.PAPER_DEEP)
    rng = random.Random(7)
    for _ in range(24):                      # 어두운 흙 알갱이/잔돌
        x, y = rng.randrange(32), rng.randrange(32)
        col = P.WOOD_DEEP if rng.random() < 0.45 else P.WOOD_BASE
        if y >= y0:
            c.px(x, y, col)
        if rng.random() < 0.5 and (y >= y0):
            c.px((x + 1) % 32, y, col)       # 2px 가로 점 — wrap
    for _ in range(12):                      # 밝은 모래 알갱이
        x, y = rng.randrange(32), rng.randrange(32)
        if y >= y0:
            c.px(x, y, P.PAPER_SHADE)


def gen_ground_dirt():
    c = Canvas(32, 32)
    dirt_fill(c)
    return c


def gen_ground_grass():
    c = Canvas(32, 32)
    dirt_fill(c)                             # 같은 흙 패턴 (dirt 타일과 옆으로 이어짐)
    # 위 6px 풀 (y 0..5)
    c.rect(0, 0, 32, 5, P.GRASS_BASE)
    c.hline(0, 5, 32, P.GRASS_DEEP)          # 풀-흙 경계
    rng = random.Random(11)
    for x in range(32):                      # 윗단 — 들쭉날쭉한 풀끝
        if rng.random() < 0.4:
            c.px(x, 0, P.GRASS_DEEP)
    for _ in range(14):                      # 풀잎 결 (세로 1~2px)
        x, y = rng.randrange(32), 1 + rng.randrange(4)
        c.px(x, y, P.GRASS_DEEP)
        if rng.random() < 0.5:
            c.px(x, min(y + 1, 4), P.GRASS_DEEP)
    for x in range(32):                      # 경계 디더 — 흙으로 흘러내림
        if (x * 7) % 3 == 0:
            c.px(x, 6, P.GRASS_DEEP)
    return c


def gen_stone():
    """돌담 블록 — INK_FAINT/SOFT 벽돌, 8px 단 + 16px 폭 엇갈림 (사방 wrap)."""
    c = Canvas(32, 32)
    c.rect(0, 0, 32, 32, P.INK_FAINT)
    for row in range(4):                     # 가로 줄눈 (단 높이 8 → 세로 wrap)
        y = row * 8
        c.hline(0, y + 7, 32, P.INK_MID)
        off = 0 if row % 2 == 0 else 8       # 엇갈림 — 가로 wrap (16 주기)
        for jx in (off % 32, (off + 16) % 32):
            c.vline(jx, y, 7, P.INK_MID)
        # 벽돌 안쪽 우/하 음영 (광원 좌상단)
        for jx in (off % 32, (off + 16) % 32):
            bx = (jx + 1) % 32
            for k in range(15):
                xx = (bx + k) % 32
                if k == 14:
                    c.vline(xx, y, 7, P.INK_SOFT)        # 오른쪽 음영
                c.px(xx, y + 6, P.INK_SOFT)              # 아래 음영
        # 좌상단 하이라이트 점
        c.px((off + 2) % 32, y + 1, P.PAPER_DEEP)
        c.px((off + 19) % 32, y + 2, P.PAPER_DEEP)
    rng = random.Random(23)
    for _ in range(10):                      # 돌 질감 점
        c.px(rng.randrange(32), rng.randrange(32), P.INK_SOFT)
    return c


def gen_wood_platform():
    """마루널 — WOOD_BASE 널 + WOOD_DEEP 틈. 단 높이 8 (사방 wrap)."""
    c = Canvas(32, 32)
    c.rect(0, 0, 32, 32, P.WOOD_BASE)
    rng = random.Random(31)
    for row in range(4):
        y = row * 8
        c.hline(0, y + 7, 32, P.WOOD_DEEP)   # 널 사이 틈
        seam = 10 if row % 2 == 0 else 26    # 널 이음매 엇갈림
        c.vline(seam, y, 7, P.WOOD_DEEP)
        # 윗면 빛 — 닳은 마루 하이라이트 점
        for x in range(32):
            if (x + row * 5) % 9 == 0:
                c.px(x, y, P.PAPER_DEEP)
        # 나뭇결 — 짧은 가로 결
        for _ in range(4):
            gx, gy = rng.randrange(32), y + 2 + rng.randrange(4)
            c.px(gx, gy, P.WOOD_DEEP)
            c.px((gx + 1) % 32, gy, P.WOOD_DEEP)
        # 못 자국
        c.px((seam + 3) % 32, y + 3, P.WOOD_DEEP)
    return c


# ════════════════════════════════ 소품 ════════════════════════════════

def gen_house_tile():
    """기와집 정면 96x80 — INK_DARK 곡선 기와지붕 + PAPER 벽 + WOOD 기둥/문."""
    c = Canvas(96, 80)

    # ── 기단 (돌, y 72..79) ──
    c.rect(6, 72, 84, 8, P.INK_FAINT)
    c.rect(6, 78, 84, 2, P.INK_SOFT)
    for jx in range(16, 90, 14):
        c.vline(jx, 73, 5, P.INK_SOFT)
    c.hline(6, 72, 84, P.PAPER_DEEP)         # 윗모서리 빛

    # ── 벽 (한지+회벽, y 28..71, x 10..85) ──
    c.rect(10, 28, 76, 44, P.PAPER_BASE)
    c.rect(78, 30, 8, 42, P.PAPER_SHADE)     # 우측 음영

    # ── 기둥 (WOOD, 주춧돌 위) ──
    for px0 in (12, 34, 59, 81):
        c.rect(px0, 30, 3, 42, P.WOOD_BASE)
        c.vline(px0 + 2, 30, 42, P.WOOD_DEEP)

    # ── 창 2개 (창호 — PAPER_BRIGHT + WOOD 문살) ──
    for wx in (17, 64):
        c.rect(wx, 38, 14, 18, P.WOOD_DEEP)              # 틀
        c.rect(wx + 1, 39, 12, 16, P.PAPER_BRIGHT)
        for lx in range(wx + 4, wx + 13, 3):
            c.vline(lx, 39, 16, P.WOOD_DEEP)
        c.hline(wx + 1, 46, 12, P.WOOD_DEEP)
        c.hline(wx + 1, 56, 14, P.WOOD_BASE)             # 창턱

    # ── 문 (가운데 두짝 띠살문) ──
    c.rect(39, 43, 18, 29, P.WOOD_DEEP)                  # 문틀
    for dx in (41, 49):
        c.rect(dx, 45, 6, 25, P.PAPER_BRIGHT)
        for ly in (47, 50, 53, 65, 68):                  # 띠살 (위/아래 묶음)
            c.hline(dx, ly, 6, P.WOOD_DEEP)
    c.px(46, 58, P.GOLD_BASE); c.px(50, 58, P.GOLD_BASE)  # 문고리

    # ── 지붕 (y 2..29) — 처마 곡선이 핵심 ──
    for x in range(96):
        t = (x - 47.5) / 47.5
        eave = 28 - int(round(6 * t ** 4))               # 가운데 28 → 끝 22 (처마 들림)
        if x < 16:
            top = 4 + int(round((16 - x) * 12 / 16.0))   # 좌측 합각 사선
        elif x > 79:
            top = 4 + int(round((x - 79) * 12 / 16.0))
        else:
            top = 4
        # 처마 밑 그늘 (벽 윗부분)
        if 10 <= x <= 85:
            for y in range(eave, 30):
                c.px(x, y, P.PAPER_SHADE)
        # 기와면
        for y in range(top, eave):
            c.px(x, y, P.INK_DARK)
        # 수키와 세로골
        if x % 4 == 1:
            for y in range(top + 1, eave - 1):
                c.px(x, y, P.INK_DEEPEST)
        # 좌측(광원) 면 — 옅은 빛 디더
        if x < 44 and x % 4 == 3:
            for y in range(top + 1, eave - 1, 3):
                c.px(x, y, P.INK_MID)
        # 처마 끝선 + 막새(둥근 와당) 점
        c.px(x, eave - 1, P.INK_DEEPEST)
        if x % 4 == 3:
            c.px(x, eave - 1, P.INK_MID)
    # 용마루 (윗단 굵은 먹선)
    c.rect(14, 2, 68, 3, P.INK_DEEPEST)
    c.hline(14, 2, 68, P.INK_MID)                        # 마루 윗빛
    c.px(13, 3, P.INK_DEEPEST); c.px(82, 3, P.INK_DEEPEST)  # 망와
    c.px(13, 4, P.INK_DEEPEST); c.px(82, 4, P.INK_DEEPEST)
    return c


def gen_house_thatch():
    """초가집 96x72 — GOLD_DEEP 둥근 초가지붕 + 흙벽. 지붕이 옆으로 흘러내림."""
    c = Canvas(96, 72)
    rng = random.Random(43)

    # ── 토방/주춧돌 (y 64..71) ──
    c.rect(10, 64, 76, 8, P.INK_FAINT)
    c.rect(10, 70, 76, 2, P.INK_SOFT)
    for jx in range(20, 86, 12):
        c.vline(jx, 65, 4, P.INK_SOFT)

    # ── 흙벽 (y 30..63, x 12..83) ──
    c.rect(12, 30, 72, 34, P.PAPER_DEEP)
    for _ in range(30):                                  # 황토 질감
        x, y = 14 + rng.randrange(68), 32 + rng.randrange(30)
        c.px(x, y, P.WOOD_BASE if rng.random() < 0.5 else P.PAPER_SHADE)
    c.dither(76, 32, 8, 32, P.INK_SOFT)                  # 우측 음영 디더
    for px0 in (12, 82):                                 # 모서리 기둥
        c.rect(px0, 30, 2, 34, P.WOOD_DEEP)
    c.dither(14, 30, 68, 1, P.INK_SOFT)                  # 처마 밑 그늘

    # ── 봉창 (왼쪽 작은 창) ──
    c.rect(20, 38, 12, 12, P.WOOD_DEEP)
    c.rect(21, 39, 10, 10, P.PAPER_BRIGHT)
    c.vline(24, 39, 10, P.WOOD_DEEP); c.vline(27, 39, 10, P.WOOD_DEEP)
    c.hline(21, 43, 10, P.WOOD_DEEP)

    # ── 널문 (가운데) ──
    c.rect(40, 38, 17, 26, P.WOOD_DEEP)
    c.rect(41, 39, 15, 25, P.WOOD_BASE)
    for sx in (44, 48, 52):
        c.vline(sx, 39, 25, P.WOOD_DEEP)
    c.px(54, 50, P.INK_MID)                              # 문고리

    # ── 초가지붕 (y 3..29) — 둥근 마루, 끝이 흘러내림 ──
    for x in range(96):
        t = (x - 47.5) / 47.5
        top = 4 + int(round(11 * t * t))                 # 가운데 4 → 끝 15
        eave = 28 + (1 if (x * 5) % 7 < 3 else 0)        # 들쭉한 처마끝
        for y in range(top, eave + 1):
            c.px(x, y, P.GOLD_DEEP)
        # 용마름 (이엉 마루) — 짙은 띠가 곡선을 따라감
        c.px(x, top, P.WOOD_DEEP)
        if abs(t) < 0.55:
            c.px(x, top + 1, P.WOOD_DEEP)
        # 볕 받는 윗면 GOLD_BASE 띠
        for y in range(top + 2, min(top + 5, eave)):
            if x < 70:
                c.px(x, y, P.GOLD_BASE)
        # 처마끝 — 짚단 그늘
        c.px(x, eave, P.WOOD_DEEP if (x % 3) else P.GOLD_DEEP)
    for _ in range(50):                                  # 이엉 짚결 (세로 짧은 획)
        x = rng.randrange(96)
        t = (x - 47.5) / 47.5
        top = 4 + int(round(11 * t * t))
        y = top + 5 + rng.randrange(max(22 - top, 1))
        if y < 28:
            c.px(x, y, P.GOLD_BASE if rng.random() < 0.55 else P.WOOD_DEEP)
            c.px(x, y + 1, P.GOLD_BASE if rng.random() < 0.4 else P.GOLD_DEEP)
    return c


def gen_well():
    """우물 40x40 — 돌 몸체 + 나무 지지대 + 두레박."""
    c = Canvas(40, 40)
    # 지지대 (기둥 2 + 가로보)
    c.rect(5, 4, 3, 21, P.WOOD_DEEP); c.vline(5, 4, 21, P.WOOD_BASE)
    c.rect(32, 4, 3, 21, P.WOOD_DEEP); c.vline(32, 4, 21, P.WOOD_BASE)
    c.rect(3, 2, 34, 3, P.WOOD_BASE); c.hline(3, 4, 34, P.WOOD_DEEP)
    # 두레박줄 + 두레박
    c.vline(19, 5, 9, P.INK_SOFT)
    c.rect(16, 14, 7, 5, P.WOOD_BASE)
    c.hline(16, 16, 7, P.WOOD_DEEP)                      # 테
    c.vline(16, 14, 5, P.WOOD_DEEP); c.vline(22, 14, 5, P.WOOD_DEEP)
    # 돌 우물 — 윗면 테 + 검은 구멍
    c.rect(3, 22, 34, 3, P.INK_SOFT)
    c.rect(9, 22, 22, 2, P.INK_DEEPEST)
    c.hline(3, 22, 6, P.INK_FAINT); c.hline(31, 22, 6, P.INK_FAINT)  # 테 빛
    # 돌 몸체
    c.rect(3, 25, 34, 13, P.INK_FAINT)
    c.hline(3, 29, 34, P.INK_SOFT); c.hline(3, 33, 34, P.INK_SOFT)   # 단
    for jx, jy in ((10, 25), (24, 25), (17, 29), (31, 29), (8, 33), (22, 33)):
        c.vline(jx, jy + 1, 3, P.INK_SOFT)               # 엇갈린 돌눈
    c.rect(34, 25, 3, 13, P.INK_SOFT)                    # 우측 음영
    c.hline(3, 37, 34, P.INK_SOFT)
    c.px(5, 26, P.PAPER_DEEP); c.px(13, 30, P.PAPER_DEEP)  # 돌 하이라이트
    return c


def gen_fence():
    """담장 64x24 — 돌+흙 (토석담), 기와 덮개. 좌우 wrap."""
    c = Canvas(64, 24)
    # 기와 덮개
    c.hline(0, 0, 64, P.INK_MID)
    c.hline(0, 1, 64, P.INK_DARK)
    c.hline(0, 2, 64, P.INK_DARK)
    for x in range(0, 64, 4):
        c.px(x, 1, P.INK_DEEPEST); c.px(x, 2, P.INK_DEEPEST)  # 기와골
    c.hline(0, 3, 64, P.INK_DEEPEST)
    # 흙 몸체
    c.rect(0, 4, 64, 20, P.PAPER_DEEP)
    rng = random.Random(53)
    for _ in range(22):
        c.px(rng.randrange(64), 4 + rng.randrange(19), P.WOOD_BASE)

    def stone(cx, cy):
        for yy in range(cy, cy + 5):
            for xx in range(cx, cx + 7):
                if (xx in (cx, cx + 6)) and (yy in (cy, cy + 4)):
                    continue                              # 모서리 라운드
                c.px(xx % 64, yy, P.INK_FAINT)
        for xx in range(cx + 1, cx + 7):                  # 우/하 음영
            c.px(xx % 64, cy + 4, P.INK_SOFT)
        for yy in range(cy + 1, cy + 4):
            c.px((cx + 6) % 64, yy, P.INK_SOFT)
        c.px((cx + 1) % 64, cy + 1, P.PAPER_SHADE)        # 좌상단 빛

    for sx in (3, 19, 35, 51):                            # 윗단 (주기 16 — wrap)
        stone(sx, 6)
    for sx in (11, 27, 43, 59):                           # 아랫단 엇갈림
        stone(sx, 13)
    for px0, py0 in ((8, 20), (30, 21), (48, 20)):        # 잔돌
        c.px(px0, py0, P.INK_SOFT); c.px(px0 + 1, py0, P.INK_SOFT)
    c.hline(0, 23, 64, P.INK_SOFT)                        # 바닥선
    return c


def gen_jangseung():
    """장승 24x56 — WOOD 몸통 + 부릅뜬 눈/이빨, 마을 수호."""
    c = Canvas(24, 56)
    # 몸통
    c.rect(6, 7, 12, 49, P.WOOD_BASE)
    c.rect(15, 7, 3, 49, P.WOOD_DEEP)                    # 우측 음영
    # 관모 (먹빛 벙거지)
    c.rect(5, 2, 14, 3, P.INK_DARK)
    c.hline(5, 2, 14, P.INK_MID)
    c.rect(3, 5, 18, 2, P.INK_DARK)
    c.hline(3, 6, 18, P.INK_DEEPEST)
    # 부릅뜬 눈 + 치켜올린 눈썹
    c.line(6, 11, 10, 13, P.INK_DARK)
    c.line(17, 11, 13, 13, P.INK_DARK)
    c.rect(7, 14, 4, 4, P.PAPER_BRIGHT)
    c.rect(13, 14, 4, 4, P.PAPER_BRIGHT)
    c.rect(9, 15, 1, 2, P.INK_DEEPEST)
    c.rect(14, 15, 1, 2, P.INK_DEEPEST)
    # 주먹코
    c.rect(10, 18, 4, 5, P.WOOD_DEEP)
    c.px(10, 22, P.INK_MID); c.px(13, 22, P.INK_MID)
    # 벌린 입 + 이빨
    c.rect(7, 25, 11, 5, P.INK_DEEPEST)
    for tx in (8, 10, 12, 14, 16):
        c.rect(tx, 26, 1, 3, P.PAPER_BRIGHT)
    c.hline(6, 31, 12, P.WOOD_DEEP)                      # 턱선
    # 몸통 명문 (天下大將軍 느낌의 먹 획)
    c.hline(9, 35, 6, P.INK_DARK); c.vline(11, 36, 2, P.INK_DARK)
    c.hline(9, 40, 6, P.INK_DARK); c.vline(9, 41, 3, P.INK_DARK)
    c.vline(14, 41, 3, P.INK_DARK); c.hline(9, 43, 6, P.INK_DARK)
    c.vline(11, 46, 4, P.INK_DARK); c.hline(9, 47, 6, P.INK_DARK)
    c.hline(10, 52, 4, P.INK_DARK)
    # 나뭇결
    for gy in (33, 34, 44, 45, 50):
        c.px(7, gy, P.WOOD_DEEP)
    # 땅에 박힌 밑동
    c.rect(6, 54, 12, 2, P.WOOD_DEEP)
    c.outline(P.WOOD_DEEP, only_color=P.WOOD_BASE)
    return c


def gen_sotdae():
    """솟대 16x64 — 긴 장대 + 꼭대기 오리 실루엣."""
    c = Canvas(16, 64)
    # 장대
    c.rect(7, 11, 2, 53, P.WOOD_DEEP)
    c.vline(7, 11, 53, P.WOOD_BASE)
    c.rect(6, 40, 4, 2, P.GOLD_DEEP)                     # 새끼줄 띠
    # 오리 (먹 실루엣)
    ell(c, 7, 7, 5, 3, P.INK_DARK)                       # 몸통
    c.px(1, 4, P.INK_DARK); c.px(2, 4, P.INK_DARK); c.px(2, 5, P.INK_DARK)  # 꼬리
    c.rect(10, 3, 2, 3, P.INK_DARK)                      # 목
    c.rect(10, 1, 4, 3, P.INK_DARK)                      # 머리
    c.px(14, 2, P.GOLD_DEEP); c.px(15, 2, P.GOLD_DEEP)   # 부리
    c.px(12, 2, P.PAPER_BRIGHT)                          # 눈
    c.px(5, 4, P.INK_MID); c.px(6, 4, P.INK_MID)         # 등 빛
    c.px(5, 7, P.INK_DEEPEST); c.px(6, 8, P.INK_DEEPEST); c.px(7, 8, P.INK_DEEPEST)  # 날개선
    return c


def gen_pine():
    """소나무 56x88 — 굽은 줄기 + GREEN 잎뭉치 3덩이, 수묵 느낌."""
    c = Canvas(56, 88)
    rng = random.Random(67)
    # 굽은 줄기 (위로 갈수록 가늘게)
    pts = [(87, 24), (68, 21), (50, 27), (34, 35), (20, 33)]
    for i in range(len(pts) - 1):
        y0, x0 = pts[i]; y1, x1 = pts[i + 1]
        for y in range(y0, y1 - 1, -1):
            f = (y - y1) / (y0 - y1)
            x = int(round(x1 + (x0 - x1) * f))
            th = 2 + int(round(3 * (y - 20) / 67.0))
            c.hline(x - th // 2, y, th, P.WOOD_DEEP)
            if y % 2 == 0:
                c.px(x - th // 2, y, P.WOOD_BASE)        # 좌측 빛
            if y % 3 == 0:
                c.px(x + th - th // 2 - 1, y, P.INK_MID)  # 먹 느낌 윤곽
    # 가지
    for (bx0, by0, bx1, by1) in ((33, 26, 45, 22), (26, 46, 12, 36)):
        c.line(bx0, by0, bx1, by1, P.WOOD_DEEP)
        c.line(bx0, by0 + 1, bx1, by1 + 1, P.WOOD_DEEP)
    # 잎뭉치 3덩이 (납작 타원 — 우산형 수관)
    clumps = ((31, 12, 15, 7), (11, 32, 10, 6), (45, 24, 10, 6))
    for (cx, cy, rx, ry) in clumps:
        ell(c, cx, cy + 1, rx, ry, P.GREEN_DEEP)         # 밑면 그늘
        ell(c, cx - 1, cy - 1, rx - 1, ry - 1, P.GREEN_BASE)
        for _ in range(16):                              # 가장자리 삐죽한 솔잎
            a = rng.random() * 6.28318
            ex = cx + int(round((rx + 1) * __import__("math").cos(a)))
            ey = cy + int(round((ry + 1) * __import__("math").sin(a)))
            c.px(ex, ey, P.GREEN_DEEP)
        c.dither(cx - rx + 2, cy, rx, ry, P.GREEN_DEEP)  # 하반부 결
    c.outline(P.GREEN_DEEP, only_color=P.GREEN_BASE)
    return c


def gen_lantern():
    """등롱 16x24 — PAPER_BRIGHT 몸 + GOLD 불빛."""
    c = Canvas(16, 24)
    c.px(7, 0, P.INK_MID); c.px(8, 0, P.INK_MID)         # 고리
    c.rect(4, 1, 8, 1, P.WOOD_BASE)                      # 윗갓
    c.rect(4, 2, 8, 1, P.WOOD_DEEP)
    # 한지 몸체 (모서리 라운드)
    c.rect(3, 3, 10, 16, P.PAPER_BRIGHT)
    for (ex, ey) in ((3, 3), (12, 3), (3, 18), (12, 18)):
        c.px(ex, ey, P.TRANSPARENT)
    c.vline(12, 5, 12, P.PAPER_SHADE)                    # 우측 음영
    # 불빛 (GOLD) + 심지 불꽃
    c.disc(8, 10, 4, P.GOLD_BASE)
    c.px(8, 9, P.GOLD_DEEP)
    c.px(8, 10, P.RED_BASE); c.px(8, 11, P.RED_BASE)
    # 살(리브)
    c.vline(3, 4, 14, P.INK_SOFT); c.vline(13, 4, 14, P.INK_SOFT)
    c.hline(4, 3, 9, P.INK_SOFT); c.hline(4, 18, 9, P.INK_SOFT)
    # 아랫갓 + 술
    c.rect(4, 19, 8, 2, P.WOOD_DEEP)
    c.hline(4, 19, 8, P.WOOD_BASE)
    c.rect(7, 21, 2, 2, P.RED_BASE)
    c.px(7, 23, P.RED_DEEP); c.px(8, 23, P.RED_DEEP)
    return c


# ════════════════════════════════ 실행 ════════════════════════════════

ASSETS = [
    # (이름, 생성함수, 타일 여부)
    ("ground_dirt", gen_ground_dirt, True),
    ("ground_grass", gen_ground_grass, True),
    ("stone", gen_stone, True),
    ("wood_platform", gen_wood_platform, True),
    ("house_tile", gen_house_tile, False),
    ("house_thatch", gen_house_thatch, False),
    ("well", gen_well, False),
    ("fence", gen_fence, False),
    ("jangseung", gen_jangseung, False),
    ("sotdae", gen_sotdae, False),
    ("pine", gen_pine, False),
    ("lantern", gen_lantern, False),
]


def main():
    paths = []
    manifest = {"tiles": {}, "props": {}}
    for name, fn, is_tile in ASSETS:
        cnv = fn()
        path = os.path.join(OUT, name + ".png")
        cnv.save(path)                                   # 팔레트 위반 시 예외
        paths.append(path)
        entry = {"file": name + ".png", "frame_w": cnv.w, "frame_h": cnv.h, "frames": 1}
        if is_tile:
            entry["tileable"] = "xy"
            manifest["tiles"][name] = entry
        else:
            manifest["props"][name] = entry
        # 검증: frames x frame_w == PNG 폭
        with Image.open(path) as im:
            assert im.width == entry["frames"] * entry["frame_w"], name
            assert im.height == entry["frame_h"], name
        print("saved:", path, "%dx%d" % (cnv.w, cnv.h))

    mpath = os.path.join(OUT, "manifest.json")
    with open(mpath, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    print("manifest:", mpath)

    # 검수 시트
    sheet = contact_sheet(paths, os.path.join(SHEET_DIR, "tiles_props_sheet.png"),
                          scale=6, cols=4)
    print("sheet:", sheet)

    # 타일 이어붙임(3x3) 검사 시트 — 이음새 확인용
    tile_names = [n for n, _, t in ASSETS if t]
    big = Image.new("RGBA", (len(tile_names) * (96 + 8) - 8, 96), (40, 36, 30, 255))
    for i, n in enumerate(tile_names):
        with Image.open(os.path.join(OUT, n + ".png")) as im:
            tile = im.convert("RGBA")
            for ty in range(3):
                for tx in range(3):
                    big.alpha_composite(tile, (i * 104 + tx * 32, ty * 32))
    big = big.resize((big.width * 4, big.height * 4), Image.NEAREST)
    tcheck = os.path.join(SHEET_DIR, "tiles_tiling_check.png")
    big.save(tcheck)
    print("tiling check:", tcheck)


if __name__ == "__main__":
    main()
