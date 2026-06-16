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
import sys, os, json, math
sys.path.insert(0, os.path.dirname(__file__))
import palette as P
from core import Canvas, strip, contact_sheet
from PIL import Image

# 프레임을 48px 폭으로 넓혀 창(긴 무기)이 잘리지 않게 한다. 몸은 CX 기준 중앙 정렬.
W, H = 48, 64
CX = 24
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "sprites", "protagonist")
SHEET = os.path.join(ROOT, "shots", "sheets", "protagonist_sheet.png")


# ──────────────────────────────────────────────────────────────
# 부품 (모두 dx/dy 오프셋 지원 — 포즈 합성용)
# ──────────────────────────────────────────────────────────────

def hat(c, dx=0, dy=0):
    """갓(黑笠) — 넓은 말총 챙 + 사다리꼴 모정(통) + 금 정자(頂子). 좌상 광원 음영."""
    bx = CX + dx
    yy = lambda r: r + dy
    # ── 모정(통) y8..14 — 위가 살짝 좁은 사다리꼴 ──
    c.rect(bx - 4, yy(9), 8, 6, P.INK_DARK)
    c.hline(bx - 3, yy(8), 6, P.INK_DEEPEST)              # 윗면 림
    c.vline(bx - 4, yy(9), 6, P.INK_MID)                  # 좌측 광원 결
    c.vline(bx + 3, yy(9), 6, P.INK_DEEPEST)              # 우측 음영
    c.hline(bx - 4, yy(14), 8, P.INK_MID)                 # 통-챙 사이 띠(은은한 결)
    c.px(bx, yy(7), P.GOLD_DEEP)                          # 정자(頂子)
    c.px(bx, yy(6), P.GOLD_BASE)                          # 정자 광
    # ── 챙(brim) y15 — 넓고 끝이 처짐 ──
    c.hline(bx - 8, yy(15), 17, P.INK_DEEPEST)            # 챙 윗면
    c.hline(bx - 7, yy(16), 15, P.INK_DARK)               # 챙 아랫면(두께)
    c.px(bx - 9, yy(16), P.INK_DEEPEST)                   # 좌 끝 처짐
    c.px(bx + 9, yy(16), P.INK_DEEPEST)                   # 우 끝 처짐
    c.px(bx - 8, yy(17), P.INK_MID)                       # 말총 투명감
    c.px(bx + 8, yy(17), P.INK_MID)


def hat_fallen(c, x, y):
    """땅에 떨어진 갓 — 챙이 바닥에 닿고 모정이 위로."""
    c.hline(x - 4, y, 9, P.INK_DEEPEST)                    # 챙 (바닥)
    c.rect(x - 2, y - 3, 5, 3, P.INK_DARK)                 # 모정
    c.hline(x - 2, y - 3, 5, P.INK_DEEPEST)


def head(c, dx=0, dy=0):
    """얼굴(3/4 우향) y17..26 — 단정한 이목구비, 좌상 광원. 갓끈은 얼굴 밖에 드리움.
    조잡한 코·눈썹 덩어리를 정리해 또렷하고 단단한 인상으로."""
    bx = CX + dx
    yy = lambda r: r + dy
    # 1) 얼굴 타원 (SKIN_BASE)
    rows = {17: (-2, 2), 18: (-3, 3), 19: (-3, 3), 20: (-3, 3), 21: (-3, 3),
            22: (-3, 3), 23: (-3, 3), 24: (-2, 3), 25: (-2, 2), 26: (-1, 1)}
    for r, (a, b) in rows.items():
        c.hline(bx + a, yy(r), b - a + 1, P.SKIN_BASE)
    # 2) 광원면 (좌상) SKIN_LIGHT — 이마·광대
    c.hline(bx - 2, yy(17), 4, P.SKIN_LIGHT)
    c.hline(bx - 2, yy(18), 3, P.SKIN_LIGHT)
    c.hline(bx - 2, yy(19), 2, P.SKIN_LIGHT)
    c.px(bx - 2, yy(20), P.SKIN_LIGHT)
    c.px(bx - 2, yy(21), P.SKIN_LIGHT)                     # 광대뼈 하이라이트
    # 3) 음영면 (우하·턱밑) SKIN_SHADE
    for r in (21, 22, 23, 24):
        c.px(bx + 3, yy(r), P.SKIN_SHADE)
    c.hline(bx, yy(25), 3, P.SKIN_SHADE)
    c.px(bx + 1, yy(26), P.SKIN_SHADE)
    c.px(bx, yy(26), P.SKIN_DEEP)                          # 턱끝 그늘
    # 4) 옆머리·구레나룻 (INK_DARK) — 뒤(좌) 가장자리
    for r in range(18, 24):
        c.px(bx - 3, yy(r), P.INK_DARK)
    c.px(bx - 2, yy(18), P.INK_DARK)                       # 살쩍
    c.px(bx - 2, yy(23), P.INK_DARK)                       # 귀밑머리
    # 5) 눈썹 (짧게 1px, 바깥쪽) + 눈 (almond) + 눈두덩 빛
    c.px(bx + 2, yy(19), P.INK_DARK)                       # 눈썹 (한 점, 또렷)
    c.px(bx + 1, yy(20), P.SKIN_LIGHT)                     # 눈두덩(쌍꺼풀 빛)
    c.px(bx + 1, yy(21), P.INK_DEEPEST)                    # 눈
    c.px(bx + 2, yy(21), P.INK_DEEPEST)
    # 6) 코 — 콧대 끝 한 점만 (얼굴이 매끈하게)
    c.px(bx + 2, yy(23), P.SKIN_SHADE)
    # 7) 입 (다문, 한 점)
    c.px(bx, yy(24), P.INK_SOFT)
    # 8) 갓끈 — 얼굴 밖 우측에 드리워 매듭 구슬로 끝남
    c.px(bx + 4, yy(17), P.INK_SOFT)
    c.px(bx + 4, yy(18), P.BLUE_DEEP)
    c.px(bx + 4, yy(19), P.BLUE_DEEP)
    c.px(bx + 4, yy(20), P.GOLD_DEEP)                      # 갓끈 매듭 구슬


def neck(c, dx=0, dy=0):
    c.rect(CX + dx - 1, 27 + dy, 4, 2, P.SKIN_SHADE)       # 목 (넉넉히)
    c.px(CX + dx - 1, 27 + dy, P.SKIN_BASE)                # 목 좌측 빛


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


# 그립~창끝 길이를 모든 공격 프레임에서 '일정하게' 유지한다 (휘둘러도 창이 작아지지 않음).
SPEAR_LEN = 24


def _tip(gx, gy, deg, length=SPEAR_LEN):
    rad = math.radians(deg)
    return gx + int(round(math.cos(rad) * length)), gy + int(round(math.sin(rad) * length))


def spear_angle(c, gx, gy, deg, length=SPEAR_LEN, sweep_from=None, sweep_col=None):
    """일정 길이 창 — 그립(gx,gy)에서 각도 deg(도, 0=→ / -90=↑ / +90=↓)로 뻗는다.
    sweep_from 을 주면 그 각도→현재 각도 사이 부채꼴 잔상(휘두름 궤적)을 그린다."""
    tx, ty = _tip(gx, gy, deg, length)
    # 휘두름 궤적 먼저(창 아래 깔리게)
    if sweep_from is not None:
        col = sweep_col or P.INK_FAINT
        steps = max(2, int(abs(deg - sweep_from) / 12))
        for k in range(1, steps + 1):
            a = sweep_from + (deg - sweep_from) * k / (steps + 1)
            ex, ey = _tip(gx, gy, a, length - 1)
            mx, my = _tip(gx, gy, a, length - 6)
            c.px(ex, ey, col)
            c.px(mx, my, P.PAPER_SHADE if col == P.INK_FAINT else col)
    spear(c, gx, gy, tx, ty)
    return tx, ty


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
    """1타 — 직선 찌르기(5f): 창을 뒤로 슬라이드(물미가 뒤로)했다가 앞으로 내지른다.
    창 '길이는 불변', 그립만 앞뒤로 이동 → 창이 작아지지 않고 묵직하게 뻗는다."""
    frames = []
    GY = 34
    # (그립x, 각도, crouch, lean, ffx, bfx, sway, 풍압?)
    spec = [
        (CX - 9, -6,  1, -1, -1, -1, -1, False),   # f0 장전(뒤로 당김, 물미 뒤로)
        (CX - 6, -5,  0,  0,  1, -2,  0, False),   # f1 돌입
        (CX - 2, -3,  0,  1,  5, -4,  2, True),    # f2 최대 찌름(깊은 런지)
        (CX - 3, -4,  0,  1,  4, -3,  1, True),    # f3 여운
        (CX - 7, -7,  0,  0,  2, -2,  0, False),   # f4 회수
    ]
    for gx, deg, cr, ln, ff, bf, sw, gust in spec:
        c = Canvas(W, H)
        _atk_base(c, crouch=cr, lean=ln, ffx=ff, bfx=bf, sway=sw,
                  head_lean=(-1 if ln < 0 else None))
        hx, hy = gx + 4, GY - 1
        arm_reach(c, CX + 3, 32, hx, hy)                   # 앞손이 그립을 따라감
        tx, ty = spear_angle(c, gx, GY, deg)
        if gust:                                           # 찌름 풍압 잔상
            arc(c, [(tx - 3, ty + 1), (tx - 6, ty + 1)], P.INK_FAINT)
            arc(c, [(tx - 4, ty - 1), (tx - 7, ty - 1)], P.PAPER_SHADE)
        frames.append(finish(c))
    return frames


def anim_attack2():
    """2타 — 넓은 횡쓸기(5f): 머리 위에서 끌어와 큰 호로 쓸어친다.
    창 길이 불변·각도만 회전, sweep 잔상이 호를 채운다."""
    frames = []
    GX, GY = CX - 2, 31
    # (각도, 직전각도(잔상), crouch, lean, ffx, bfx, sway)
    spec = [
        (-105, None, 0, -1, 1, -2, -1),   # f0 감기(우상단 뒤로)
        (-70,  -105, 0,  0, 2, -2,  0),   # f1 끌어내리기 시작
        (-15,  -70,  0,  1, 4, -3,  2),   # f2 수평 강타(넓은 호)
        (35,   -15,  0,  1, 3, -2,  1),   # f3 하단 마무리
        (15,   None, 0,  0, 2, -2,  0),   # f4 회수
    ]
    for deg, prev, cr, ln, ff, bf, sw in spec:
        c = Canvas(W, H)
        _atk_base(c, crouch=cr, lean=ln, ffx=ff, bfx=bf, sway=sw,
                  head_lean=(-1 if ln < 0 else None))
        mx, my = _tip(GX, GY, deg, 8)
        arm_reach(c, CX + 3, 30, mx, my)                   # 앞손이 자루 중간
        spear_angle(c, GX, GY, deg, sweep_from=prev)
        frames.append(finish(c))
    return frames


def anim_attack3():
    """3타 — 회전 내려찍기(선풍 일격, 6f): 머리 위 치켜듦→한 바퀴 회전→땅에 내리꽂기.
    창 길이 불변, 각도가 한 바퀴 돈다. 충격 프레임에 RED 궤적으로 '추가 피해' 강조."""
    frames = []
    GX, GY = CX - 1, 32
    # f0 치켜듦 (수직 위)
    c = Canvas(W, H)
    _atk_base(c, crouch=0, lean=-1, ffx=1, bfx=-1, sway=-1, head_lean=-1)
    arm_reach(c, CX + 3, 30, CX + 2, 26)
    spear_angle(c, GX, GY, -90)
    frames.append(finish(c))
    # f1 회전1 (뒤로 넘어가며 — 좌상단)
    c = Canvas(W, H)
    _atk_base(c, crouch=0, lean=0, ffx=2, bfx=-1, sway=1)
    arm_reach(c, CX + 2, 30, CX, 28)
    spear_angle(c, GX, GY, -150, sweep_from=-90)
    frames.append(finish(c))
    # f2 회전2 (좌하단 지나 앞으로 — 한 바퀴)
    c = Canvas(W, H)
    _atk_base(c, crouch=1, lean=1, ffx=2, bfx=-1, sway=2)
    arm_reach(c, CX + 2, 31, CX + 4, 31)
    spear_angle(c, GX, GY, -210, sweep_from=-150)          # = +150, 좌하단
    frames.append(finish(c))

    def impact(red_trail):
        c = Canvas(W, H)
        _atk_base(c, crouch=2, lean=1, ffx=3, bfx=-2, sway=1)
        arm_reach(c, CX + 4, 33, CX + 6, 35)
        tx, ty = spear_angle(c, GX, GY + 1, 68, sweep_from=(120 if not red_trail else None))
        c.px(tx, ty + 1, P.PAPER_SHADE)                    # 흙먼지
        c.px(tx + 2, ty, P.PAPER_SHADE)
        c.px(tx - 2, ty + 1, P.PAPER_SHADE)
        if red_trail:                                      # 회전 궤적 강조 (추가 피해)
            for a in range(-150, 80, 18):
                ex, ey = _tip(GX, GY, a, SPEAR_LEN - 2)
                c.px(ex, ey, P.RED_BASE)
            c.px(tx, ty, P.RED_BASE)                       # 창끝 핏빛 잔광
        return finish(c)

    frames.append(impact(False))    # f3 내려꽂기
    frames.append(impact(True))     # f4 충격 + 홍 궤적
    # f5 회수 — 창 뽑아 반쯤 일어섬
    c = Canvas(W, H)
    _atk_base(c, crouch=1, lean=0, ffx=2, bfx=-2, sway=0)
    arm_reach(c, CX + 4, 33, CX + 6, 34)
    spear_angle(c, GX, GY, 40)
    frames.append(finish(c))
    return frames


def anim_charge():
    """창에 기를 모으기(3f) — 창을 앞으로 겨눈 채 창끝 GOLD 점멸."""
    def pose(sparks, tip_gold):
        c = Canvas(W, H)
        skirt(c)
        feet(c, ffx=2, bfx=-2)
        arm_back(c, 0, 1)
        torso(c, 0, 1)                                     # 낮은 자세
        arm_reach(c, CX + 3, 32, CX + 5, 32)
        tx, ty = spear_angle(c, CX - 4, 33, -12)           # 창 앞으로 겨눔(일정 길이)
        if tip_gold:
            c.px(tx, ty, P.GOLD_BASE)                      # 창끝 점화
            c.px(tx - 1, ty - 1, P.GOLD_DEEP)
        for (x, y, col) in sparks:
            c.px(x, y, col)
        neck(c, 0, 1)
        head(c, 0, 1)
        hat(c, 0, 1)
        return finish(c)

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
