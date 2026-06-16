# -*- coding: utf-8 -*-
"""추가 프롭 — 보물 궤짝 + 불탄 산신당(서낭당 터).

규약: STYLE_BIBLE 25색. 외곽선 짝색.
출력: assets/tilesets/chest.png (28x20), assets/tilesets/shrine_ruin.png (96x88)
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import palette as P
from core import Canvas, contact_sheet

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "tilesets")


def _outline(c, mapping):
    src = [[c.get(x, y) for x in range(c.w)] for y in range(c.h)]
    order = list(mapping.keys())
    for y in range(c.h):
        for x in range(c.w):
            if src[y][x][3] != 0:
                continue
            found = None
            for nx, ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if 0 <= nx < c.w and 0 <= ny < c.h:
                    n = src[ny][nx]
                    if n[3] != 0 and n in mapping and (found is None or order.index(n) < order.index(found)):
                        found = n
            if found is not None:
                c.px(x, y, mapping[found])


def chest():
    """보물 궤짝 — 나무 몸통 + 금장 잠금 + 곡면 뚜껑."""
    c = Canvas(28, 20)
    c.rect(3, 9, 22, 9, P.WOOD_BASE)             # 몸통
    c.rect(3, 16, 22, 2, P.WOOD_DEEP)            # 바닥 그림자
    c.vline(23, 10, 7, P.WOOD_DEEP)              # 우측 음영
    # 뚜껑 (곡면)
    for i, x in enumerate(range(3, 25)):
        top = 6 if 8 <= x <= 19 else 7
        c.vline(x, top, 9 - (top - 6), P.WOOD_DEEP)
    c.hline(4, 5, 19, P.WOOD_BASE)
    c.hline(6, 4, 15, P.WOOD_DEEP)
    # 금장 띠 + 자물쇠
    c.vline(7, 5, 13, P.GOLD_DEEP)
    c.vline(20, 5, 13, P.GOLD_DEEP)
    c.rect(12, 10, 4, 4, P.GOLD_BASE)            # 자물쇠
    c.px(13, 11, P.INK_DEEPEST)
    c.px(13, 8, P.GOLD_BASE); c.px(14, 8, P.GOLD_BASE)  # 경첩
    _outline(c, {P.WOOD_BASE: P.WOOD_DEEP, P.GOLD_BASE: P.GOLD_DEEP, P.WOOD_DEEP: P.INK_MID})
    return c


def shrine_ruin():
    """불탄 산신당 터 — 그을린 기둥, 무너진 기와, 한지 부적 잔해."""
    c = Canvas(96, 88)
    base = 80
    # 무너진 기단(돌)
    c.rect(8, base, 80, 6, P.INK_FAINT)
    c.hline(8, base, 80, P.PAPER_DEEP)
    for x in range(10, 86, 6):
        c.px(x, base + 3, P.INK_SOFT)
    # 그을린 기둥 4개 (높낮이 다르게 — 무너진 느낌)
    posts = [(16, 40), (36, 22), (58, 30), (78, 48)]
    for px, h in posts:
        top = base - h
        c.rect(px, top, 6, h, P.INK_DARK)        # 숯덩이 기둥
        c.vline(px, top, h, P.INK_MID)           # 좌측 잿빛
        c.vline(px + 5, top, h, P.INK_DEEPEST)
        # 기둥 끝 부러진 단면 (탄 자국)
        c.hline(px, top, 6, P.RED_DEEP)
        c.px(px + 2, top - 1, P.GOLD_DEEP)       # 아직 식지 않은 불씨
    # 부러진 들보 하나 (사선)
    c.line(36, base - 22, 60, base - 12, P.INK_DARK)
    c.line(36, base - 21, 60, base - 11, P.INK_DEEPEST)
    # 무너진 기와 더미 (좌측)
    for i in range(5):
        c.rect(10 + i * 3, base - 5 - (i % 2), 4, 3, P.INK_DARK)
    # 찢긴 한지 부적 잔해 (기둥에 걸린)
    c.rect(38, base - 18, 4, 6, P.PAPER_SHADE)
    c.px(39, base - 16, P.RED_DEEP)
    c.px(40, base - 13, P.PAPER_SHADE)           # 펄럭이는 끝
    # 잿더미 바닥
    for x in range(14, 84, 5):
        c.px(x, base - 1, P.INK_MID)
    _outline(c, {P.INK_DARK: P.INK_DEEPEST, P.PAPER_DEEP: P.INK_SOFT,
                 P.PAPER_SHADE: P.INK_SOFT, P.RED_DEEP: P.INK_DARK})
    return c


def main():
    paths = []
    for name, fn in [("chest", chest), ("shrine_ruin", shrine_ruin)]:
        p = os.path.join(OUT, name + ".png")
        fn().save(p, preview_scale=6)
        paths.append(p)
        print("ok", os.path.relpath(p, ROOT))
    contact_sheet(paths, os.path.join(ROOT, "shots", "sheets", "props2_sheet.png"), scale=5, cols=2)
    print("ok sheet")


if __name__ == "__main__":
    main()
