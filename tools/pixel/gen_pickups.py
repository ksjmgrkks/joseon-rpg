# -*- coding: utf-8 -*-
"""픽업 아이템 아이콘 — 부적/약초/엽전/서찰 (각 16x16, 바닥에 놓인 줍는 물건).

규약: STYLE_BIBLE 25색. 16x16 캔버스, 외곽선 짝색.
출력: assets/sprites/pickups/<이름>.png (+ preview)
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import palette as P
from core import Canvas, contact_sheet

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "sprites", "pickups")


def _outline(c, mapping):
    src = [[c.get(x, y) for x in range(c.w)] for y in range(c.h)]
    order = list(mapping.keys())
    for y in range(c.h):
        for x in range(c.w):
            if src[y][x][3] != 0:
                continue
            found = None
            for nx, ny in ((x-1, y), (x+1, y), (x, y-1), (x, y+1)):
                if 0 <= nx < c.w and 0 <= ny < c.h:
                    n = src[ny][nx]
                    if n[3] != 0 and n in mapping and (found is None or order.index(n) < order.index(found)):
                        found = n
            if found is not None:
                c.px(x, y, mapping[found])


def charm():
    """부적 — 세로 한지 + 붉은 부적 글씨 + 위 매듭."""
    c = Canvas(16, 16)
    c.rect(5, 2, 6, 12, P.PAPER_BRIGHT)        # 한지 몸체
    c.vline(9, 3, 10, P.PAPER_SHADE)           # 우측 음영
    c.px(7, 1, P.INK_DARK); c.px(8, 1, P.INK_DARK)   # 매듭
    c.px(7, 0, P.BLUE_DEEP)
    # 붉은 부적 글씨 (획 몇 개)
    c.hline(6, 4, 4, P.RED_DEEP)
    c.vline(7, 4, 6, P.RED_BASE)
    c.hline(6, 7, 4, P.RED_DEEP)
    c.px(6, 11, P.RED_DEEP); c.px(9, 11, P.RED_DEEP)
    _outline(c, {P.PAPER_BRIGHT: P.INK_SOFT, P.RED_BASE: P.RED_DEEP, P.INK_DARK: P.INK_DEEPEST})
    return c


def herb():
    """약초 — 녹색 잎 세 갈래 + 줄기."""
    c = Canvas(16, 16)
    c.vline(8, 7, 7, P.GREEN_DEEP)             # 줄기
    # 잎 세 갈래
    c.rect(6, 4, 2, 5, P.GREEN_BASE)
    c.rect(9, 4, 2, 5, P.GREEN_BASE)
    c.rect(7, 2, 3, 5, P.GREEN_BASE)
    c.px(8, 3, P.GRASS_BASE)                   # 잎 하이라이트
    c.px(6, 6, P.GREEN_DEEP); c.px(10, 6, P.GREEN_DEEP)
    c.px(7, 13, P.WOOD_DEEP)                   # 뿌리끝 흙
    _outline(c, {P.GREEN_BASE: P.GREEN_DEEP, P.GREEN_DEEP: P.INK_MID})
    return c


def coin():
    """엽전 — 둥근 놋쇠 + 가운데 네모 구멍."""
    c = Canvas(16, 16)
    c.disc(8, 8, 5, P.GOLD_BASE)
    # 우하단 음영
    for x in range(4, 13):
        for y in range(4, 13):
            if (x-8)**2 + (y-8)**2 <= 27 and (x > 9 or y > 9):
                c.px(x, y, P.GOLD_DEEP)
    c.rect(7, 7, 3, 3, P.TRANSPARENT)          # 네모 구멍
    c.px(6, 5, P.PAPER_BRIGHT)                 # 광택 점
    _outline(c, {P.GOLD_BASE: P.GOLD_DEEP, P.GOLD_DEEP: P.INK_MID})
    return c


def scroll():
    """서찰 — 말린 두루마리 (가로) + 끈."""
    c = Canvas(16, 16)
    c.rect(3, 6, 10, 4, P.PAPER_BRIGHT)        # 종이 몸통
    c.hline(3, 9, 10, P.PAPER_SHADE)
    c.rect(2, 5, 2, 6, P.WOOD_BASE)            # 좌측 축
    c.rect(12, 5, 2, 6, P.WOOD_BASE)           # 우측 축
    c.vline(2, 5, 6, P.WOOD_DEEP); c.vline(13, 5, 6, P.WOOD_DEEP)
    c.vline(7, 6, 4, P.RED_DEEP)               # 봉인 끈
    c.hline(6, 4, 3, P.INK_FAINT)              # 글자 암시
    _outline(c, {P.PAPER_BRIGHT: P.INK_SOFT, P.WOOD_BASE: P.WOOD_DEEP, P.RED_DEEP: P.INK_DARK})
    return c


ITEMS = {"charm": charm, "herb": herb, "coin": coin, "scroll": scroll}


def main():
    paths = []
    for name, fn in ITEMS.items():
        p = os.path.join(OUT, name + ".png")
        fn().save(p, preview_scale=10)
        paths.append(p)
        print("ok", os.path.relpath(p, ROOT))
    contact_sheet(paths, os.path.join(ROOT, "shots", "sheets", "pickups_sheet.png"), scale=10, cols=4)
    print("ok sheet")


if __name__ == "__main__":
    main()
