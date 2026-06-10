# -*- coding: utf-8 -*-
"""주인공 PoC — 떠돌이 무사 idle 1프레임 (스타일 기준점).

비율(STYLE_BIBLE §2, 48px 본체 + 갓):
  갓 ~8px(본체 위) / 얼굴 12 / 목 2 / 상체(도포) 15 / 하체(도포 자락) 16 / 발 3
캔버스 32x64, 발끝 y=62, 본체 y=14..62, 오른쪽 보기.
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import palette as P
from core import Canvas

W, H = 32, 64
CX = 16            # 몸 중심축
FOOT = 62          # 발바닥
BODY_TOP = FOOT - 48   # =14 머리 꼭대기


def base_idle() -> Canvas:
    c = Canvas(W, H)

    # ── 하체: 도포 자락 (y 43..59) — 아래로 살짝 퍼지는 사다리꼴 ──
    for i, y in enumerate(range(43, 59)):
        half = 5 + i // 4          # 5→8 로 퍼짐
        c.hline(CX - half, y, half * 2, P.PAPER_BASE)
    # 자락 우하단 음영 + 주름 디더
    for i, y in enumerate(range(43, 59)):
        half = 5 + i // 4
        c.rect(CX + half - 2, y, 2, 1, P.PAPER_SHADE)
    c.dither(CX - 2, 48, 2, 10, P.PAPER_SHADE)         # 가운데 주름
    c.hline(CX - 8, 58, 16, P.PAPER_SHADE)             # 밑단

    # ── 발 (y 59..61) — 짚신/가죽신, 오른쪽 보기라 앞발 강조 ──
    c.rect(CX - 5, 59, 4, 3, P.WOOD_DEEP)              # 뒷발
    c.rect(CX + 1, 59, 5, 3, P.WOOD_DEEP)              # 앞발
    c.px(CX + 5, 59, P.WOOD_BASE)                      # 앞발 하이라이트

    # ── 상체: 도포 (y 28..43) ──
    c.rect(CX - 6, 28, 12, 15, P.PAPER_BASE)
    # 어깨 라운드
    c.px(CX - 6, 28, P.TRANSPARENT); c.px(CX + 5, 28, P.TRANSPARENT)
    # 우하단 음영(등쪽)
    c.rect(CX + 3, 29, 3, 14, P.PAPER_SHADE)
    # 깃(동정) — 사선 여밈: 목에서 오른쪽 아래로
    c.line(CX, 28, CX + 4, 34, P.PAPER_BRIGHT)
    c.line(CX, 29, CX + 4, 35, P.INK_SOFT)
    # 세조대(허리끈) — 가는 청색 띠 + 매듭
    c.hline(CX - 6, 36, 12, P.BLUE_DEEP)
    c.px(CX + 1, 37, P.BLUE_DEEP); c.px(CX + 2, 38, P.BLUE_DEEP)

    # ── 팔: 앞팔은 자연스럽게 내림, 도포 소매 (y 29..38) ──
    c.rect(CX + 4, 29, 3, 9, P.PAPER_BASE)             # 앞쪽 소매
    c.rect(CX + 5, 30, 2, 8, P.PAPER_SHADE)
    c.rect(CX + 5, 38, 2, 2, P.SKIN_BASE)              # 손
    # 뒷팔은 몸통에 가려 음영만
    c.rect(CX - 6, 30, 2, 8, P.PAPER_SHADE)

    # ── 환도(칼) — 왼 허리에 찬 검, 뒤로 비스듬히 ──
    c.line(CX - 8, 40, CX - 1, 35, P.INK_MID)          # 칼집
    c.line(CX - 8, 41, CX - 1, 36, P.INK_DARK)
    c.px(CX - 1, 35, P.GOLD_BASE)                      # 칼자루 끝
    c.px(CX, 34, P.GOLD_DEEP)

    # ── 목 (y 26..28) ──
    c.rect(CX - 1, 26, 3, 2, P.SKIN_SHADE)

    # ── 얼굴 (y 14..26, 갓이 위 3px 덮음) ──
    c.rect(CX - 4, 17, 8, 9, P.SKIN_BASE)              # 얼굴 면
    c.rect(CX + 2, 18, 2, 8, P.SKIN_SHADE)             # 우측(뒤통수쪽) 음영
    c.px(CX - 4, 17, P.TRANSPARENT); c.px(CX + 3, 17, P.TRANSPARENT)
    c.px(CX - 4, 25, P.TRANSPARENT); c.px(CX + 3, 25, P.TRANSPARENT)
    # 눈 (앞쪽 1/3) + 코점
    c.px(CX + 1, 20, P.INK_DEEPEST)
    c.px(CX + 3, 22, P.SKIN_DEEP)
    # 옆머리(귀밑 머리칼)
    c.rect(CX - 4, 18, 2, 4, P.INK_DARK)

    # ── 갓 (y 6..16) — 넓은 챙 + 둥근 모정 ──
    c.hline(CX - 8, 14, 17, P.INK_DEEPEST)             # 챙 (넓게)
    c.hline(CX - 7, 15, 15, P.INK_DARK)                # 챙 두께(아래면)
    c.rect(CX - 4, 8, 9, 6, P.INK_DARK)                # 모정(원통)
    c.hline(CX - 3, 7, 7, P.INK_DARK)
    c.hline(CX - 3, 8, 7, P.INK_DEEPEST)               # 모정 윗단
    c.px(CX - 4, 8, P.TRANSPARENT); c.px(CX + 4, 8, P.TRANSPARENT)
    # 갓 투명감 — 챙 끝 1px 옅게
    c.px(CX - 8, 14, P.INK_MID); c.px(CX + 8, 14, P.INK_MID)
    # 갓끈 — 턱 아래로 청색
    c.px(CX + 3, 16, P.BLUE_BASE)
    c.line(CX + 3, 17, CX + 2, 24, P.BLUE_BASE)

    # ── 선택적 외곽선: 한지(도포) 영역만 옅은 먹으로 ──
    c.outline(P.INK_SOFT, only_color=P.PAPER_BASE)

    return c


if __name__ == "__main__":
    out = os.path.join(os.path.dirname(__file__), "..", "..",
                       "assets", "sprites", "protagonist", "idle_poc.png")
    base_idle().save(os.path.abspath(out))
    print("saved:", os.path.abspath(out))
