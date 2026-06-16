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
    """무기 궤적 1px 점열."""
    for x, y in pts:
        c.px(x, y, col)


def spear(c, gx, gy, tx, ty, trail=None):
    """창 — 양손 그립(gx,gy) → 창끝(tx,ty). 나무 자루 + 강철 창날 + 홍 술 + 물미."""
    dx = tx - gx
    dy = ty - gy
    n = max(abs(dx), abs(dy), 1)
    # 두께 방향 (자루를 2px 로 보이게)
    tkx = 1 if abs(dy) >= abs(dx) else 0
    tky = 0 if abs(dy) >= abs(dx) else 1
    # 자루 (나무)
    c.line(gx, gy, tx, ty, P.WOOD_BASE)
    c.line(gx + tkx, gy + tky, tx + tkx, ty + tky, P.WOOD_DEEP)
    # 물미 — 그립 너머 반대쪽으로 짧게
    bx = gx - int(round(dx * 3.0 / n))
    by = gy - int(round(dy * 3.0 / n))
    c.line(gx, gy, bx, by, P.WOOD_DEEP)
    c.px(bx, by, P.GOLD_DEEP)
    # 강철 창날 (끝 5px) + 창끝 광
    sxp = tx - int(round(dx * 5.0 / n))
    syp = ty - int(round(dy * 5.0 / n))
    c.line(sxp, syp, tx, ty, P.INK_FAINT)
    c.px(tx + tkx, ty + tky, P.INK_FAINT)
    c.px(tx, ty, P.PAPER_BRIGHT)
    # 창코 고리 + 홍 술 (창날 아래 매달림)
    jx = tx - int(round(dx * 6.0 / n))
    jy = ty - int(round(dy * 6.0 / n))
    c.px(jx, jy, P.GOLD_BASE)
    c.px(jx, jy + 1, P.RED_BASE)
    c.px(jx, jy + 2, P.RED_DEEP)
    c.px(jx - 1, jy + 1, P.RED_DEEP)
    if trail:
        arc(c, trail, P.INK_FAINT)


def spear_stand(c, dx=0, dy=0, sway=0, tassel=0):
    """세워 든 창 — 좌측에 수직으로. 창날이 갓 위로, 홍 술, 물미. (idle/walk/carry)
    sway: 그립 위(창날·창코)가 좌우로 흔들리는 2차 모션. tassel: 홍 술만 더 흔들림."""
    x = CX + dx - 8
    xt = x + sway                               # 그립 위쪽(흔들리는 부분)
    grip_y = 37 + dy
    # 자루 — 그립(고정) 아래는 수직, 위는 sway 만큼 기울어 그립으로 수렴
    c.vline(x, grip_y, 22 - dy if False else (59 - grip_y), P.WOOD_BASE)   # 아래 자루(그립~물미)
    c.vline(x + 1, grip_y, 59 - grip_y, P.WOOD_DEEP)
    c.line(x, grip_y, xt, 14 + dy, P.WOOD_BASE)      # 위 자루(그립~창코, sway)
    c.line(x + 1, grip_y, xt + 1, 14 + dy, P.WOOD_DEEP)
    c.px(x, 59 + dy, P.GOLD_DEEP)               # 물미
    c.px(x + 1, 59 + dy, P.GOLD_DEEP)
    # 창날 (잎사귀형) y6..13 — sway 따라감
    c.vline(xt, 8 + dy, 6, P.INK_FAINT)
    c.px(xt + 1, 8 + dy, P.INK_FAINT)
    c.px(xt, 6 + dy, P.PAPER_BRIGHT)            # 창끝 광
    c.px(xt, 7 + dy, P.PAPER_BRIGHT)
    c.px(xt - 1, 10 + dy, P.INK_FAINT)          # 날 폭
    c.px(xt + 1, 11 + dy, P.INK_FAINT)
    c.px(xt, 14 + dy, P.GOLD_BASE)              # 창코
    # 홍 술 y15..17 — tassel 만큼 추가로 흔들림(중력 지연)
    tx = xt + tassel
    c.px(tx - 1, 15 + dy, P.RED_BASE)
    c.px(tx, 15 + dy, P.RED_DEEP)
    c.px(tx + 1, 15 + dy, P.RED_BASE)
    c.px(tx, 16 + dy, P.RED_DEEP)
    c.px(tx - 1, 16 + dy, P.RED_DEEP)
    c.px(tx, 17 + dy, P.RED_DEEP)
    # 그립 손 (자루를 쥔)
    c.px(x + 1, grip_y, P.SKIN_BASE)
    c.px(x + 1, grip_y + 1, P.SKIN_BASE)


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


def feet(c, ffx=0, ffy=0, bfx=0, bfy=0, ff_lift=False, bf_lift=False):
    """짚신 — 발바닥 y=62. lift=True 면 들린 발(짧은 발끝)로 그려 보폭 무게가 산다."""
    # 뒷발 (far)
    if bf_lift:
        c.rect(CX - 4 + bfx, 60 + bfy, 3, 2, P.WOOD_DEEP)  # 발끝만 (들림)
    else:
        c.rect(CX - 5 + bfx, 60 + bfy, 4, 3, P.WOOD_DEEP)
    # 앞발 (near)
    if ff_lift:
        c.rect(CX + 2 + ffx, 60 + ffy, 3, 2, P.WOOD_DEEP)  # 발끝만 (들림)
        c.px(CX + 4 + ffx, 60 + ffy, P.WOOD_BASE)
    else:
        c.rect(CX + 1 + ffx, 60 + ffy, 5, 3, P.WOOD_DEEP)
        c.px(CX + 5 + ffx, 60 + ffy, P.WOOD_BASE)          # 앞발 하이라이트


def finish(c):
    """선택적 외곽선 — 한지(도포) 영역만 옅은 먹."""
    c.outline(P.INK_SOFT, only_color=P.PAPER_BASE)
    return c


# ──────────────────────────────────────────────────────────────
# 기본 합성 (idle/walk 용)
# ──────────────────────────────────────────────────────────────

def standing(body_dy=0, sway=0, arm_dx=0, ffx=0, bfx=0, head_fixed=False,
             lean=0, hat_dy=None, ffy=0, bfy=0, ff_lift=False, bf_lift=False,
             sp_sway=0, sp_tassel=0, head_dx=0):
    """서있는 합성 (idle/walk 기반).
    body_dy<0 = 들숨(상체가 올라감). head_fixed=True 면 머리/갓은 body_dy 무시.
    lean: 상체+머리를 진행 방향(+x)으로 기울임. hat_dy: 갓 상하 지연(2차 모션).
    ffy/bfy/*_lift: 발 들림. sp_sway/sp_tassel: 창·홍술 2차 모션. head_dx: 머리 좌우."""
    c = Canvas(W, H)
    hd = 0 if head_fixed else body_dy
    hatdy = hd if hat_dy is None else hat_dy
    skirt(c, sway=sway)
    feet(c, ffx=ffx, ffy=ffy, bfx=bfx, bfy=bfy, ff_lift=ff_lift, bf_lift=bf_lift)
    spear_stand(c, 0, body_dy, sway=sp_sway, tassel=sp_tassel)
    arm_back(c, -arm_dx + lean, body_dy)
    torso(c, lean, body_dy)
    arm_front(c, arm_dx + lean, body_dy)
    neck(c, lean + head_dx, hd)
    head(c, lean + head_dx, hd)
    hat(c, lean + head_dx, hatdy)
    return finish(c)


# ──────────────────────────────────────────────────────────────
# 애니메이션 프레임들
# ──────────────────────────────────────────────────────────────

def anim_idle():
    """호흡(6f) — 들숨에 상체가 천천히 올라가고, 갓은 한 박자 늦게 따라온다(2차 모션).
    창 홍 술이 살랑이고, 무게중심이 미세하게 흔들려 살아있는 정지(idle)."""
    # (body_dy, hem sway, hat_dy 지연, 창 sway, 홍술 tassel)
    spec = [
        (0,  0, 0,  0,  0),
        (0,  0, 0,  0,  1),   # 술이 살짝 오른쪽
        (-1, 0, 0,  0,  1),   # 들숨 시작 (몸 ↑, 갓은 아직)
        (-1, 1, -1, 1,  0),   # 갓 뒤따라 ↑, 창 살짝 기욺
        (0,  1, -1, 1, -1),   # 날숨 (몸 ↓, 갓 지연), 술 왼쪽
        (0,  0, 0,  0,  0),
    ]
    return [standing(body_dy=bd, sway=sw, hat_dy=hd, sp_sway=ss, sp_tassel=ts)
            for bd, sw, hd, ss, ts in spec]


def anim_walk():
    """8프레임 정식 보행 — 접지(무게↓)→통과(무게↑)를 두 번. 발 들림, 자락 반대 스윙,
    팔·창 카운터 스윙, 진행 방향 약간 숙임(lean). 갓은 한 박자 지연(2차 모션)."""
    # i: (앞발x, 뒷발x, 앞발들림, 뒷발들림, body_dy, hem sway, 팔스윙, 창sway, 술)
    spec = [
        # --- 1보 (앞발 디딤) ---
        (+4, -4, False, True,  0,  -1, +1, 0,  0),   # 0 접지(왼발 앞)
        (+3, -3, False, False, 1,  -1, +1, 0,  1),   # 1 무게 받기(↓)
        (+1, -1, False, True,  -1,  0,  0, 1,  1),   # 2 통과(↑, 뒷발 들려 앞으로)
        (-2, +2, True,  False, 0,  +1, -1, 1,  0),   # 3 앞 디딤 준비
        # --- 2보 (뒷발 디딤) ---
        (-4, +4, True,  False, 0,  +1, -1, 0,  0),   # 4 접지(오른발 앞)
        (-3, +3, False, False, 1,  +1, -1, 0, -1),   # 5 무게 받기(↓)
        (-1, +1, True,  False, -1,  0,  0, -1,-1),   # 6 통과(↑, 앞발 들려 앞으로)
        (+2, -2, False, True,  0,  -1, +1, -1, 0),   # 7 뒷 디딤 준비
    ]
    out = []
    for ff, bf, fl, bl, bd, sw, a, ss, ts in spec:
        # 갓은 body_dy 를 한 박자 늦게 따라가게 hat_dy 를 살짝 줄여 지연감
        out.append(standing(body_dy=bd, sway=sw, arm_dx=a, ffx=ff, bfx=bf,
                            ff_lift=fl, bf_lift=bl, ffy=(-1 if fl else 0),
                            bfy=(-1 if bl else 0), head_fixed=True, lean=1,
                            hat_dy=(0 if bd >= 0 else -1), sp_sway=ss, sp_tassel=ts))
    return out


def anim_jump():
    """도약(3f) — 상승(쭉 폄)→정점(웅크려 균형)→하강(자락 펄럭)."""
    # f0 — 상승: 몸 위로 늘이고 발 끌어올림, 창 약간 기욺, 도포 압축
    c = Canvas(W, H)
    skirt(c, sway=0, bottom=57)
    feet(c, ffx=2, ffy=-3, bfx=-2, bfy=-4, ff_lift=True, bf_lift=True)
    spear_stand(c, 0, -1, sway=1, tassel=-1)
    arm_back(c, 0, -1)
    torso(c, 0, -1)
    arm_reach(c, CX + 4, 29, CX + 7, 24)                   # 팔 위로 (상승 반동)
    neck(c, 0, -1)
    head(c, 0, -1)
    hat(c, 0, -2)                                          # 갓 지연
    f0 = finish(c)
    # f1 — 정점: 무릎 끌어올려 웅크림, 팔 균형, 자락 모음
    c = Canvas(W, H)
    skirt(c, sway=0, bottom=55)
    feet(c, ffx=1, ffy=-5, bfx=-1, bfy=-5, ff_lift=True, bf_lift=True)
    spear_stand(c, 0, 0)
    arm_back(c, 0, 0)
    torso(c, 0, 0)
    arm_reach(c, CX + 4, 31, CX + 7, 30)                   # 팔 앞으로 균형
    neck(c, 0, 0)
    head(c, 0, 0)
    hat(c, 0, 0)
    f1 = finish(c)
    # f2 — 하강: 발 내리고 도포 펄럭(위로), 팔 벌림
    c = Canvas(W, H)
    skirt(c, sway=2, bottom=58)
    feet(c, ffx=3, ffy=0, bfx=-3, bfy=-1)                  # 앞발 뻗어 착지 준비
    spear_stand(c, 0, 1, sway=-1, tassel=2)
    arm_back(c, 1, 0)
    torso(c, 0, 0)
    arm_reach(c, CX + 4, 31, CX + 8, 33)                   # 팔 벌려 균형
    c.px(CX - 7, 56, P.PAPER_BRIGHT)                       # 자락 펄럭 끝
    neck(c, 0, 0)
    head(c, 0, 0)
    hat(c, 0, 1)
    f2 = finish(c)
    return [f0, f1, f2]


def _atk_base(c, crouch=0, lean=0, ffx=0, bfx=0, sway=0, head_lean=None):
    """공격 프레임 공통 몸체 — 자락·발·뒤팔·몸통·머리·갓 (앞팔/창은 호출부에서)."""
    hl = lean if head_lean is None else head_lean
    skirt(c, sway=sway)
    feet(c, ffx=ffx, bfx=bfx)
    arm_back(c, -lean, crouch)
    torso(c, lean, crouch)
    neck(c, hl, crouch)
    head(c, hl, crouch)
    hat(c, hl, crouch)


def anim_attack():
    """1타 — 직선 찌르기(5f): 예비(뒤로 당김)→돌입→최대 찌름→여운→회수.
    앞발이 깊게 들어가는 런지와 풍압 잔상으로 묵직함을 준다."""
    frames = []
    # f0 예비 — 무게 뒤로, 창 깊이 당김, 살짝 숙임 준비
    c = Canvas(W, H)
    _atk_base(c, crouch=1, lean=-1, ffx=0, bfx=-1, sway=-1, head_lean=-1)
    arm_reach(c, CX + 2, 32, CX - 1, 35)
    spear(c, CX - 6, 36, CX + 4, 33)                       # 창 뒤로 장전
    frames.append(finish(c))
    # f1 돌입 — 앞발 내딛기 시작, 창 중간까지
    c = Canvas(W, H)
    _atk_base(c, crouch=0, lean=0, ffx=2, bfx=-2, sway=0)
    arm_reach(c, CX + 3, 33, CX + 6, 33)
    spear(c, CX - 3, 34, CX + 9, 33)
    arc(c, [(CX + 5, 33)], P.PAPER_SHADE)
    frames.append(finish(c))
    # f2 최대 찌름 — 깊은 런지, 창 끝까지, 풍압 2줄
    c = Canvas(W, H)
    _atk_base(c, crouch=0, lean=1, ffx=5, bfx=-4, sway=2)
    arm_reach(c, CX + 4, 33, CX + 9, 33)
    spear(c, CX - 1, 34, CX + 15, 33)                      # 길게 찌름
    arc(c, [(CX + 6, 35), (CX + 9, 34), (CX + 12, 34)], P.INK_FAINT)
    arc(c, [(CX + 7, 32), (CX + 10, 32), (CX + 13, 32)], P.PAPER_SHADE)
    frames.append(finish(c))
    # f3 여운 — 창끝 진동(살짝 내려), 무게 앞
    c = Canvas(W, H)
    _atk_base(c, crouch=0, lean=1, ffx=4, bfx=-3, sway=1)
    arm_reach(c, CX + 4, 33, CX + 8, 34)
    spear(c, CX - 1, 35, CX + 14, 34)
    arc(c, [(CX + 11, 35)], P.PAPER_SHADE)
    frames.append(finish(c))
    # f4 회수 — 중심 복귀, 창 절반 당김
    c = Canvas(W, H)
    _atk_base(c, crouch=0, lean=0, ffx=2, bfx=-2, sway=0)
    arm_reach(c, CX + 4, 33, CX + 6, 34)
    spear(c, CX - 2, 35, CX + 10, 33)
    frames.append(finish(c))
    return frames


def anim_attack2():
    """2타 — 넓은 횡쓸기(5f): 위로 감기→상단 시작→수평 강타→하단 마무리→회수.
    창이 큰 호를 그리고 잔상이 호를 채워 휘두름의 궤적이 보인다."""
    frames = []
    # f0 감기 — 창 우상단 뒤로 들어올림, 무게 뒤
    c = Canvas(W, H)
    _atk_base(c, crouch=0, lean=-1, ffx=1, bfx=-2, sway=-1, head_lean=-1)
    arm_reach(c, CX + 3, 29, CX + 6, 26)
    spear(c, CX + 4, 30, CX + 12, 18)                      # 창 비스듬 위 뒤로
    frames.append(finish(c))
    # f1 상단 시작 — 창 머리 위 지나기 시작
    c = Canvas(W, H)
    _atk_base(c, crouch=0, lean=0, ffx=2, bfx=-2, sway=0)
    arm_reach(c, CX + 3, 29, CX + 6, 27)
    spear(c, CX + 2, 30, CX + 14, 22)
    arc(c, [(CX + 8, 17), (CX + 12, 19)], P.INK_FAINT)
    frames.append(finish(c))
    # f2 수평 강타 — 창 거의 수평, 넓은 윗 호
    c = Canvas(W, H)
    _atk_base(c, crouch=0, lean=1, ffx=4, bfx=-3, sway=2)
    arm_reach(c, CX + 4, 31, CX + 8, 31)
    spear(c, CX, 32, CX + 15, 30)                          # 수평 쓸기
    arc(c, [(CX + 5, 21), (CX + 9, 22), (CX + 12, 24), (CX + 15, 27)], P.INK_FAINT)
    arc(c, [(CX + 7, 19), (CX + 11, 20)], P.PAPER_SHADE)
    frames.append(finish(c))
    # f3 하단 마무리 — 창 우하단으로 흘려 호 완성
    c = Canvas(W, H)
    _atk_base(c, crouch=0, lean=1, ffx=3, bfx=-2, sway=1)
    arm_reach(c, CX + 4, 33, CX + 7, 35)
    spear(c, CX + 1, 33, CX + 14, 41)                      # 우하단
    arc(c, [(CX + 13, 27), (CX + 15, 32), (CX + 15, 38)], P.INK_FAINT)
    frames.append(finish(c))
    # f4 회수 — 중심 복귀
    c = Canvas(W, H)
    _atk_base(c, crouch=0, lean=0, ffx=2, bfx=-2, sway=0)
    arm_reach(c, CX + 4, 33, CX + 6, 33)
    spear(c, CX - 1, 34, CX + 10, 34)
    frames.append(finish(c))
    return frames


def anim_attack3():
    """3타 — 회전 내려찍기(선풍 일격, 6f): 치켜듦→회전1→회전2→내려꽂기→충격(홍 궤적)→회수.
    마지막 타격 프레임에 RED 1px 궤적으로 '추가 피해'를 강조."""
    frames = []
    # f0 치켜듦 — 창 머리 위 수직, 살짝 뒤로 (예비)
    c = Canvas(W, H)
    _atk_base(c, crouch=0, lean=-1, ffx=1, bfx=-1, sway=-1, head_lean=-1)
    arm_reach(c, CX + 3, 29, CX + 4, 25)
    spear(c, CX + 3, 30, CX + 5, 11)                       # 창 수직 위
    frames.append(finish(c))
    # f1 회전1 — 창이 앞위→앞 대각으로 돌기 시작, 회전 링 잔상
    c = Canvas(W, H)
    _atk_base(c, crouch=0, lean=1, ffx=2, bfx=-1, sway=1)
    arm_reach(c, CX + 3, 30, CX + 6, 29)
    spear(c, CX, 30, CX + 14, 24)
    arc(c, [(CX + 4, 14), (CX + 8, 15), (CX + 11, 18), (CX + 13, 21)], P.INK_FAINT)
    frames.append(finish(c))
    # f2 회전2 — 창이 몸 가로질러 반대편까지(한 바퀴 도는 중), 링 잔상
    c = Canvas(W, H)
    _atk_base(c, crouch=1, lean=1, ffx=2, bfx=-1, sway=2)
    arm_reach(c, CX + 3, 31, CX + 6, 31)
    spear(c, CX - 8, 28, CX + 13, 32)                      # 창 몸 가로질러
    arc(c, [(CX - 5, 19), (CX, 16), (CX + 5, 16), (CX + 10, 18), (CX + 13, 23)], P.INK_FAINT)
    frames.append(finish(c))

    def impact(red_trail):
        c = Canvas(W, H)
        _atk_base(c, crouch=2, lean=1, ffx=3, bfx=-2, sway=1)
        arm_reach(c, CX + 4, 34, CX + 6, 36)
        spear(c, CX + 1, 33, CX + 13, 51)                  # 창끝 땅으로 꽂음
        c.px(CX + 13, 53, P.PAPER_SHADE)                   # 흙먼지
        c.px(CX + 15, 51, P.PAPER_SHADE)
        c.px(CX + 11, 54, P.PAPER_SHADE)
        if red_trail:                                      # 회전 궤적 강조 (추가 피해)
            arc(c, [(CX - 5, 20), (CX, 16), (CX + 6, 17), (CX + 11, 21),
                    (CX + 14, 28), (CX + 15, 36), (CX + 14, 44)], P.RED_BASE)
            c.px(CX + 13, 49, P.RED_BASE)                  # 창끝 핏빛 잔광
        return finish(c)

    frames.append(impact(False))    # f3 내려꽂기
    frames.append(impact(True))     # f4 충격 + 홍 궤적
    # f5 회수 — 창 땅에서 뽑아 반쯤 일어섬
    c = Canvas(W, H)
    _atk_base(c, crouch=1, lean=0, ffx=2, bfx=-2, sway=0)
    arm_reach(c, CX + 4, 33, CX + 7, 35)
    spear(c, CX + 1, 34, CX + 12, 40)
    frames.append(finish(c))
    return frames


def anim_charge():
    """창에 기를 모으기 — 창끝 GOLD 점멸 (찌르기 장전 자세)."""
    def pose(sparks, tip_gold):
        c = Canvas(W, H)
        skirt(c)
        feet(c, ffx=2, bfx=-2)
        arm_back(c, 0, 1)
        torso(c, 0, 1)                                     # 낮은 자세
        arm_reach(c, CX + 4, 32, CX + 7, 33)
        spear(c, CX - 2, 34, CX + 11, 30)                  # 창 앞으로 겨눔
        if tip_gold:
            c.px(CX + 11, 30, P.GOLD_BASE)                 # 창끝 점화
            c.px(CX + 12, 29, P.GOLD_DEEP)
        for (x, y, col) in sparks:
            c.px(x, y, col)
        neck(c, 0, 1)
        head(c, 0, 1)
        hat(c, 0, 1)
        return finish(c)

    # 3프레임 펄스 — 불씨가 모였다 터지는 호흡
    f0 = pose([(CX + 9, 27, P.GOLD_DEEP)], tip_gold=False)
    f1 = pose([(CX + 9, 27, P.GOLD_BASE), (CX + 13, 29, P.GOLD_BASE),
               (CX + 7, 28, P.GOLD_DEEP)], tip_gold=True)
    f2 = pose([(CX + 12, 25, P.GOLD_BASE), (CX + 9, 33, P.GOLD_DEEP),
               (CX + 14, 27, P.GOLD_BASE), (CX + 8, 26, P.GOLD_DEEP)], tip_gold=True)
    return [f0, f1, f2]


def crouch(ffx=1, bfx=-1, arm_out=False):
    """웅크림 자세 (dodge 시작/끝 공용)."""
    c = Canvas(W, H)
    skirt(c)
    feet(c, ffx=ffx, bfx=bfx)
    spear_stand(c, 0, 4)
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


def _roll_ball(spin):
    """구르는 공 모양 도포 뭉치. spin: 0=앞으로 말림, 1=정점(완전 공), 2=펴짐 직전."""
    c = Canvas(W, H)
    c.disc(CX, 54, 8, P.PAPER_BASE)                        # 둥근 도포 뭉치
    c.dither(CX + 1, 54, 7, 8, P.PAPER_SHADE)              # 우하단 음영
    # 말려든 갓 — spin 에 따라 위치가 돈다
    hat_x = [CX + 1, CX - 1, CX - 4][spin]
    hat_y = [48, 47, 49][spin]
    c.rect(hat_x, hat_y, 4, 3, P.INK_DARK)
    c.hline(hat_x, hat_y, 2, P.INK_DEEPEST)
    # 감긴 세조대(청) — 회전 따라 각도 변화
    if spin == 0:   c.line(CX - 6, 57, CX + 5, 59, P.BLUE_DEEP)
    elif spin == 1: c.line(CX - 5, 51, CX + 5, 57, P.BLUE_DEEP)
    else:           c.line(CX - 5, 59, CX + 5, 51, P.BLUE_DEEP)
    c.line(CX - 5, 52, CX + 2, 51, P.PAPER_SHADE)         # 자락 주름
    # 구름(먼지) 모션 점 — 뒤로 흩어짐
    c.px(CX - 9, 57 - spin, P.INK_FAINT)
    c.px(CX - 10, 53 + spin, P.INK_FAINT)
    c.px(CX - 11, 55, P.PAPER_SHADE)
    return finish(c)


def anim_dodge():
    """구르기(4f) — 웅크림→공 말림→정점 회전→펴며 일어섬. 둥근 실루엣으로 무적 표현."""
    f0 = crouch(ffx=1, bfx=-1)
    f1 = _roll_ball(0)
    f2 = _roll_ball(1)
    f3 = crouch(ffx=3, bfx=-1, arm_out=True)
    return [f0, f1, f2, f3]


def anim_hurt():
    """피격 젖힘(3f) — 충격(확 젖힘)→최대 휘청→복귀. 갓이 들썩이는 2차 모션."""
    def pose(lean, sag, back, tassel):
        c = Canvas(W, H)
        skirt(c, sway=-1)
        feet(c, ffx=-1, bfx=-1 - back)                     # 뒤로 밀린 발
        spear_stand(c, -1, sag, sway=-1, tassel=tassel)    # 창이 충격에 흔들림
        arm_back(c, -1, sag)
        torso(c, -1, sag)
        arm_reach(c, CX + 2, 30 + sag, CX + 5, 26 + sag)   # 팔 휘청
        neck(c, -lean, sag)
        head(c, -lean, sag)
        hat(c, -lean - 1, sag - 1)                         # 갓이 들썩
        return finish(c)
    # f0 충격(급격히 젖힘) → f1 최대 휘청 → f2 복귀
    return [pose(2, 0, 1, -2), pose(2, 1, 1, -1), pose(1, 0, 0, 0)]


def anim_death():
    """무릎 → 엎어짐, 갓 떨어짐 (5f)."""
    # f0 — 휘청 (hurt 보다 깊게)
    c = Canvas(W, H)
    skirt(c, sway=-1)
    feet(c, ffx=0, bfx=-2)
    # 창은 손에서 떨어져 나감 (무기 미표시)
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
    "idle":    (anim_idle,     7, True),
    "walk":    (anim_walk,    12, True),
    "jump":    (anim_jump,     8, False),
    "attack":  (anim_attack,  20, False),
    "attack2": (anim_attack2, 18, False),
    "attack3": (anim_attack3, 16, False),
    "charge":  (anim_charge,   8, True),
    "dodge":   (anim_dodge,   16, False),
    "hurt":    (anim_hurt,    16, False),
    "death":   (anim_death,    8, False),
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
