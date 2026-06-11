# -*- coding: utf-8 -*-
"""적 2종 생성 — 저승사자(reaper 32x64) + 호환 호랑이(tiger 48x48).

reaper: 검은 갓 + 검은 도포 (INK 계열만), 창백한 PAPER_BRIGHT 얼굴.
        발 없음 — 옷자락이 연기처럼 흩어지며 바닥(y=62) 위 2px 부유 (최저 픽셀 y<=59).
        idle(4: 부유 상하) walk(4: 미끄러짐+연기 꼬리) attack(3: 소매 휘두름) death(4: 연기 소멸)

tiger : 한국 민화 호랑이 — 어깨가 크고 머리가 큰 4족. GOLD_BASE 몸 + INK_DARK 줄무늬
        + PAPER_BRIGHT 배/주둥이/구레나룻. 48x48, 발바닥선 y=44(최저 픽셀 43), 축 x=24.
        idle(2: 숨쉬기) walk(4: 대각 보행) attack(3: 앞발 후려치기) death(4: 쓰러짐)

규약: AGENT_GUIDE.md §1~2, STYLE_BIBLE §1(25색)·§3(외곽선 짝색)·§4(광원 좌상단).
"""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
import palette as P
from core import Canvas, strip, contact_sheet

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
REAPER_DIR = os.path.join(ROOT, "assets", "sprites", "enemies", "reaper")
TIGER_DIR = os.path.join(ROOT, "assets", "sprites", "enemies", "tiger")
FRAMES_DIR = os.path.join(ROOT, "shots", "frames", "reaper_tiger")
SHEET_PATH = os.path.join(ROOT, "shots", "sheets", "reaper_tiger_sheet.png")


# ──────────────────────────────────────────────────────────────
# 공용: 색별 외곽선 (검정 단색 금지 — 베이스의 짝색으로)
# ──────────────────────────────────────────────────────────────
def outline_multi(c, mapping):
    """빈 픽셀의 상하좌우 이웃이 mapping 에 있는 색이면 그 짝색으로 외곽선.
    mapping 의 삽입 순서가 우선순위 (먼저 등록한 색이 이김)."""
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
    """결정적 의사난수 0..96"""
    return (x * 13 + y * 29 + s * 53) % 97


# ══════════════════════════════════════════════════════════════
# ① 저승사자 (32x64, 축 x=16, 바닥선 y=62 — 2px 부유라 최저 픽셀 59)
# ══════════════════════════════════════════════════════════════
RW, RH, RCX = 32, 64, 16


def draw_reaper(dy=0, lean=0, sleeve="rest", phase=0, trail=0):
    """dy: 부유 보브(음수=위). lean: 머리 전진 기울임(px).
    sleeve: rest|raise|swing|down. phase: 연기 디더 위상. trail: 뒤(왼쪽) 연기 꼬리 길이."""
    c = Canvas(RW, RH)
    cx = RCX

    def half_w(y):
        if y == 26:
            return 4
        if y == 27:
            return 5
        if 28 <= y <= 30:
            return 6
        if 31 <= y <= 37:
            return 7
        return 8

    # ── 도포 본체 (y26..59) — 좌측 INK_MID(광원) / 중앙 INK_DARK / 우측 INK_DEEPEST ──
    for y in range(26, 60):
        h = half_w(y)
        for x in range(cx - h, cx + h + 1):
            if x <= cx - h + 1:
                col = P.INK_MID
            elif x >= cx + h - 2:
                col = P.INK_DEEPEST
            else:
                col = P.INK_DARK
            c.px(x, y + dy, col)
    # 주름 골 (세로 명암)
    c.vline(cx + 2, 40 + dy, 16, P.INK_DEEPEST)
    c.vline(cx - 4, 42 + dy, 14, P.INK_MID)

    # ── 소매 (팔은 소매 속) ──
    if sleeve == "rest":  # 두 손 모음 — 가로 소매단
        c.rect(cx - 5, 33 + dy, 11, 5, P.INK_DARK)
        c.hline(cx - 5, 33 + dy, 11, P.INK_MID)
        c.hline(cx - 5, 37 + dy, 11, P.INK_DEEPEST)
        c.rect(cx + 4, 34 + dy, 2, 3, P.INK_DEEPEST)  # 소매 입구
    elif sleeve == "raise":  # 치켜듦 (백스윙)
        for i in range(6):
            c.rect(cx + 1 + i, 31 + dy - i, 3, 3, P.INK_DARK)
        c.hline(cx + 1, 30 + dy, 3, P.INK_MID)
        c.rect(cx + 6, 25 + dy, 3, 3, P.INK_DEEPEST)  # 들린 소매 입구
    elif sleeve == "swing":  # 수평 휘두름
        c.rect(cx + 2, 31 + dy, 11, 4, P.INK_DARK)
        c.hline(cx + 2, 31 + dy, 11, P.INK_MID)
        c.rect(cx + 11, 31 + dy, 2, 4, P.INK_DEEPEST)
        c.px(cx + 13, 33 + dy, P.INK_FAINT)  # 바람결
        c.px(cx + 14, 34 + dy, P.INK_FAINT)
    elif sleeve == "down":  # 내려침 후
        for i in range(7):
            c.rect(cx + 2 + i, 33 + dy + i, 3, 2, P.INK_DARK)
        c.rect(cx + 8, 40 + dy, 3, 2, P.INK_DEEPEST)

    # ── 목깃 + 창백한 얼굴 (PAPER_BRIGHT) ──
    hx = cx + lean
    c.hline(hx - 3, 25 + dy, 7, P.INK_DEEPEST)  # 높은 깃
    c.rect(hx - 3, 16 + dy, 7, 9, P.PAPER_BRIGHT)
    c.px(hx - 3, 16 + dy, P.TRANSPARENT)
    c.px(hx + 3, 16 + dy, P.TRANSPARENT)
    c.px(hx - 3, 24 + dy, P.TRANSPARENT)
    c.px(hx + 3, 24 + dy, P.TRANSPARENT)
    c.hline(hx - 2, 16 + dy, 5, P.INK_FAINT)  # 갓 그늘
    c.vline(hx + 3, 18 + dy, 6, P.INK_FAINT)  # 우측 음영
    c.px(hx + 1, 19 + dy, P.INK_FAINT)        # 꺼진 눈두덩
    c.px(hx + 1, 20 + dy, P.INK_DEEPEST)      # 눈
    c.px(hx, 23 + dy, P.INK_FAINT)            # 홀쭉한 볼
    # 갓끈 (잿빛)
    c.line(hx + 3, 17 + dy, hx + 2, 24 + dy, P.INK_FAINT)

    # ── 검은 갓 ──
    c.hline(hx - 8, 14 + dy, 17, P.INK_DEEPEST)   # 챙
    c.hline(hx - 7, 15 + dy, 15, P.INK_DARK)      # 챙 밑면
    c.rect(hx - 4, 8 + dy, 9, 6, P.INK_DARK)      # 모정
    c.hline(hx - 3, 7 + dy, 7, P.INK_DARK)
    c.hline(hx - 3, 8 + dy, 7, P.INK_DEEPEST)
    c.px(hx - 4, 8 + dy, P.TRANSPARENT)
    c.px(hx + 4, 8 + dy, P.TRANSPARENT)
    c.vline(hx + 3, 9 + dy, 5, P.INK_DEEPEST)     # 모정 우측 음영
    c.px(hx - 8, 14 + dy, P.INK_MID)              # 챙 끝 말총 투명감
    c.px(hx + 8, 14 + dy, P.INK_MID)

    # ── 외곽선 (짝색) — 침식 전에 둘러야 연기 부분이 지저분해지지 않음 ──
    outline_multi(c, {
        P.INK_DARK: P.INK_DEEPEST,
        P.INK_MID: P.INK_DARK,
        P.PAPER_BRIGHT: P.INK_SOFT,
    })

    # ── 옷자락 연기 침식 (y52..59) — 아래로 갈수록 듬성듬성 ──
    for y in range(52, 60):
        d = y - 51  # 1..8
        for x in range(RW):
            if c.get(x, y + dy)[3] and _h(x, y, phase) % 9 < d:
                c.px(x, y + dy, P.TRANSPARENT)
    # 떠도는 잔연기
    for y in range(54, 60):
        for x in range(cx - 10, cx + 10):
            if c.get(x, y + dy)[3] == 0 and _h(x, y, phase + 3) % 23 == 0:
                c.px(x, y + dy, P.INK_FAINT)

    # ── 연기 꼬리 (이동 반대쪽 = 왼쪽) ──
    for k in range(trail * 2):
        wx = cx - 9 - k
        wy = 52 + (_h(k, trail, phase) % 5)
        c.px(wx, wy + dy, P.INK_FAINT if k % 2 else P.INK_MID)

    return c


SMOKE_MAP = {
    P.INK_DEEPEST: P.INK_DARK, P.INK_DARK: P.INK_MID, P.INK_MID: P.INK_FAINT,
    P.INK_SOFT: P.INK_FAINT, P.INK_FAINT: P.INK_FAINT, P.PAPER_BRIGHT: P.INK_FAINT,
}


def dissolve(src, frac, seed, lift_max=0, smoke=0.0):
    """디더 기반 연기 소멸 — frac 비율 제거(아래쪽 가중), 생존 픽셀은 위로 lift + 잿빛화."""
    out = Canvas(src.w, src.h)
    for y in range(src.h):
        for x in range(src.w):
            p = src.get(x, y)
            if p[3] == 0:
                continue
            bias = 0.45 + 0.9 * (y / 64.0)  # 아래일수록 먼저 사라짐 (연기는 위로)
            if _h(x, y, seed) / 97.0 < frac * bias:
                continue
            ny = y - (_h(x, y, seed + 7) % (lift_max + 1)) if lift_max else y
            col = p
            if _h(x, y, seed + 11) / 97.0 < smoke:
                col = SMOKE_MAP.get(p, P.INK_FAINT)
            out.px(x, ny, col)
    return out


def build_reaper():
    anims = {}
    # idle — 제자리 부유 (상하 보브 + 연기 위상)
    anims["idle"] = [draw_reaper(dy=d, phase=i) for i, d in enumerate((0, -1, -2, -1))]
    # walk — 앞으로 미끄러짐: 살짝 숙이고(lean) 뒤로 연기 꼬리
    anims["walk"] = [
        draw_reaper(dy=0, lean=1, phase=10, trail=1),
        draw_reaper(dy=-1, lean=1, phase=11, trail=2),
        draw_reaper(dy=-1, lean=1, phase=12, trail=3),
        draw_reaper(dy=0, lean=1, phase=13, trail=2),
    ]
    # attack — 소매 백스윙 → 수평 휘두름 → 내려침
    anims["attack"] = [
        draw_reaper(dy=0, lean=0, sleeve="raise", phase=20),
        draw_reaper(dy=-1, lean=1, sleeve="swing", phase=21),
        draw_reaper(dy=0, lean=1, sleeve="down", phase=22),
    ]
    # death — 디더 소멸 (연기로 흩어짐)
    base = draw_reaper(dy=0, phase=30)
    anims["death"] = [
        dissolve(base, 0.10, 41, lift_max=0, smoke=0.15),
        dissolve(base, 0.34, 42, lift_max=1, smoke=0.45),
        dissolve(base, 0.62, 43, lift_max=3, smoke=0.80),
        dissolve(base, 0.88, 44, lift_max=5, smoke=1.00),
    ]
    return anims


# ══════════════════════════════════════════════════════════════
# ② 호환 호랑이 (48x48, 축 x=24, 발바닥선 y=44 — 최저 픽셀 43)
# ══════════════════════════════════════════════════════════════
TW, TH, TCX = 48, 48, 24


def tiger_tail(c, dy=0, tip=0):
    pts = [(9, 21), (8, 20), (7, 18), (6, 16), (6, 14), (7, 12), (8, 11)]
    for i, (x, y) in enumerate(pts):
        yy = y + dy - (tip if i >= 4 else (tip + 1) // 2 if i >= 2 else 0)
        col = P.INK_DARK if (i // 2) % 2 == 1 or i == len(pts) - 1 else P.GOLD_BASE
        c.px(x, yy, col)
        c.px(x + 1, yy, col)


def tiger_leg(c, x0, color, dx=0, lift=0, top=33, dy=0, near=False, paw_dx=1):
    x = x0 + dx
    bot = 43 - lift
    c.rect(x, top + dy, 4, bot - (top + dy) + 1, color)
    c.rect(x + paw_dx, bot - 1, 4, 2, color)  # 발 (앞으로 한 칸)
    if near:
        c.vline(x + 3, top + dy, bot - (top + dy) - 1, P.GOLD_DEEP)  # 우측 음영
        c.hline(x, top + dy + 5, 4, P.INK_DARK)                      # 발목 줄무늬
    c.px(x + paw_dx + 3, bot, P.PAPER_BRIGHT)  # 발톱

def tiger_torso(c, dy=0):
    for x in range(8, 38):
        top = 21 - (x - 8) // 6
        if x == 26:
            top = 17
        elif x == 27:
            top = 16
        elif x >= 28:
            top = 15  # 민화 호랑이 어깨혹 — 크고 높게
        bottom = 34
        if x == 8:
            top, bottom = 23, 29
        elif x == 9:
            top, bottom = 22, 32
        elif x == 10:
            bottom = 33
        if x >= 33:
            bottom = 36  # 앞가슴 깊음
        c.vline(x, top + dy, bottom - top + 1, P.GOLD_BASE)
    # 하복부 음영 + 한지빛 배
    c.hline(11, 31 + dy, 20, P.GOLD_DEEP)
    c.rect(12, 32 + dy, 19, 3, P.PAPER_BRIGHT)
    for x in range(13, 31, 3):
        c.px(x, 31 + dy, P.PAPER_BRIGHT)  # 물결 배 경계
    # 등~옆구리 줄무늬 (살짝 사선)
    for sx, sy, ln in ((11, 22, 6), (16, 20, 8), (21, 19, 9), (26, 18, 9), (30, 16, 8), (34, 16, 6), (9, 23, 4)):
        c.vline(sx, sy + dy, ln, P.INK_DARK)
        c.vline(sx + 1, sy + 1 + dy, ln, P.INK_DARK)


def tiger_haunch(c, dy=0):
    c.rect(12, 26 + dy, 7, 8, P.GOLD_BASE)
    c.vline(12, 27 + dy, 6, P.GOLD_DEEP)   # 몸통과 분리감
    c.vline(15, 27 + dy, 5, P.INK_DARK)    # 허벅지 줄무늬
    c.vline(16, 28 + dy, 5, P.INK_DARK)
    c.hline(13, 33 + dy, 6, P.GOLD_DEEP)


def tiger_head(c, hx, hy, mouth=0, dead=False):
    """hx,hy = 두개골 좌상단 (기본 33,13). 머리가 큰 민화 비율."""
    # 귀
    c.rect(hx + 1, hy - 2, 3, 2, P.GOLD_BASE)
    c.px(hx + 1, hy - 2, P.INK_DARK)
    c.rect(hx + 7, hy - 2, 3, 2, P.GOLD_BASE)
    c.px(hx + 9, hy - 2, P.INK_DARK)
    # 두개골 + 턱
    c.rect(hx, hy, 12, 10, P.GOLD_BASE)
    c.px(hx, hy, P.TRANSPARENT)
    c.px(hx + 11, hy, P.TRANSPARENT)
    c.rect(hx, hy + 10, 8, 3, P.GOLD_BASE)
    c.vline(hx + 11, hy + 1, 4, P.GOLD_DEEP)  # 우상단 음영
    # 이마 줄무늬 (왕(王) 기운)
    c.hline(hx + 2, hy + 1, 5, P.INK_DARK)
    c.px(hx + 4, hy, P.INK_DARK)
    c.hline(hx + 1, hy + 3, 4, P.INK_DARK)
    # 눈 + 눈썹
    c.hline(hx + 8, hy + 3, 3, P.INK_DARK)
    if dead:
        c.hline(hx + 8, hy + 4, 2, P.INK_DARK)  # 감은 눈
    else:
        c.px(hx + 8, hy + 4, P.INK_DEEPEST)
        c.px(hx + 9, hy + 4, P.INK_DEEPEST)
    # 주둥이 (한지빛)
    if mouth == 0:
        c.rect(hx + 7, hy + 6, 6, 5, P.PAPER_BRIGHT)
        c.px(hx + 12, hy + 6, P.INK_DEEPEST)  # 코
        c.px(hx + 12, hy + 7, P.INK_DARK)
        c.hline(hx + 9, hy + 9, 4, P.INK_SOFT)  # 입선
        c.px(hx + 8, hy + 8, P.INK_SOFT)        # 수염점
    else:  # 벌린 아가리 — 붉은 입속 + 송곳니
        c.rect(hx + 7, hy + 6, 6, 3, P.PAPER_BRIGHT)
        c.px(hx + 12, hy + 6, P.INK_DEEPEST)
        c.rect(hx + 8, hy + 9, 5, 3, P.RED_DEEP)
        c.px(hx + 8, hy + 9, P.PAPER_BRIGHT)   # 윗송곳니
        c.px(hx + 12, hy + 9, P.PAPER_BRIGHT)
        c.hline(hx + 8, hy + 12, 5, P.PAPER_BRIGHT)  # 아래턱
        c.px(hx + 12, hy + 11, P.PAPER_BRIGHT)
    # 흰 구레나룻 (볼털 — 들쭉날쭉)
    c.px(hx - 1, hy + 6, P.PAPER_BRIGHT)
    c.px(hx, hy + 7, P.PAPER_BRIGHT)
    c.px(hx - 1, hy + 8, P.PAPER_BRIGHT)
    c.px(hx, hy + 9, P.PAPER_BRIGHT)
    c.px(hx - 1, hy + 10, P.PAPER_BRIGHT)


TIGER_OUTLINE = {
    P.GOLD_BASE: P.GOLD_DEEP,
    P.INK_DARK: P.INK_DEEPEST,
    P.PAPER_BRIGHT: P.INK_SOFT,
    P.GOLD_DEEP: P.INK_MID,
    P.RED_DEEP: P.INK_DARK,
}


def draw_tiger(body_dy=0, head_dx=0, head_dy=0,
               hf=0, hn=0, ff=0, fn=0,
               lift_fn=0, lift_hn=0,
               front_pose=None, mouth=0, tail_tip=0, dead_eye=False):
    """body_dy: 몸통·머리 침하(+아래). 다리 x오프셋 hf/hn/ff/fn (뒷원경/뒷근경/앞원경/앞근경)."""
    c = Canvas(TW, TH)
    tiger_tail(c, dy=body_dy, tip=tail_tip)
    tiger_leg(c, 10, P.GOLD_DEEP, dx=hf)               # 뒷다리(원경)
    tiger_leg(c, 28, P.GOLD_DEEP, dx=ff)               # 앞다리(원경)
    tiger_torso(c, dy=body_dy)
    tiger_haunch(c, dy=body_dy)
    tiger_leg(c, 14, P.GOLD_BASE, dx=hn, lift=lift_hn, near=True)  # 뒷다리(근경)
    if front_pose is None:
        tiger_leg(c, 32, P.GOLD_BASE, dx=fn, lift=lift_fn, near=True)  # 앞다리(근경)
    elif front_pose == "windup":  # 앞발 들어 움츠림
        c.rect(29, 30 + body_dy, 4, 6, P.GOLD_BASE)
        c.vline(32, 30 + body_dy, 5, P.GOLD_DEEP)
        c.rect(31, 35 + body_dy, 4, 2, P.GOLD_BASE)
        c.px(35, 36 + body_dy, P.PAPER_BRIGHT)
    tiger_head(c, 33 + head_dx, 13 + body_dy + head_dy, mouth=mouth, dead=dead_eye)
    if front_pose == "swipe_high":  # 위→앞 후려치기 (머리 위에 겹침)
        for i in range(10):
            c.rect(31 + i, 34 + body_dy - i // 2, 2, 3, P.GOLD_BASE)
        c.rect(40, 27 + body_dy, 4, 4, P.GOLD_BASE)   # 발
        c.vline(43, 27 + body_dy, 4, P.GOLD_DEEP)
        c.px(44, 27 + body_dy, P.PAPER_BRIGHT)        # 발톱 3개
        c.px(45, 29 + body_dy, P.PAPER_BRIGHT)
        c.px(44, 31 + body_dy, P.PAPER_BRIGHT)
    elif front_pose == "swipe_down":  # 내려찍은 발
        for i in range(8):
            c.rect(31 + i, 33 + body_dy + i, 2, 3, P.GOLD_BASE)
        c.rect(38, 41, 5, 3, P.GOLD_BASE)
        c.px(43, 42, P.PAPER_BRIGHT)
        c.px(43, 43, P.PAPER_BRIGHT)
    outline_multi(c, TIGER_OUTLINE)
    return c


def draw_tiger_down(settle=0):
    """death 후반 — 옆으로 쓰러져 누움. settle=1 이면 한 뼘 더 가라앉음."""
    c = Canvas(TW, TH)
    dy = settle
    # 누운 몸통 더미
    for x in range(8, 38):
        top = 36 + dy
        if 10 <= x <= 34:
            top = 35 + dy
        if 14 <= x <= 30:
            top = 34 + dy
        c.vline(x, top, 44 - top, P.GOLD_BASE)
    # 줄무늬 (누운 등)
    for sx in (12, 17, 22, 27, 31):
        c.vline(sx, 36 + dy, 6 - dy, P.INK_DARK)
        c.vline(sx + 1, 37 + dy, 5 - dy, P.INK_DARK)
    # 배 (바닥쪽 한지빛)
    c.hline(14, 43, 14, P.PAPER_BRIGHT)
    # 뻗은 앞다리 / 뒷다리
    c.rect(38, 41, 6, 3, P.GOLD_BASE)
    c.px(44, 42, P.PAPER_BRIGHT)
    c.rect(4, 42, 5, 2, P.GOLD_DEEP)
    # 축 늘어진 꼬리
    c.hline(2, 42 + dy, 7, P.GOLD_BASE)
    c.px(4, 42 + dy, P.INK_DARK)
    c.px(5, 42 + dy, P.INK_DARK)
    c.px(2, 42 + dy, P.INK_DARK)
    # 머리 — 바닥에 떨굼
    tiger_head(c, 33, 30 + dy, mouth=0, dead=True)
    # 흙먼지
    if settle:
        for x, y in ((12, 31), (21, 29), (30, 32)):
            c.px(x, y, P.INK_FAINT)
    outline_multi(c, TIGER_OUTLINE)
    return c


def build_tiger():
    anims = {}
    # idle — 숨쉬기 (몸통 1px 침하 + 꼬리 까딱)
    anims["idle"] = [
        draw_tiger(),
        draw_tiger(body_dy=1, tail_tip=1),
    ]
    # walk — 대각 보행 (앞근+뒷원 ↔ 앞원+뒷근)
    anims["walk"] = [
        draw_tiger(hf=2, hn=-2, ff=-2, fn=2),
        draw_tiger(body_dy=-1, lift_fn=1, tail_tip=1),
        draw_tiger(hf=-2, hn=2, ff=2, fn=-2),
        draw_tiger(body_dy=-1, lift_hn=1, tail_tip=1),
    ]
    # attack — 움츠림 → 후려치기(아가리) → 내려찍기
    anims["attack"] = [
        draw_tiger(body_dy=2, head_dy=1, head_dx=-1, front_pose="windup", tail_tip=2),
        draw_tiger(body_dy=-1, front_pose="swipe_high", mouth=1, tail_tip=2),
        draw_tiger(body_dy=0, head_dx=1, front_pose="swipe_down", mouth=1),
    ]
    # death — 휘청 → 무릎 꺾임 → 쓰러짐 → 잠잠
    anims["death"] = [
        draw_tiger(body_dy=1, head_dy=2, mouth=1, tail_tip=-1),
        draw_tiger(body_dy=3, head_dy=4, hf=-2, hn=-1, ff=2, fn=2, tail_tip=-2),
        draw_tiger_down(settle=0),
        draw_tiger_down(settle=1),
    ]
    return anims


# ══════════════════════════════════════════════════════════════
# 출력 — 스트립 + manifest + 검수 시트
# ══════════════════════════════════════════════════════════════
MANIFESTS = {
    "reaper": {
        "frame_w": 32, "frame_h": 64,
        "anims": {
            "idle": {"frames": 4, "fps": 5, "loop": True},
            "walk": {"frames": 4, "fps": 8, "loop": True},
            "attack": {"frames": 3, "fps": 10, "loop": False},
            "death": {"frames": 4, "fps": 6, "loop": False},
        },
    },
    "tiger": {
        "frame_w": 48, "frame_h": 48,
        "anims": {
            "idle": {"frames": 2, "fps": 3, "loop": True},
            "walk": {"frames": 4, "fps": 8, "loop": True},
            "attack": {"frames": 3, "fps": 12, "loop": False},
            "death": {"frames": 4, "fps": 8, "loop": False},
        },
    },
}


def main():
    os.makedirs(FRAMES_DIR, exist_ok=True)
    built = {"reaper": (REAPER_DIR, build_reaper()), "tiger": (TIGER_DIR, build_tiger())}
    sheet_paths = []
    saved = []

    for name, (out_dir, anims) in built.items():
        mani = MANIFESTS[name]
        fw, fh = mani["frame_w"], mani["frame_h"]
        for anim, frames in anims.items():
            spec = mani["anims"][anim]
            assert len(frames) == spec["frames"], \
                "%s/%s 프레임 수 불일치: %d != %d" % (name, anim, len(frames), spec["frames"])
            s = strip(frames)
            assert s.w == spec["frames"] * fw and s.h == fh, \
                "%s/%s 스트립 크기 오류: %dx%d" % (name, anim, s.w, s.h)
            path = os.path.join(out_dir, anim + ".png")
            s.save(path)
            saved.append(path)
            print("OK  %-22s %dx%d (%d frames)" % (os.path.relpath(path, ROOT), s.w, s.h, len(frames)))
            # 검수 시트용 개별 프레임 (행 정렬 위해 4의 배수로 패딩)
            for i, f in enumerate(frames):
                fp = os.path.join(FRAMES_DIR, "%s_%s_%d.png" % (name, anim, i))
                f.save(fp, preview_scale=1)
                sheet_paths.append(fp)
            for _ in range((-len(frames)) % 4):
                blank = Canvas(fw, fh)
                fp = os.path.join(FRAMES_DIR, "%s_%s_blank%d.png" % (name, anim, _))
                blank.save(fp, preview_scale=1)
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
