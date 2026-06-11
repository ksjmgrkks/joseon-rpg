# -*- coding: utf-8 -*-
"""적 2종 생성 — 도깨비(goblin 32x64) + 구미호(fox 48x48).

goblin: 뿔 1개, WOOD_BASE 피부, 표범가죽 잠방이(GOLD_BASE+INK_DARK 점), 나무 방망이.
        우락부락 둥근 실루엣. 32x64, 발바닥선 y=62, 축 x=16.
        idle(2: 숨쉬기) walk(4: 쿵쿵 걸음) attack(3: 방망이 내려치기) death(4: 뒤로 쓰러짐)

fox   : 구미호 — 4족 여우. GOLD_BASE 몸 + PAPER_BRIGHT 가슴/주둥이, 꼬리 3갈래가
        위로 부채처럼(실루엣 핵심). 48x48, 발바닥선 y=44, 축 x=24.
        idle(4: 꼬리 물결) walk(4: 대각 보행) attack(3: 도약 할퀴기) death(4: 쓰러짐)

규약: AGENT_GUIDE.md §1~2, STYLE_BIBLE §1(25색)·§3(외곽선 짝색)·§4(광원 좌상단).
"""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
import palette as P
from core import Canvas, strip, contact_sheet

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GOBLIN_DIR = os.path.join(ROOT, "assets", "sprites", "enemies", "goblin")
FOX_DIR = os.path.join(ROOT, "assets", "sprites", "enemies", "fox")
FRAMES_DIR = os.path.join(ROOT, "shots", "frames", "goblin_fox")
SHEET_PATH = os.path.join(ROOT, "shots", "sheets", "goblin_fox_sheet.png")


def outline_multi(c, mapping):
    """빈 픽셀의 상하좌우 이웃이 mapping 의 색이면 그 짝색으로 외곽선."""
    src = [[c.get(x, y) for x in range(c.w)] for y in range(c.h)]
    order = list(mapping.keys())
    for y in range(c.h):
        for x in range(c.w):
            if src[y][x][3] != 0:
                continue
            found = None
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < c.w and 0 <= ny < c.h:
                    n = src[ny][nx]
                    if n[3] != 0 and n in mapping:
                        if found is None or order.index(n) < order.index(found):
                            found = n
            if found is not None:
                c.px(x, y, mapping[found])


def _h(x, y, s=0):
    return (x * 13 + y * 29 + s * 53) % 97


# ══════════════════════════════════════════════════════════════
# ① 도깨비 (32x64, 축 x=16, 발바닥 y=62)
# ══════════════════════════════════════════════════════════════
GW, GH, GCX = 32, 64, 16

GOBLIN_OUTLINE = {
    P.WOOD_BASE: P.WOOD_DEEP,
    P.GOLD_BASE: P.GOLD_DEEP,
    P.INK_DARK: P.INK_DEEPEST,
    P.RED_BASE: P.RED_DEEP,
    P.WOOD_DEEP: P.INK_MID,
    P.PAPER_BRIGHT: P.WOOD_DEEP,
}


def goblin_leg(c, x0, dy=0, lift=0, near=False):
    bot = 62 - lift
    c.rect(x0, 50 + dy, 6, bot - (50 + dy) - 1, P.WOOD_BASE)   # 굵은 종아리
    c.rect(x0 - 1, bot - 2, 8, 3, P.WOOD_DEEP)                 # 큰 발
    c.px(x0 + 6, bot - 2, P.INK_DARK)                          # 발톱
    c.px(x0 - 1, bot - 2, P.INK_DARK)
    if near:
        c.vline(x0 + 5, 50 + dy, bot - (50 + dy) - 3, P.WOOD_DEEP)


def draw_goblin(body_dy=0, arm="rest", club_dy=0, legs="stand", dead=0):
    c = Canvas(GW, GH)
    cx = GCX
    bdy = body_dy

    # ── 다리 ──
    if dead >= 2:
        pass  # 쓰러진 프레임은 별도 처리
    else:
        if legs == "stand":
            goblin_leg(c, 8, dy=bdy)
            goblin_leg(c, 18, dy=bdy, near=True)
        elif legs == "stepL":
            goblin_leg(c, 6, dy=bdy, lift=1)
            goblin_leg(c, 19, dy=bdy, near=True)
        elif legs == "stepR":
            goblin_leg(c, 9, dy=bdy, near=True)
            goblin_leg(c, 20, dy=bdy, lift=1)

    # ── 표범가죽 잠방이 (허리 ~ 허벅지) ──
    c.rect(cx - 9, 44 + bdy, 19, 8, P.GOLD_BASE)
    c.px(cx - 9, 44 + bdy, P.TRANSPARENT)
    c.px(cx + 9, 44 + bdy, P.TRANSPARENT)
    # 들쭉날쭉 가죽 밑단
    for x in range(cx - 9, cx + 10, 2):
        c.px(x, 52 + bdy, P.GOLD_BASE)
    # 표범 점
    for sx, sy in ((cx - 6, 46), (cx - 1, 48), (cx + 4, 46), (cx + 6, 49), (cx - 4, 50), (cx + 1, 45)):
        c.px(sx, sy + bdy, P.INK_DARK)
        c.px(sx + 1, sy + bdy, P.INK_DARK)
    c.hline(cx - 9, 44 + bdy, 19, P.GOLD_DEEP)  # 허리끈 그늘

    # ── 우락부락 몸통 (배불뚝 둥근) ──
    for y in range(26, 45):
        if y < 30:
            hw = 7 + (y - 26)
        elif y < 40:
            hw = 11
        else:
            hw = 11 - (y - 39)
        for x in range(cx - hw, cx + hw + 1):
            col = P.WOOD_BASE
            if x >= cx + hw - 2:
                col = P.WOOD_DEEP
            c.px(x, y + bdy, col)
    # 가슴/배 근육 음영
    c.hline(cx - 6, 36 + bdy, 12, P.WOOD_DEEP)
    c.px(cx - 3, 33 + bdy, P.WOOD_DEEP)
    c.px(cx + 3, 33 + bdy, P.WOOD_DEEP)
    c.vline(cx, 31 + bdy, 12, P.WOOD_DEEP)  # 복근 중앙선

    # ── 팔 ──
    if arm == "rest":
        # 왼팔(원경) 늘어뜨림
        c.rect(cx - 12, 30 + bdy, 4, 12, P.WOOD_DEEP)
        c.rect(cx - 12, 41 + bdy, 4, 3, P.WOOD_DEEP)  # 주먹
        # 오른팔(근경) — 방망이 쥠
        c.rect(cx + 8, 30 + bdy, 5, 11, P.WOOD_BASE)
        c.rect(cx + 9, 40 + bdy, 5, 4, P.WOOD_BASE)   # 주먹
        _club(c, cx + 16, 44 + bdy + club_dy, angle="down")
    elif arm == "raise":  # 방망이 머리 위로
        c.rect(cx - 12, 30 + bdy, 4, 12, P.WOOD_DEEP)
        c.rect(cx - 12, 41 + bdy, 4, 3, P.WOOD_DEEP)
        c.rect(cx + 7, 22 + bdy, 5, 12, P.WOOD_BASE)  # 치켜든 팔
        c.rect(cx + 8, 20 + bdy, 5, 4, P.WOOD_BASE)
        _club(c, cx + 9, 6 + bdy, angle="up")
    elif arm == "smash":  # 내려친 직후
        c.rect(cx - 12, 30 + bdy, 4, 12, P.WOOD_DEEP)
        c.rect(cx + 8, 32 + bdy, 5, 10, P.WOOD_BASE)
        c.rect(cx + 9, 41 + bdy, 5, 4, P.WOOD_BASE)
        _club(c, cx + 14, 48 + bdy, angle="down")

    # ── 머리 (큰 얼굴 + 송곳니 + 뿔 1개) ──
    hy = 14 + bdy
    c.rect(cx - 6, hy, 12, 12, P.WOOD_BASE)
    c.px(cx - 6, hy, P.TRANSPARENT)
    c.px(cx + 5, hy, P.TRANSPARENT)
    c.vline(cx + 5, hy + 1, 10, P.WOOD_DEEP)  # 우측 음영
    # 부리부리 눈 (붉은기)
    c.rect(cx - 4, hy + 4, 3, 2, P.PAPER_BRIGHT)
    c.rect(cx + 1, hy + 4, 3, 2, P.PAPER_BRIGHT)
    c.px(cx - 3, hy + 4, P.RED_BASE)
    c.px(cx + 2, hy + 4, P.RED_BASE)
    c.px(cx - 3, hy + 5, P.INK_DEEPEST)
    c.px(cx + 2, hy + 5, P.INK_DEEPEST)
    # 굵은 눈썹
    c.hline(cx - 5, hy + 3, 4, P.INK_DARK)
    c.hline(cx + 1, hy + 3, 4, P.INK_DARK)
    # 주먹코 + 송곳니 입
    c.px(cx - 1, hy + 7, P.WOOD_DEEP)
    c.px(cx, hy + 7, P.WOOD_DEEP)
    c.hline(cx - 4, hy + 9, 9, P.INK_DEEPEST)   # 입
    c.px(cx - 3, hy + 10, P.PAPER_BRIGHT)       # 송곳니
    c.px(cx + 3, hy + 10, P.PAPER_BRIGHT)
    # 뿔 1개 (이마 중앙, 위로)
    c.rect(cx - 1, hy - 4, 3, 5, P.PAPER_BRIGHT)
    c.px(cx - 1, hy - 4, P.TRANSPARENT)
    c.px(cx, hy - 5, P.PAPER_BRIGHT)
    c.px(cx, hy - 6, P.WOOD_DEEP)
    # 더벅머리 (먹색 몇 가닥)
    for hx in range(cx - 5, cx + 6, 2):
        c.px(hx, hy - 1, P.INK_DARK)

    if dead == 0 or dead == 1:
        outline_multi(c, GOBLIN_OUTLINE)
        return c
    return c  # dead>=2 는 _goblin_down 에서 만든다


def _club(c, x, y, angle="down"):
    """나무 방망이 — 옹이 박힌 몽둥이."""
    if angle == "down":
        for i in range(10):
            w = 3 + i // 4
            c.rect(x - w // 2, y + i, w, 1, P.WOOD_DEEP if i < 2 else P.WOOD_BASE)
        c.px(x, y + 5, P.INK_DARK)   # 옹이
        c.px(x + 1, y + 8, P.INK_DARK)
    else:  # up — 머리 위 수직
        for i in range(12):
            w = 3 + (11 - i) // 4
            c.rect(x - w // 2, y + i, w, 1, P.WOOD_DEEP if i > 9 else P.WOOD_BASE)
        c.px(x, y + 3, P.INK_DARK)
        c.px(x + 1, y + 6, P.INK_DARK)


def _goblin_down(settle=0):
    """death 후반 — 뒤로 벌렁 누움."""
    c = Canvas(GW, GH)
    cx = GCX
    dy = settle
    # 누운 몸통
    for x in range(6, 28):
        top = 54 + dy
        if 10 <= x <= 24:
            top = 52 + dy
        c.vline(x, top, 62 - top, P.WOOD_BASE)
    c.hline(8, 60, 18, P.WOOD_DEEP)
    # 잠방이
    c.rect(10, 55 + dy, 10, 5, P.GOLD_BASE)
    c.px(13, 57 + dy, P.INK_DARK)
    c.px(17, 56 + dy, P.INK_DARK)
    # 늘어진 팔 + 떨군 방망이
    c.rect(4, 58 + dy, 4, 3, P.WOOD_DEEP)
    c.rect(24, 57 + dy, 6, 2, P.WOOD_BASE)
    c.rect(28, 59, 4, 2, P.WOOD_DEEP)  # 굴러간 방망이
    # 머리 — 옆으로
    c.rect(2, 50 + dy, 9, 8, P.WOOD_BASE)
    c.px(5, 53 + dy, P.INK_DEEPEST)   # 감은 눈(가로선)
    c.hline(4, 53 + dy, 3, P.INK_DARK)
    c.px(2, 48 + dy, P.PAPER_BRIGHT)  # 뿔
    c.px(2, 47 + dy, P.WOOD_DEEP)
    if settle:
        for x, y in ((10, 50), (20, 51), (26, 53)):
            c.px(x, y, P.INK_FAINT)
    outline_multi(c, GOBLIN_OUTLINE)
    return c


def build_goblin():
    return {
        "idle": [draw_goblin(body_dy=0), draw_goblin(body_dy=1)],
        "walk": [
            draw_goblin(body_dy=0, legs="stepL", club_dy=0),
            draw_goblin(body_dy=1, legs="stand", club_dy=1),
            draw_goblin(body_dy=0, legs="stepR", club_dy=0),
            draw_goblin(body_dy=1, legs="stand", club_dy=1),
        ],
        "attack": [
            draw_goblin(body_dy=0, arm="raise", legs="stand"),
            draw_goblin(body_dy=-1, arm="raise", legs="stepL"),
            draw_goblin(body_dy=1, arm="smash", legs="stand"),
        ],
        "death": [
            draw_goblin(body_dy=2, arm="rest", legs="stand", dead=1),
            draw_goblin(body_dy=4, arm="smash", legs="stepR", dead=1),
            _goblin_down(settle=0),
            _goblin_down(settle=1),
        ],
    }


# ══════════════════════════════════════════════════════════════
# ② 구미호 (48x48, 축 x=24, 발바닥 y=44)
# ══════════════════════════════════════════════════════════════
FW2, FH2, FCX = 48, 48, 24

FOX_OUTLINE = {
    P.GOLD_BASE: P.GOLD_DEEP,
    P.PAPER_BRIGHT: P.INK_SOFT,
    P.INK_DARK: P.INK_DEEPEST,
    P.GOLD_DEEP: P.INK_MID,
    P.RED_DEEP: P.INK_DARK,
}


def _tail(c, pts, wave, phase):
    """폴리라인 꼬리를 두툼하게(폭 3~4px) 그린다. 끝 2칸은 흰 털."""
    n = len(pts)
    for i in range(n - 1):
        x0, y0 = pts[i]
        x1, y1 = pts[i + 1]
        tip = i >= n - 3
        col = P.PAPER_BRIGHT if tip else P.GOLD_BASE
        steps = max(abs(x1 - x0), abs(y1 - y0), 1)
        for s in range(steps + 1):
            x = round(x0 + (x1 - x0) * s / steps)
            y = round(y0 + (y1 - y0) * s / steps) + (wave if (i + phase) % 2 else 0)
            w = 4 - (3 * i) // n   # 뿌리 두껍고 끝 가늘게
            c.rect(x - w // 2, y, w, 2, col)
            if not tip:
                c.px(x + (w + 1) // 2 - 1, y + 1, P.GOLD_DEEP)  # 아래쪽 음영


def fox_tails(c, spread=0, wave=0):
    """3갈래 꼬리가 위로 부채처럼 크게 펼쳐짐 — 구미호의 핵심 실루엣.
    엉덩이(좌측 x~11,y~30)에서 솟아 캔버스 위쪽까지 길게."""
    s = spread
    # 부채: 왼쪽(뒤로 길게) · 가운데(곧게 위) · 오른쪽(등 너머 위로)
    _tail(c, [(11, 31), (8, 26), (5, 21), (3, 16 - s), (2, 11 - s), (3, 7 - s)], wave, 0)
    _tail(c, [(12, 30), (11, 24), (10, 18), (10, 12 - s), (11, 7 - s)], wave, 1)
    _tail(c, [(13, 29), (14, 23), (16, 18), (18, 13 - s), (20, 9 - s)], wave, 0)


def fox_leg(c, x0, dy=0, lift=0, near=False):
    bot = 44 - lift
    c.rect(x0, 36 + dy, 3, bot - (36 + dy), P.GOLD_BASE if near else P.GOLD_DEEP)
    c.px(x0, bot - 1, P.INK_DARK)  # 발끝
    if near:
        c.vline(x0 + 2, 37 + dy, bot - (37 + dy) - 1, P.GOLD_DEEP)


def fox_head(c, hx, hy, mouth=0, dead=False):
    """여우 머리 — 뾰족 귀 + 긴 주둥이."""
    # 귀 (삼각)
    c.rect(hx + 1, hy - 3, 2, 3, P.GOLD_BASE)
    c.px(hx + 1, hy - 3, P.INK_DARK)
    c.rect(hx + 6, hy - 3, 2, 3, P.GOLD_BASE)
    c.px(hx + 7, hy - 3, P.INK_DARK)
    c.px(hx + 2, hy - 1, P.PAPER_BRIGHT)  # 귀 속털
    c.px(hx + 6, hy - 1, P.PAPER_BRIGHT)
    # 머리
    c.rect(hx, hy, 9, 7, P.GOLD_BASE)
    c.px(hx, hy, P.TRANSPARENT)
    c.px(hx + 8, hy, P.TRANSPARENT)
    c.vline(hx + 8, hy + 1, 5, P.GOLD_DEEP)
    # 긴 주둥이 (앞 = 오른쪽)
    c.rect(hx + 8, hy + 3, 5, 3, P.GOLD_BASE)
    c.rect(hx + 10, hy + 4, 3, 2, P.PAPER_BRIGHT)  # 흰 주둥이끝
    c.px(hx + 12, hy + 4, P.INK_DEEPEST)           # 코
    # 눈 (째진 — 요사스러움)
    if dead:
        c.hline(hx + 4, hy + 3, 3, P.INK_DARK)
    else:
        c.px(hx + 5, hy + 3, P.RED_DEEP)
        c.px(hx + 6, hy + 3, P.INK_DEEPEST)
        c.px(hx + 4, hy + 2, P.INK_DARK)  # 째진 눈꼬리
    if mouth:
        c.rect(hx + 9, hy + 6, 4, 2, P.RED_DEEP)
        c.px(hx + 9, hy + 6, P.PAPER_BRIGHT)   # 송곳니
        c.px(hx + 12, hy + 6, P.PAPER_BRIGHT)
    # 흰 볼털
    c.px(hx - 1, hy + 4, P.PAPER_BRIGHT)
    c.px(hx - 1, hy + 5, P.PAPER_BRIGHT)


def draw_fox(body_dy=0, tail_spread=0, tail_wave=0,
             legs="stand", pose=None, mouth=0, head_dx=0, head_dy=0, dead_eye=False):
    c = Canvas(FW2, FH2)
    cx = FCX
    fox_tails(c, spread=tail_spread, wave=tail_wave)

    # 원경 다리
    if pose != "leap":
        fox_leg(c, 13, dy=body_dy, lift=(1 if legs == "stepR" else 0))
        fox_leg(c, 30, dy=body_dy, lift=(1 if legs == "stepL" else 0))

    # 몸통 (날렵한 여우 — 등이 길고 낮음)
    for x in range(10, 36):
        top = 28 + body_dy
        if 14 <= x <= 30:
            top = 27 + body_dy
        if x >= 31:
            top = 26 + body_dy  # 앞가슴 높음
        c.vline(x, top, 36 + body_dy - top, P.GOLD_BASE)
    # 흰 가슴/배
    c.hline(12, 34 + body_dy, 22, P.PAPER_BRIGHT)
    c.rect(31, 30 + body_dy, 4, 5, P.PAPER_BRIGHT)  # 앞가슴
    # 등 음영
    c.hline(12, 27 + body_dy, 20, P.GOLD_DEEP)

    # 근경 다리
    if pose == "leap":  # 도약 — 앞발 뻗고 뒷발 차기
        c.rect(34, 26 + body_dy, 3, 4, P.GOLD_BASE)   # 뻗은 앞발
        c.rect(36, 25 + body_dy, 4, 2, P.GOLD_BASE)
        c.px(40, 25 + body_dy, P.PAPER_BRIGHT)        # 발톱
        c.px(40, 26 + body_dy, P.PAPER_BRIGHT)
        c.rect(11, 33 + body_dy, 3, 4, P.GOLD_DEEP)   # 찬 뒷발
    elif pose == "swipe":  # 할퀴기
        c.rect(33, 28 + body_dy, 3, 3, P.GOLD_BASE)
        for i in range(5):
            c.px(37 + i, 26 + body_dy + i, P.PAPER_BRIGHT)  # 발톱 궤적
        fox_leg(c, 16, dy=body_dy, near=True)
    else:
        fox_leg(c, 16, dy=body_dy, lift=(1 if legs == "stepL" else 0), near=True)
        fox_leg(c, 33, dy=body_dy, lift=(1 if legs == "stepR" else 0), near=True)

    fox_head(c, 33 + head_dx, 22 + body_dy + head_dy, mouth=mouth, dead=dead_eye)
    outline_multi(c, FOX_OUTLINE)
    return c


def _fox_down(settle=0):
    c = Canvas(FW2, FH2)
    dy = settle
    # 옆으로 누운 몸
    for x in range(10, 36):
        top = 38 + dy
        if 14 <= x <= 30:
            top = 37 + dy
        c.vline(x, top, 44 - top, P.GOLD_BASE)
    c.hline(12, 43, 22, P.PAPER_BRIGHT)
    # 늘어진 꼬리 3갈래 (바닥에 깔림)
    for i, ty in enumerate((40, 42, 41)):
        c.hline(2 + i, ty + dy, 9, P.GOLD_BASE if i else P.PAPER_BRIGHT)
        c.px(2 + i, ty + dy, P.PAPER_BRIGHT)
    # 뻗은 다리
    c.rect(20, 43, 3, 2, P.GOLD_DEEP)
    c.rect(28, 43, 3, 2, P.GOLD_DEEP)
    # 머리 떨굼
    fox_head(c, 33, 33 + dy, mouth=0, dead=True)
    if settle:
        for x, y in ((14, 35), (24, 34), (30, 36)):
            c.px(x, y, P.INK_FAINT)
    outline_multi(c, FOX_OUTLINE)
    return c


def build_fox():
    return {
        "idle": [
            draw_fox(tail_spread=0, tail_wave=0),
            draw_fox(tail_spread=1, tail_wave=-1, body_dy=0),
            draw_fox(tail_spread=2, tail_wave=0, body_dy=1),
            draw_fox(tail_spread=1, tail_wave=1, body_dy=0),
        ],
        "walk": [
            draw_fox(legs="stepL", tail_spread=1, head_dx=1),
            draw_fox(legs="stand", tail_spread=1, tail_wave=-1, body_dy=-1),
            draw_fox(legs="stepR", tail_spread=1, head_dx=1),
            draw_fox(legs="stand", tail_spread=2, tail_wave=1, body_dy=-1),
        ],
        "attack": [
            draw_fox(pose=None, legs="stand", body_dy=2, tail_spread=2, head_dy=1),  # 웅크림
            draw_fox(pose="leap", body_dy=-3, tail_spread=3, mouth=1, head_dx=1),    # 도약
            draw_fox(pose="swipe", body_dy=0, tail_spread=2, mouth=1, head_dx=1),    # 할퀴기
        ],
        "death": [
            draw_fox(body_dy=2, tail_spread=0, mouth=1, head_dy=2, dead_eye=False),
            draw_fox(body_dy=4, tail_spread=0, head_dy=3, legs="stepR", dead_eye=True),
            _fox_down(settle=0),
            _fox_down(settle=1),
        ],
    }


# ══════════════════════════════════════════════════════════════
MANIFESTS = {
    "goblin": {
        "frame_w": 32, "frame_h": 64,
        "anims": {
            "idle": {"frames": 2, "fps": 3, "loop": True},
            "walk": {"frames": 4, "fps": 7, "loop": True},
            "attack": {"frames": 3, "fps": 9, "loop": False},
            "death": {"frames": 4, "fps": 6, "loop": False},
        },
    },
    "fox": {
        "frame_w": 48, "frame_h": 48,
        "anims": {
            "idle": {"frames": 4, "fps": 5, "loop": True},
            "walk": {"frames": 4, "fps": 8, "loop": True},
            "attack": {"frames": 3, "fps": 11, "loop": False},
            "death": {"frames": 4, "fps": 8, "loop": False},
        },
    },
}


def main():
    os.makedirs(FRAMES_DIR, exist_ok=True)
    built = {"goblin": (GOBLIN_DIR, build_goblin()), "fox": (FOX_DIR, build_fox())}
    sheet_paths, saved = [], []
    for name, (out_dir, anims) in built.items():
        mani = MANIFESTS[name]
        fw, fh = mani["frame_w"], mani["frame_h"]
        for anim, frames in anims.items():
            spec = mani["anims"][anim]
            assert len(frames) == spec["frames"], \
                "%s/%s 프레임 수 불일치: %d != %d" % (name, anim, len(frames), spec["frames"])
            s = strip(frames)
            assert s.w == spec["frames"] * fw and s.h == fh, \
                "%s/%s 스트립 크기 오류: %dx%d (기대 %dx%d)" % (name, anim, s.w, s.h, spec["frames"] * fw, fh)
            path = os.path.join(out_dir, anim + ".png")
            s.save(path)
            saved.append(path)
            print("OK  %-24s %dx%d (%d frames)" % (os.path.relpath(path, ROOT), s.w, s.h, len(frames)))
            for i, f in enumerate(frames):
                fp = os.path.join(FRAMES_DIR, "%s_%s_%d.png" % (name, anim, i))
                f.save(fp, preview_scale=1)
                sheet_paths.append(fp)
            for k in range((-len(frames)) % 4):
                fp = os.path.join(FRAMES_DIR, "%s_%s_blank%d.png" % (name, anim, k))
                Canvas(fw, fh).save(fp, preview_scale=1)
                sheet_paths.append(fp)
        mp = os.path.join(out_dir, "manifest.json")
        with open(mp, "w", encoding="utf-8") as f:
            json.dump(mani, f, indent=2, ensure_ascii=False)
        saved.append(mp)
        print("OK  %s" % os.path.relpath(mp, ROOT))
    contact_sheet(sheet_paths, SHEET_PATH, scale=6, cols=4)
    print("OK  sheet -> %s" % os.path.relpath(SHEET_PATH, ROOT))
    return saved


if __name__ == "__main__":
    main()
