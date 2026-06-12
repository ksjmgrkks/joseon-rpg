# -*- coding: utf-8 -*-
"""주인공 — 갓 쓴 떠돌이 무사. 전 애님 10종 (idle/walk/jump/attack/attack2/attack3/charge/dodge/hurt/death).

규격 (AGENT_GUIDE §1): 32x64, 발바닥 y=62, 축 x=16, 오른쪽 보기.
비율: 갓 +7px / 얼굴 12 / 목 2 / 상체 15 / 하체(도포자락) 16 / 발 3 = 본체 48px (y15..62)

PoC(gen_protagonist_poc.base_idle) 대비 반영한 선행 비평:
- 옆머리 먹 블록을 얼굴 뒤(왼쪽) 가장자리에 밀착 + 갓챙 아래 y16 공백 제거 (이마/머리로 채움)
- 갓끈(청색)은 뺨 앞쪽 3px 로 짧게 — 목까지 내리지 않음
- 환도 칼자루(금색 2px)가 칼집 라인 끝과 변(edge) 접촉으로 연결
- 어깨(12px)가 치마 허리(10px)보다 양쪽 1px 씩 넓게 — 남성 실루엣
"""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
import palette as P
from core import Canvas, strip, contact_sheet
from PIL import Image

W, H = 32, 64
CX = 16
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "sprites", "protagonist")
SHEET = os.path.join(ROOT, "shots", "sheets", "protagonist_sheet.png")


# ──────────────────────────────────────────────────────────────
# 부품 (모두 dx/dy 오프셋 지원 — 포즈 합성용)
# ──────────────────────────────────────────────────────────────

def hat(c, dx=0, dy=0):
    """갓 — 넓은 챙(y15, 끝이 살짝 처짐) + 원통 모정(y8..14) + 금 정자."""
    bx = CX + dx
    c.hline(bx - 7, 15 + dy, 15, P.INK_DEEPEST)            # 챙
    c.px(bx - 8, 16 + dy, P.INK_DEEPEST)                   # 챙 끝 곡선 (1px 처짐)
    c.px(bx + 8, 16 + dy, P.INK_DEEPEST)
    c.hline(bx - 6, 16 + dy, 13, P.INK_DARK)               # 챙 아랫면
    c.px(bx - 8, 17 + dy, P.INK_MID)                       # 챙 끝 말총 투명감
    c.px(bx + 8, 17 + dy, P.INK_MID)
    c.rect(bx - 4, 9 + dy, 9, 6, P.INK_DARK)               # 모정
    c.vline(bx - 4, 10 + dy, 5, P.INK_MID)                 # 모정 좌측 결 (광원)
    c.vline(bx + 4, 10 + dy, 5, P.INK_DEEPEST)             # 모정 우측 음영
    c.hline(bx - 3, 8 + dy, 7, P.INK_DARK)
    c.hline(bx - 3, 9 + dy, 7, P.INK_DEEPEST)              # 모정 윗단
    c.px(bx - 4, 9 + dy, P.TRANSPARENT)
    c.px(bx + 4, 9 + dy, P.TRANSPARENT)
    c.px(bx, 7 + dy, P.GOLD_DEEP)                          # 정자(頂子) 장식


def hat_fallen(c, x, y):
    """땅에 떨어진 갓 — 챙이 바닥에 닿고 모정이 위로."""
    c.hline(x - 4, y, 9, P.INK_DEEPEST)                    # 챙 (바닥)
    c.rect(x - 2, y - 3, 5, 3, P.INK_DARK)                 # 모정
    c.hline(x - 2, y - 3, 5, P.INK_DEEPEST)


def head(c, dx=0, dy=0):
    """얼굴 y16..26 — 눈썹·턱 그늘로 떠돌이 무사의 단단한 인상."""
    bx = CX + dx
    c.rect(bx - 4, 16 + dy, 8, 11, P.SKIN_BASE)            # 얼굴면 (y16 갓챙 바로 아래까지)
    c.px(bx - 4, 26 + dy, P.TRANSPARENT)                   # 턱 라운드
    c.px(bx + 3, 26 + dy, P.TRANSPARENT)
    c.rect(bx + 2, 19 + dy, 2, 7, P.SKIN_SHADE)            # 앞면(우) 음영
    c.hline(bx - 3, 17 + dy, 6, P.SKIN_LIGHT)              # 갓챙 아래 이마 (밝은 면)
    c.rect(bx - 4, 16 + dy, 2, 7, P.INK_DARK)              # 옆머리 — 뒤쪽 가장자리, 챙에 밀착
    c.px(bx - 2, 21 + dy, P.INK_DARK)                      # 귀밑머리 한 가닥
    c.hline(bx - 2, 16 + dy, 5, P.INK_DARK)                # 이마 위 머리선
    c.hline(bx, 19 + dy, 2, P.INK_DARK)                    # 눈썹 (굳은 인상)
    c.px(bx + 1, 20 + dy, P.INK_DEEPEST)                   # 눈
    c.px(bx + 3, 22 + dy, P.SKIN_DEEP)                     # 코
    c.px(bx + 1, 24 + dy, P.SKIN_DEEP)                     # 입 (다문)
    c.px(bx, 25 + dy, P.SKIN_SHADE)                        # 턱 그늘
    # 갓끈 — 뺨 앞 라인을 따라 내려옴 + 끝 구슬
    c.px(bx + 3, 18 + dy, P.BLUE_BASE)
    c.px(bx + 3, 19 + dy, P.BLUE_BASE)
    c.px(bx + 3, 20 + dy, P.BLUE_DEEP)
    c.px(bx + 3, 21 + dy, P.GOLD_DEEP)                     # 갓끈 구슬


def neck(c, dx=0, dy=0):
    c.rect(CX + dx - 1, 27 + dy, 3, 2, P.SKIN_SHADE)


def torso(c, dx=0, dy=0):
    """상체 — 한지 도포 위에 청색 전복(소매 없는 쾌자) + 홍색 전대.
    윗단은 dy 로 움직이고 아랫단(y43)은 치마와 맞물려 고정."""
    bx = CX + dx
    top = 29 + dy
    # ── 한지 도포 바탕 (소매 쪽 가장자리가 보임) ──
    c.rect(bx - 6, top, 12, 44 - top, P.PAPER_BASE)        # 어깨 12px
    c.px(bx - 6, top, P.TRANSPARENT)                       # 어깨 라운드
    c.px(bx + 5, top, P.TRANSPARENT)
    c.vline(bx - 6, top + 1, 42 - top, P.PAPER_BRIGHT)     # 좌측 광원 하이라이트
    c.rect(bx + 4, top + 1, 2, 42 - top, P.PAPER_SHADE)    # 우측 음영
    # ── 전복(쾌자) — 청색 소매 없는 덧옷, 가슴~허리 ──
    vtop = top + 2
    c.rect(bx - 4, vtop, 8, 43 - vtop, P.BLUE_DEEP)
    c.vline(bx - 4, vtop, 43 - vtop, P.BLUE_BASE)          # 좌측 광원
    c.vline(bx - 3, vtop + 1, 42 - vtop, P.BLUE_BASE)
    c.vline(bx, vtop + 1, 42 - vtop, P.INK_DARK)           # 가운데 여밈선 (부드럽게)
    c.px(bx - 4, vtop, P.TRANSPARENT)                      # 어깨선 라운드
    c.px(bx + 3, vtop, P.TRANSPARENT)
    # ── 동정(깃) — 전복 위로 드러나는 흰 깃 ──
    c.line(bx, top, bx + 4, top + 4, P.PAPER_BRIGHT)
    c.line(bx - 1, top, bx + 3, top + 4, P.INK_SOFT)
    # ── 전대(허리띠) — 홍색 포인트 + 늘어진 매듭 ──
    belt = min(42, top + 8)
    c.hline(bx - 5, belt, 11, P.RED_DEEP)
    c.px(bx - 2, belt, P.RED_BASE)                         # 매듭 중심 (광원)
    c.px(bx + 1, belt + 1, P.RED_DEEP)                     # 늘어진 끈
    c.px(bx + 1, belt + 2, P.RED_DEEP)
    c.px(bx + 2, belt + 3, P.RED_BASE)


def arm_front(c, dx=0, dy=0):
    """앞팔 자연 내림 — 도포 소매."""
    bx = CX + dx
    c.rect(bx + 4, 30 + dy, 3, 9, P.PAPER_BASE)
    c.rect(bx + 5, 31 + dy, 2, 8, P.PAPER_SHADE)
    c.rect(bx + 5, 39 + dy, 2, 2, P.SKIN_BASE)             # 손


def arm_back(c, dx=0, dy=0):
    c.rect(CX + dx - 6, 31 + dy, 2, 8, P.PAPER_SHADE)


def arm_reach(c, sx, sy, hx, hy):
    """어깨(sx,sy)→손(hx,hy)으로 뻗은 소매 2px + 손."""
    c.line(sx, sy, hx, hy, P.PAPER_BASE)
    c.line(sx, sy + 1, hx, hy + 1, P.PAPER_SHADE)
    c.rect(hx, hy, 2, 2, P.SKIN_BASE)


def sword_hip(c, dx=0, dy=0, with_hilt=True):
    """환도 — 왼 허리 칼집. 금장 코등이/끝장식 + 홍 칼수술로 장식."""
    bx = CX + dx
    c.line(bx - 10, 44 + dy, bx - 2, 37 + dy, P.INK_MID)   # 칼집 (길게)
    c.line(bx - 10, 45 + dy, bx - 2, 38 + dy, P.INK_DARK)
    c.px(bx - 6, 41 + dy, P.INK_FAINT)                     # 칼집 띠돈(금속 결)
    c.px(bx - 10, 45 + dy, P.GOLD_DEEP)                    # 칼집 끝장식(금속 캡)
    c.px(bx - 10, 44 + dy, P.GOLD_DEEP)
    if with_hilt:
        c.px(bx - 2, 36 + dy, P.GOLD_BASE)                 # 코등이 (금장)
        c.px(bx - 1, 37 + dy, P.GOLD_BASE)
        c.px(bx, 35 + dy, P.GOLD_DEEP)                     # 칼자루 끝
        c.px(bx - 2, 39 + dy, P.RED_BASE)                  # 칼수술 (홍)
        c.px(bx - 2, 40 + dy, P.RED_DEEP)


def blade(c, gx, gy, tx, ty, tip=None):
    """뽑은 환도 — 금장 코등이(gx,gy)→칼끝(tx,ty)."""
    c.line(gx, gy, tx, ty, P.INK_FAINT)
    c.px(tx, ty, tip or P.PAPER_BRIGHT)
    c.px(gx, gy, P.GOLD_BASE)


def arc(c, pts, col):
    """칼 궤적 1px 점열."""
    for x, y in pts:
        c.px(x, y, col)


def skirt(c, sway=0, top=44, bottom=59, low_only=True):
    """도포 자락 사다리꼴 — 광원측 하이라이트 + 주름 골 2줄 + sway 흔들림."""
    for i, y in enumerate(range(top, bottom)):
        half = 5 + min(3, i // 4)
        sx = sway if (not low_only or y > 52) else 0
        c.hline(CX - half + sx, y, half * 2, P.PAPER_BASE)
        c.px(CX - half + sx, y, P.PAPER_BRIGHT)                   # 좌측 광원 가장자리
        c.rect(CX + half - 2 + sx, y, 2, 1, P.PAPER_SHADE)
    # 주름 골 — 좌우 두 줄 (몸의 둥근 결)
    mid = (top + bottom) // 2
    c.vline(CX - 3, mid, bottom - mid, P.PAPER_SHADE)
    c.vline(CX + 1, top + 2, bottom - top - 2, P.PAPER_SHADE)
    c.dither(CX + 2, mid, 1, bottom - mid, P.PAPER_SHADE)         # 우측 결 디더
    # 전복 자락 — 청색 밑단이 치마 위로 넓고 짧게 겹침 (끝이 갈라짐)
    c.rect(CX - 3, top, 7, 2, P.BLUE_DEEP)
    c.hline(CX - 3, top, 3, P.BLUE_BASE)
    c.px(CX - 3, top + 2, P.BLUE_DEEP)
    c.px(CX - 2, top + 2, P.BLUE_DEEP)
    c.px(CX + 2, top + 2, P.BLUE_DEEP)
    hb = 5 + min(3, max(0, bottom - top - 1) // 4)
    c.hline(CX - hb + sway, bottom, hb * 2, P.PAPER_SHADE)        # 밑단


def feet(c, ffx=0, ffy=0, bfx=0, bfy=0):
    """짚신 — 발바닥 y=62."""
    c.rect(CX - 5 + bfx, 60 + bfy, 4, 3, P.WOOD_DEEP)      # 뒷발
    c.rect(CX + 1 + ffx, 60 + ffy, 5, 3, P.WOOD_DEEP)      # 앞발
    c.px(CX + 5 + ffx, 60 + ffy, P.WOOD_BASE)              # 앞발 하이라이트


def finish(c):
    """선택적 외곽선 — 한지(도포) 영역만 옅은 먹."""
    c.outline(P.INK_SOFT, only_color=P.PAPER_BASE)
    return c


# ──────────────────────────────────────────────────────────────
# 기본 합성 (idle/walk 용)
# ──────────────────────────────────────────────────────────────

def standing(body_dy=0, sway=0, arm_dx=0, ffx=0, bfx=0, head_fixed=False):
    """서있는 합성. body_dy<0 = 들숨(상체가 1px 올라가고 아랫단은 고정).
    head_fixed=True 면 머리/갓은 body_dy 무시 (walk — 갓 고정)."""
    c = Canvas(W, H)
    hd = 0 if head_fixed else body_dy
    skirt(c, sway=sway)
    feet(c, ffx=ffx, bfx=bfx)
    sword_hip(c, 0, body_dy)
    arm_back(c, -arm_dx, body_dy)
    torso(c, 0, body_dy)
    arm_front(c, arm_dx, body_dy)
    neck(c, 0, hd)
    head(c, 0, hd)
    hat(c, 0, hd)
    return finish(c)


# ──────────────────────────────────────────────────────────────
# 애니메이션 프레임들
# ──────────────────────────────────────────────────────────────

def anim_idle():
    """호흡 — 몸통 1px 상하 + 도포자락 흔들림."""
    return [
        standing(0, 0),
        standing(-1, 0),
        standing(-1, 1),
        standing(0, 1),
    ]


def anim_walk():
    """다리 교차 + 팔 스윙. 갓/머리는 고정 (head_fixed)."""
    spec = [  # (앞발x, 뒷발x, 팔스윙, 자락sway)
        (+3, -3, -1, +1),
        (+2, -2, -1, +1),
        (0, 0, 0, 0),
        (-3, +3, +1, -1),
        (-2, +2, +1, -1),
        (0, 0, 0, 0),
    ]
    return [standing(0, sw, a, ff, bf, head_fixed=True)
            for ff, bf, a, sw in spec]


def anim_jump():
    """상승 웅크림 / 하강 펼침."""
    # f0 — 웅크림: 무릎 끌어올림, 자락 압축, 팔 뒤로
    c = Canvas(W, H)
    skirt(c, sway=0, bottom=56)
    feet(c, ffx=1, ffy=-4, bfx=-1, bfy=-3)                 # 발 끌어올림
    sword_hip(c, 0, 1)
    arm_back(c, 0, 1)
    torso(c, 0, 1)
    c.rect(CX + 4, 31, 3, 6, P.PAPER_BASE)                 # 팔 — 짧게 접음
    c.rect(CX + 5, 32, 2, 5, P.PAPER_SHADE)
    c.rect(CX + 5, 37, 2, 2, P.SKIN_BASE)
    neck(c, 0, 1)
    head(c, 0, 1)
    hat(c, 0, 1)
    f0 = finish(c)
    # f1 — 펼침: 몸 늘리고 자락 펄럭, 팔 위로
    c = Canvas(W, H)
    skirt(c, sway=1, bottom=58)
    feet(c, ffx=2, ffy=0, bfx=-2, bfy=-1)                  # 앞발 뻗고 뒷발 끌림
    sword_hip(c, 0, -1)
    arm_back(c, 0, -2)
    torso(c, 0, -1)
    arm_reach(c, CX + 4, 30, CX + 7, 25)                   # 팔 위로 펼침
    neck(c, 0, -1)
    head(c, 0, -1)
    hat(c, 0, -1)
    f1 = finish(c)
    return [f0, f1]


def anim_attack():
    """발도 → 횡베기."""
    # f0 — 발도: 손이 왼 허리 칼자루로
    c = Canvas(W, H)
    skirt(c)
    feet(c, ffx=2, bfx=-1)
    sword_hip(c, 0, 0, with_hilt=True)
    arm_back(c)
    torso(c)
    arm_reach(c, CX + 3, 31, CX - 1, 35)                   # 손이 칼자루를 잡음
    neck(c)
    head(c)
    hat(c)
    f0 = finish(c)
    # f1 — 횡베기: 칼 수평, 궤적 호
    c = Canvas(W, H)
    skirt(c, sway=1)
    feet(c, ffx=3, bfx=-2)
    sword_hip(c, 0, 0, with_hilt=False)                    # 칼집 비었음
    arm_back(c, -1)
    torso(c, 1)
    arm_reach(c, CX + 4, 31, CX + 8, 32)
    blade(c, CX + 10, 33, CX + 15, 33)                     # 수평 칼
    arc(c, [(CX + 5, 26), (CX + 8, 27), (CX + 11, 29), (CX + 13, 31)], P.INK_FAINT)
    neck(c, 1)
    head(c, 1)
    hat(c, 1)
    f1 = finish(c)
    # f2 — 마무리: 칼 앞아래로 흘림
    c = Canvas(W, H)
    skirt(c, sway=1)
    feet(c, ffx=3, bfx=-2)
    sword_hip(c, 0, 0, with_hilt=False)
    arm_back(c, -1)
    torso(c, 1)
    arm_reach(c, CX + 4, 32, CX + 7, 36)
    blade(c, CX + 8, 38, CX + 13, 44)
    arc(c, [(CX + 14, 34), (CX + 15, 38)], P.INK_FAINT)    # 궤적 잔상
    neck(c, 1)
    head(c, 1)
    hat(c, 1)
    f2 = finish(c)
    return [f0, f1, f2]


def anim_attack2():
    """역베기 — 아래에서 위로 올려치기."""
    # f0 — 칼 낮게 앞아래로 (준비)
    c = Canvas(W, H)
    skirt(c)
    feet(c, ffx=2, bfx=-2)
    sword_hip(c, 0, 0, with_hilt=False)
    arm_back(c)
    torso(c)
    arm_reach(c, CX + 4, 33, CX + 6, 37)
    blade(c, CX + 7, 39, CX + 3, 47)                       # 칼끝 아래로
    neck(c)
    head(c)
    hat(c)
    f0 = finish(c)
    # f1 — 올려베기: 칼 위앞 대각, 아래쪽 궤적
    c = Canvas(W, H)
    skirt(c, sway=1)
    feet(c, ffx=3, bfx=-2)
    sword_hip(c, 0, 0, with_hilt=False)
    arm_back(c, -1)
    torso(c, 1)
    arm_reach(c, CX + 4, 30, CX + 8, 30)
    blade(c, CX + 10, 29, CX + 14, 23)
    arc(c, [(CX + 8, 42), (CX + 11, 38), (CX + 13, 33), (CX + 15, 28)], P.INK_FAINT)
    neck(c, 1)
    head(c, 1)
    hat(c, 1)
    f1 = finish(c)
    # f2 — 마무리: 칼 높이 들림, 몸 살짝 뒤로
    c = Canvas(W, H)
    skirt(c)
    feet(c, ffx=2, bfx=-2)
    sword_hip(c, 0, 0, with_hilt=False)
    arm_back(c)
    torso(c)
    arm_reach(c, CX + 3, 29, CX + 5, 26)
    blade(c, CX + 6, 25, CX + 9, 17)
    arc(c, [(CX + 13, 21), (CX + 15, 25)], P.INK_FAINT)
    neck(c, -1)
    head(c, -1)
    hat(c, -1)
    f2 = finish(c)
    return [f0, f1, f2]


def anim_attack3():
    """내려베기 피니시 (4f) — 마지막 프레임 RED_BASE 1px 궤적."""
    # f0 — 머리 위로 칼 치켜듦
    c = Canvas(W, H)
    skirt(c)
    feet(c, ffx=1, bfx=-1)
    sword_hip(c, 0, 0, with_hilt=False)
    arm_back(c)
    torso(c)
    arm_reach(c, CX + 3, 29, CX + 5, 23)
    blade(c, CX + 6, 22, CX + 9, 12)                       # 칼 머리 위
    neck(c)
    head(c)
    hat(c)
    f0 = finish(c)
    # f1 — 중간 휘두름: 칼 앞위 대각
    c = Canvas(W, H)
    skirt(c, sway=1)
    feet(c, ffx=2, bfx=-1)
    sword_hip(c, 0, 0, with_hilt=False)
    arm_back(c, -1)
    torso(c, 1)
    arm_reach(c, CX + 4, 30, CX + 7, 29)
    blade(c, CX + 8, 28, CX + 14, 24)
    arc(c, [(CX + 7, 14), (CX + 10, 16), (CX + 12, 19)], P.INK_FAINT)
    neck(c, 1)
    head(c, 1)
    hat(c, 1)
    f1 = finish(c)

    def impact(red_trail):
        c = Canvas(W, H)
        skirt(c, sway=1)
        feet(c, ffx=3, bfx=-2)
        sword_hip(c, 0, 2, with_hilt=False)
        arm_back(c, -1, 2)
        torso(c, 1, 2)                                     # 웅크리며 내리침
        arm_reach(c, CX + 4, 34, CX + 6, 36)
        blade(c, CX + 7, 38, CX + 12, 50)                  # 칼끝 땅으로
        c.px(CX + 13, 52, P.PAPER_SHADE)                   # 흙먼지
        c.px(CX + 15, 50, P.PAPER_SHADE)
        if red_trail:                                      # RED_BASE 1px 궤적 강조
            arc(c, [(CX + 9, 14), (CX + 12, 19), (CX + 14, 25),
                    (CX + 15, 32), (CX + 15, 39), (CX + 14, 45)], P.RED_BASE)
        neck(c, 1, 2)
        head(c, 1, 2)
        hat(c, 1, 2)
        return finish(c)

    return [f0, f1, impact(False), impact(True)]


def anim_charge():
    """칼 든 채 모으기 — GOLD 점멸."""
    def pose(sparks, tip_gold):
        c = Canvas(W, H)
        skirt(c)
        feet(c, ffx=2, bfx=-2)
        sword_hip(c, 0, 1, with_hilt=False)
        arm_back(c, 0, 1)
        torso(c, 0, 1)                                     # 낮은 자세
        arm_reach(c, CX + 4, 32, CX + 6, 34)
        blade(c, CX + 7, 33, CX + 12, 26,
              tip=(P.GOLD_BASE if tip_gold else None))
        for (x, y, col) in sparks:
            c.px(x, y, col)
        neck(c, 0, 1)
        head(c, 0, 1)
        hat(c, 0, 1)
        return finish(c)

    f0 = pose([(CX + 10, 29, P.GOLD_BASE), (CX + 13, 30, P.GOLD_BASE),
               (CX + 6, 30, P.GOLD_DEEP)], tip_gold=False)
    f1 = pose([(CX + 12, 23, P.GOLD_BASE), (CX + 9, 32, P.GOLD_DEEP),
               (CX + 14, 28, P.GOLD_BASE)], tip_gold=True)
    return [f0, f1]


def crouch(ffx=1, bfx=-1, arm_out=False):
    """웅크림 자세 (dodge 시작/끝 공용)."""
    c = Canvas(W, H)
    skirt(c)
    feet(c, ffx=ffx, bfx=bfx)
    sword_hip(c, 0, 4)
    torso(c, 0, 6)                                         # 상체 압축
    if arm_out:
        arm_reach(c, CX + 3, 37, CX + 7, 40)
    else:
        c.rect(CX + 4, 36, 3, 6, P.PAPER_BASE)
        c.rect(CX + 5, 37, 2, 5, P.PAPER_SHADE)
        c.rect(CX + 5, 42, 2, 2, P.SKIN_BASE)
    neck(c, 0, 6)
    head(c, 0, 6)
    hat(c, 0, 6)
    return finish(c)


def anim_dodge():
    """구르기 — 낮고 둥근 실루엣."""
    f0 = crouch(ffx=1, bfx=-1)
    # f1 — 공 모양 구르기
    c = Canvas(W, H)
    c.disc(CX, 54, 8, P.PAPER_BASE)                        # 둥근 도포 뭉치 (바닥 y62 접지)
    c.dither(CX + 1, 54, 7, 8, P.PAPER_SHADE)              # 우하단 음영
    c.rect(CX + 1, 48, 4, 3, P.INK_DARK)                   # 말려든 갓
    c.hline(CX - 1, 49, 2, P.INK_DEEPEST)
    c.line(CX - 6, 57, CX + 5, 59, P.BLUE_DEEP)            # 감긴 세조대
    c.line(CX - 5, 52, CX + 2, 51, P.PAPER_SHADE)          # 자락 주름
    c.px(CX - 9, 57, P.INK_FAINT)                          # 구름 모션 점
    c.px(CX - 10, 53, P.INK_FAINT)
    f1 = finish(c)
    f2 = crouch(ffx=3, bfx=-1, arm_out=True)
    return [f0, f1, f2]


def anim_hurt():
    """뒤로 젖힘 (2f)."""
    def pose(lean, sag):
        c = Canvas(W, H)
        skirt(c, sway=-1)
        feet(c, ffx=0, bfx=-1 - (lean > 1))
        sword_hip(c, -1, sag)
        arm_back(c, -1, sag)
        torso(c, -1, sag)
        arm_reach(c, CX + 2, 30 + sag, CX + 5, 26 + sag)   # 팔 휘청
        neck(c, -lean, sag)
        head(c, -lean, sag)
        hat(c, -lean - 1, sag - 1)                         # 갓이 들썩
        return finish(c)
    return [pose(1, 0), pose(2, 1)]


def anim_death():
    """무릎 → 엎어짐, 갓 떨어짐 (5f)."""
    # f0 — 휘청 (hurt 보다 깊게)
    c = Canvas(W, H)
    skirt(c, sway=-1)
    feet(c, ffx=0, bfx=-2)
    sword_hip(c, -1, 1)
    arm_back(c, -1, 1)
    torso(c, -1, 1)
    c.rect(CX + 3, 32, 3, 8, P.PAPER_BASE)                 # 팔 축 늘어짐
    c.rect(CX + 4, 33, 2, 7, P.PAPER_SHADE)
    c.rect(CX + 4, 40, 2, 2, P.SKIN_BASE)
    neck(c, -2, 1)
    head(c, -2, 1)
    hat(c, -3, 0)                                          # 갓 미끄러지기 시작
    f0 = finish(c)

    # f1 — 무릎 꿇음
    c = Canvas(W, H)
    for i, y in enumerate(range(52, 59)):                  # 압축된 자락
        half = 5 + min(3, i // 2)
        c.hline(CX - half, y, half * 2, P.PAPER_BASE)
        c.rect(CX + half - 2, y, 2, 1, P.PAPER_SHADE)
    c.hline(CX - 8, 59, 16, P.PAPER_SHADE)
    c.rect(CX + 3, 60, 4, 3, P.WOOD_DEEP)                  # 앞발 (버팀)
    c.rect(CX - 6, 60, 3, 3, P.PAPER_SHADE)                # 꿇은 무릎
    c.rect(CX - 10, 61, 3, 2, P.WOOD_DEEP)                 # 뒤집힌 뒷발
    torso(c, 0, 8)
    c.rect(CX + 4, 40, 3, 6, P.PAPER_BASE)                 # 팔 늘어짐
    c.rect(CX + 5, 41, 2, 5, P.PAPER_SHADE)
    c.rect(CX + 5, 46, 2, 2, P.SKIN_BASE)
    neck(c, 0, 8)
    head(c, 0, 8)
    hat(c, -4, 7)                                          # 갓이 뒤로 벗겨짐
    f1 = finish(c)

    # f2 — 앞으로 무너짐 (갓은 공중에)
    c = Canvas(W, H)
    for k, y in enumerate(range(50, 58)):                  # 다리/자락 — 뒤쪽 낮게
        c.hline(CX - 8, y, 7 + k // 2, P.PAPER_BASE)
    c.hline(CX - 8, 58, 11, P.PAPER_SHADE)
    c.rect(CX - 10, 59, 3, 3, P.WOOD_DEEP)                 # 뒷발 끌림
    for k, y in enumerate(range(44, 52)):                  # 기운 상체 (앞으로 쏠림)
        c.hline(CX - 6 + k, y, 9, P.PAPER_BASE)
    c.rect(CX + 2, 50, 3, 2, P.PAPER_SHADE)
    arm_reach(c, CX + 3, 50, CX + 8, 57)                   # 땅 짚는 팔
    c.rect(CX + 5, 52, 6, 6, P.SKIN_BASE)                  # 숙인 머리
    c.rect(CX + 5, 52, 6, 2, P.INK_DARK)                   # 상투머리
    c.px(CX + 10, 56, P.INK_DEEPEST)                       # 감긴 눈
    c.line(CX - 9, 30, CX - 3, 28, P.INK_DEEPEST)          # 공중에 뜬 갓 (기울어진 챙)
    c.rect(CX - 7, 25, 4, 3, P.INK_DARK)
    f2 = finish(c)

    # f3 — 엎어짐 (갓 땅에 떨어짐)
    c = Canvas(W, H)
    c.rect(CX - 7, 58, 12, 5, P.PAPER_BASE)                # 누운 몸 (y58..62)
    c.rect(CX - 7, 61, 12, 2, P.PAPER_SHADE)
    c.dither(CX - 5, 59, 8, 2, P.PAPER_SHADE)              # 등 주름
    c.rect(CX + 5, 58, 5, 5, P.SKIN_BASE)                  # 엎어진 머리
    c.rect(CX + 5, 58, 5, 2, P.INK_DARK)
    c.rect(CX - 11, 60, 3, 3, P.WOOD_DEEP)                 # 발
    c.rect(CX - 9, 61, 3, 2, P.WOOD_DEEP)
    arm_reach(c, CX + 7, 59, CX + 10, 60)                  # 뻗은 팔
    hat_fallen(c, CX - 12, 62)                             # 땅에 떨어진 갓
    c.px(CX + 12, 58, P.PAPER_SHADE)                       # 흙먼지
    c.px(CX - 3, 55, P.PAPER_SHADE)
    f3 = finish(c)

    # f4 — 잦아듦 (먼지 가라앉음, 더 납작)
    c = Canvas(W, H)
    c.rect(CX - 7, 59, 12, 4, P.PAPER_BASE)                # 더 납작 (y59..62)
    c.rect(CX - 7, 61, 12, 2, P.PAPER_SHADE)
    c.dither(CX - 5, 60, 8, 1, P.PAPER_SHADE)
    c.rect(CX + 5, 59, 5, 4, P.SKIN_BASE)
    c.rect(CX + 5, 59, 5, 2, P.INK_DARK)
    c.rect(CX - 11, 61, 3, 2, P.WOOD_DEEP)
    c.rect(CX - 9, 61, 3, 2, P.WOOD_DEEP)
    c.hline(CX + 10, 61, 3, P.SKIN_BASE)                   # 늘어진 손
    hat_fallen(c, CX - 12, 62)
    f4 = finish(c)

    return [f0, f1, f2, f3, f4]


# ──────────────────────────────────────────────────────────────
# 출력
# ──────────────────────────────────────────────────────────────

ANIMS = {
    "idle":    (anim_idle,    5, True),
    "walk":    (anim_walk,    9, True),
    "jump":    (anim_jump,    8, False),
    "attack":  (anim_attack,  12, False),
    "attack2": (anim_attack2, 12, False),
    "attack3": (anim_attack3, 12, False),
    "charge":  (anim_charge,  6, True),
    "dodge":   (anim_dodge,   12, False),
    "hurt":    (anim_hurt,    10, False),
    "death":   (anim_death,   8, False),
}


def main():
    manifest = {"frame_w": W, "frame_h": H, "anims": {}}
    paths = []
    for name, (fn, fps, loop) in ANIMS.items():
        frames = fn()
        s = strip(frames)
        path = os.path.join(OUT, name + ".png")
        s.save(path)
        # 검증: frames 수 x frame_w == 스트립 폭
        with Image.open(path) as im:
            assert im.width == len(frames) * W, \
                "%s: strip width %d != %d*%d" % (name, im.width, len(frames), W)
            assert im.height == H
        manifest["anims"][name] = {"frames": len(frames), "fps": fps, "loop": loop}
        paths.append(path)
        print("ok %-8s %d frames -> %s" % (name, len(frames), path))

    mpath = os.path.join(OUT, "manifest.json")
    with open(mpath, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    print("ok manifest ->", mpath)

    contact_sheet(paths, SHEET, scale=6, cols=2)
    print("ok sheet ->", SHEET)


if __name__ == "__main__":
    main()
