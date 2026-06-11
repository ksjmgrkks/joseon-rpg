# -*- coding: utf-8 -*-
"""보스 — 호환 두령 (64x64, 축 x=32, 발바닥선 y=62).

거대 호랑이: GOLD_BASE/GOLD_DEEP 몸 + INK_DARK 줄무늬 + PAPER_BRIGHT 배/주둥이.
왼눈 위 RED_DEEP 흉터 + RED_BASE 눈빛, 큰 어깨혹. 민화 호랑이의 위엄 + 괴담의 섬뜩함.
오른쪽 보기.
  idle(4: 호흡+꼬리) walk(4: 대각 보행) telegraph(2: 웅크림+눈 점멸)
  attack(3: 도약 덮치기) heal(3: 웅크려 상처 핥기) death(6: 천천히 무너짐)

규약: AGENT_GUIDE.md §1~2, STYLE_BIBLE §1(25색)·§3·§4.
"""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
import palette as P
from core import Canvas, strip, contact_sheet

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BOSS_DIR = os.path.join(ROOT, "assets", "sprites", "enemies", "boss")
FRAMES_DIR = os.path.join(ROOT, "shots", "frames", "boss")
SHEET_PATH = os.path.join(ROOT, "shots", "sheets", "boss_sheet.png")

W, H, CX = 64, 64, 32
FOOT = 62

OUTLINE = {
    P.GOLD_BASE: P.GOLD_DEEP,
    P.INK_DARK: P.INK_DEEPEST,
    P.PAPER_BRIGHT: P.INK_SOFT,
    P.GOLD_DEEP: P.INK_MID,
    P.RED_DEEP: P.INK_DARK,
    P.RED_BASE: P.RED_DEEP,
}


def outline_multi(c, mapping):
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


def leg(c, x0, dy=0, lift=0, near=False, w=6):
    bot = FOOT - lift
    top = 44 + dy
    c.rect(x0, top, w, bot - top, P.GOLD_BASE if near else P.GOLD_DEEP)
    c.rect(x0 - 1, bot - 2, w + 2, 3, P.GOLD_BASE if near else P.GOLD_DEEP)  # 큰 발
    # 발톱
    for k in range(3):
        c.px(x0 + 1 + k * 2, bot, P.PAPER_BRIGHT)
    if near:
        c.vline(x0 + w - 1, top, bot - top - 2, P.GOLD_DEEP)
        c.hline(x0, top + 7, w, P.INK_DARK)   # 발목 줄무늬
        c.hline(x0, top + 12, w, P.INK_DARK)


def tail(c, dy=0, tip=0):
    pts = [(12, 30), (9, 28), (6, 25), (4, 21), (4, 17), (6, 13), (9, 11 - tip)]
    for i in range(len(pts) - 1):
        x0, y0 = pts[i]; x1, y1 = pts[i + 1]
        steps = max(abs(x1 - x0), abs(y1 - y0), 1)
        for s in range(steps + 1):
            x = round(x0 + (x1 - x0) * s / steps)
            y = round(y0 + (y1 - y0) * s / steps) + dy
            band = (i % 2 == 1)
            c.rect(x - 1, y, 3, 2, P.INK_DARK if band else P.GOLD_BASE)
    c.rect(7, 9 - tip + dy, 4, 3, P.PAPER_BRIGHT)  # 꼬리 끝 흰털


def torso(c, dy=0):
    # 거대한 몸통 — 어깨혹이 높고 크게
    for x in range(10, 52):
        top = 30 - (x - 10) // 8
        if x >= 36:
            top = 22  # 앞 어깨
        if x >= 42:
            top = 20  # 어깨혹 정점
        if x >= 47:
            top = 22
        bottom = 46
        if x < 13:
            top, bottom = 31, 40
        if x >= 46:
            bottom = 48
        c.vline(x, top + dy, bottom - top + 1, P.GOLD_BASE)
    # 등 음영 라인
    c.hline(14, 24 + dy, 30, P.GOLD_DEEP)
    # 흰 배
    c.rect(15, 43 + dy, 30, 4, P.PAPER_BRIGHT)
    c.hline(14, 42 + dy, 30, P.GOLD_DEEP)
    # 줄무늬 (등~옆구리, 살짝 사선, 굵게)
    for sx, sy, ln in ((14, 30, 9), (20, 27, 12), (26, 25, 13), (32, 24, 13),
                       (38, 22, 13), (44, 22, 11), (49, 24, 8)):
        c.rect(sx, sy + dy, 2, ln, P.INK_DARK)
        c.rect(sx + 1, sy + 1 + dy, 2, ln, P.INK_DARK)


def haunch(c, dy=0):
    c.rect(13, 32 + dy, 11, 13, P.GOLD_BASE)
    c.vline(13, 33 + dy, 11, P.GOLD_DEEP)
    c.rect(17, 33 + dy, 2, 9, P.INK_DARK)    # 허벅지 줄무늬
    c.rect(20, 34 + dy, 2, 8, P.INK_DARK)
    c.hline(14, 44 + dy, 9, P.GOLD_DEEP)


def head(c, hx, hy, mouth=0, dead=False, glow=True):
    """큰 머리. hx,hy = 두개골 좌상단(기본 44,16)."""
    # 귀
    c.rect(hx + 1, hy - 3, 4, 3, P.GOLD_BASE)
    c.px(hx + 1, hy - 3, P.INK_DARK)
    c.rect(hx + 10, hy - 3, 4, 3, P.GOLD_BASE)
    c.px(hx + 13, hy - 3, P.INK_DARK)
    c.px(hx + 2, hy - 1, P.PAPER_BRIGHT)
    c.px(hx + 12, hy - 1, P.PAPER_BRIGHT)
    # 두개골 + 턱
    c.rect(hx, hy, 16, 13, P.GOLD_BASE)
    c.px(hx, hy, P.TRANSPARENT)
    c.px(hx + 15, hy, P.TRANSPARENT)
    c.rect(hx, hy + 13, 11, 4, P.GOLD_BASE)
    c.vline(hx + 15, hy + 1, 6, P.GOLD_DEEP)
    # 이마 王 줄무늬
    c.rect(hx + 5, hy, 2, 6, P.INK_DARK)
    c.hline(hx + 3, hy + 1, 7, P.INK_DARK)
    c.hline(hx + 2, hy + 4, 5, P.INK_DARK)
    c.hline(hx + 8, hy + 4, 5, P.INK_DARK)
    # 눈썹
    c.hline(hx + 2, hy + 5, 4, P.INK_DARK)
    c.hline(hx + 10, hy + 5, 4, P.INK_DARK)
    # 눈 — 오른눈 일반, 왼눈(앞쪽 x큰쪽)은 흉터 + 붉은 안광
    c.rect(hx + 2, hy + 6, 3, 2, P.PAPER_BRIGHT)
    if dead:
        c.hline(hx + 2, hy + 6, 3, P.INK_DARK)
        c.hline(hx + 10, hy + 6, 3, P.INK_DARK)
    else:
        c.px(hx + 3, hy + 6, P.INK_DEEPEST)
        # 왼눈 붉은 안광
        c.rect(hx + 10, hy + 6, 3, 2, P.RED_DEEP if not glow else P.RED_BASE)
        c.px(hx + 11, hy + 6, P.INK_DEEPEST if not glow else P.RED_BASE)
    # 왼눈 위 흉터 (대각 붉은 자국)
    c.px(hx + 11, hy + 2, P.RED_DEEP)
    c.px(hx + 12, hy + 3, P.RED_DEEP)
    c.px(hx + 13, hy + 4, P.RED_DEEP)
    # 주둥이
    if mouth == 0:
        c.rect(hx + 9, hy + 8, 8, 6, P.PAPER_BRIGHT)
        c.px(hx + 16, hy + 8, P.INK_DEEPEST)   # 코
        c.hline(hx + 11, hy + 12, 5, P.INK_SOFT)
        c.px(hx + 10, hy + 10, P.INK_SOFT)     # 수염점
        c.px(hx + 9, hy + 11, P.INK_SOFT)
    else:  # 포효
        c.rect(hx + 9, hy + 8, 8, 3, P.PAPER_BRIGHT)
        c.px(hx + 16, hy + 8, P.INK_DEEPEST)
        c.rect(hx + 10, hy + 11, 7, 5, P.RED_DEEP)   # 붉은 입속
        c.px(hx + 10, hy + 11, P.PAPER_BRIGHT)       # 송곳니
        c.px(hx + 16, hy + 11, P.PAPER_BRIGHT)
        c.px(hx + 11, hy + 15, P.PAPER_BRIGHT)       # 아랫니
        c.px(hx + 15, hy + 15, P.PAPER_BRIGHT)
    # 흰 구레나룻
    for k in range(7):
        c.px(hx - 1, hy + 6 + k, P.PAPER_BRIGHT if k % 2 == 0 else P.INK_SOFT)


def front_leg_near(c, dy=0, lift=0, pose=None):
    if pose == "windup":
        c.rect(40, 38 + dy, 6, 8, P.GOLD_BASE)
        c.vline(45, 38 + dy, 7, P.GOLD_DEEP)
        c.rect(43, 45 + dy, 6, 3, P.GOLD_BASE)
        for k in range(3):
            c.px(45 + k, 48 + dy, P.PAPER_BRIGHT)
    elif pose == "swipe":  # 위에서 앞으로 후려치는 큰 발
        for i in range(14):
            c.rect(42 + i, 46 + dy - i, 3, 4, P.GOLD_BASE)
        c.rect(54, 30 + dy, 6, 6, P.GOLD_BASE)
        c.vline(59, 30 + dy, 6, P.GOLD_DEEP)
        for k in range(3):
            c.px(60, 30 + dy + k * 2, P.PAPER_BRIGHT)  # 발톱
            c.px(59 - k, 36 + dy, P.PAPER_BRIGHT)
    else:
        leg(c, 44, dy=dy, lift=lift, near=True, w=6)


def draw_boss(body_dy=0, head_dx=0, head_dy=0, hf=0, hn=0, ff=0, fn=0,
              lift_hn=0, lift_fn=0, mouth=0, tail_tip=0, glow=True,
              front_pose=None, dead=False):
    c = Canvas(W, H)
    tail(c, dy=body_dy, tip=tail_tip)
    leg(c, 16, dy=body_dy, lift=hf, w=6)          # 뒷다리 원경
    leg(c, 40, dy=body_dy, lift=ff, w=6)          # 앞다리 원경
    torso(c, dy=body_dy)
    haunch(c, dy=body_dy)
    leg(c, 20, dy=body_dy, lift=lift_hn or hn, near=True, w=6)  # 뒷다리 근경
    front_leg_near(c, dy=body_dy, lift=lift_fn or fn, pose=front_pose)
    head(c, 44 + head_dx, 16 + body_dy + head_dy, mouth=mouth, dead=dead, glow=glow)
    outline_multi(c, OUTLINE)
    return c


def draw_boss_lick(stage=0):
    """heal — 웅크려 옆구리 상처를 핥음. 머리를 몸쪽으로 숙임. GREEN 점 = 치유 기운."""
    c = Canvas(W, H)
    tail(c, dy=2, tip=-1)
    leg(c, 16, dy=2, w=6)
    leg(c, 40, dy=2, w=6)
    torso(c, dy=2)
    haunch(c, dy=2)
    leg(c, 20, dy=2, near=True, w=6)
    leg(c, 44, dy=2, near=True, w=6)
    # 숙인 머리 — 몸통 중앙 위로
    head(c, 30 + stage, 30 - stage, mouth=1 if stage == 1 else 0, glow=False)
    # 치유 기운 (옅은 녹점)
    if stage >= 1:
        for x, y in ((26, 40), (30, 38), (34, 41), (28, 36)):
            if (x + y + stage) % 2 == 0:
                c.px(x, y, P.GREEN_BASE)
    outline_multi(c, OUTLINE)
    return c


def draw_boss_down(settle=0):
    c = Canvas(W, H)
    dy = settle
    for x in range(10, 52):
        top = 50 + dy
        if 16 <= x <= 46:
            top = 47 + dy
        if 22 <= x <= 40:
            top = 45 + dy
        c.vline(x, top, FOOT - top, P.GOLD_BASE)
    # 줄무늬
    for sx in (16, 23, 30, 37, 43):
        c.rect(sx, 48 + dy, 2, 10 - dy, P.INK_DARK)
        c.rect(sx + 1, 49 + dy, 2, 9 - dy, P.INK_DARK)
    c.hline(18, 60, 26, P.PAPER_BRIGHT)   # 바닥쪽 흰 배
    # 뻗은 다리들
    c.rect(48, 58, 9, 4, P.GOLD_BASE)
    for k in range(3):
        c.px(57, 59 + k, P.PAPER_BRIGHT)
    c.rect(4, 58, 7, 3, P.GOLD_DEEP)
    # 늘어진 꼬리
    c.hline(2, 57 + dy, 10, P.GOLD_BASE)
    c.px(4, 57 + dy, P.INK_DARK); c.px(7, 57 + dy, P.INK_DARK)
    c.rect(1, 56 + dy, 3, 3, P.PAPER_BRIGHT)
    # 떨군 머리
    head(c, 44, 42 + dy, mouth=0, dead=True, glow=False)
    if settle:
        for x, y in ((16, 44), (28, 42), (40, 45), (22, 43)):
            c.px(x, y, P.INK_FAINT)
    outline_multi(c, OUTLINE)
    return c


def build():
    anims = {}
    anims["idle"] = [
        draw_boss(),
        draw_boss(body_dy=1, tail_tip=1),
        draw_boss(body_dy=1, tail_tip=2, glow=False),
        draw_boss(body_dy=0, tail_tip=1),
    ]
    anims["walk"] = [
        draw_boss(hf=0, hn=0, ff=3, fn=0, tail_tip=1),
        draw_boss(body_dy=-1, lift_fn=2, tail_tip=2),
        draw_boss(hf=3, hn=0, ff=0, fn=0, tail_tip=1),
        draw_boss(body_dy=-1, lift_hn=2, tail_tip=2),
    ]
    anims["telegraph"] = [
        draw_boss(body_dy=3, head_dy=2, head_dx=-2, front_pose="windup", tail_tip=3, glow=False),
        draw_boss(body_dy=4, head_dy=2, head_dx=-2, front_pose="windup", tail_tip=4, glow=True, mouth=1),
    ]
    anims["attack"] = [
        draw_boss(body_dy=2, front_pose="windup", mouth=1, tail_tip=3, glow=True),
        draw_boss(body_dy=-3, front_pose="swipe", mouth=1, head_dy=-1, tail_tip=2, glow=True),
        draw_boss(body_dy=0, front_pose="swipe", mouth=1, head_dx=1, glow=True),
    ]
    anims["heal"] = [draw_boss_lick(0), draw_boss_lick(1), draw_boss_lick(2)]
    anims["death"] = [
        draw_boss(body_dy=2, head_dy=2, mouth=1, tail_tip=-1, glow=False),
        draw_boss(body_dy=4, head_dy=4, hf=-2, ff=2, tail_tip=-2, glow=False),
        draw_boss(body_dy=6, head_dy=6, hf=-3, ff=3, mouth=0, tail_tip=-3, dead=True, glow=False),
        draw_boss_down(settle=0),
        draw_boss_down(settle=1),
        draw_boss_down(settle=2),
    ]
    return anims


MANIFEST = {
    "frame_w": 64, "frame_h": 64,
    "anims": {
        "idle": {"frames": 4, "fps": 4, "loop": True},
        "walk": {"frames": 4, "fps": 7, "loop": True},
        "telegraph": {"frames": 2, "fps": 5, "loop": False},
        "attack": {"frames": 3, "fps": 10, "loop": False},
        "heal": {"frames": 3, "fps": 5, "loop": False},
        "death": {"frames": 6, "fps": 6, "loop": False},
    },
}


def main():
    os.makedirs(FRAMES_DIR, exist_ok=True)
    anims = build()
    fw, fh = MANIFEST["frame_w"], MANIFEST["frame_h"]
    sheet_paths, saved = [], []
    for anim, frames in anims.items():
        spec = MANIFEST["anims"][anim]
        assert len(frames) == spec["frames"], \
            "%s 프레임 수 불일치: %d != %d" % (anim, len(frames), spec["frames"])
        s = strip(frames)
        assert s.w == spec["frames"] * fw and s.h == fh, \
            "%s 스트립 크기 오류: %dx%d" % (anim, s.w, s.h)
        path = os.path.join(BOSS_DIR, anim + ".png")
        s.save(path)
        saved.append(path)
        print("OK  %-24s %dx%d (%d frames)" % (os.path.relpath(path, ROOT), s.w, s.h, len(frames)))
        for i, f in enumerate(frames):
            fp = os.path.join(FRAMES_DIR, "boss_%s_%d.png" % (anim, i))
            f.save(fp, preview_scale=1)
            sheet_paths.append(fp)
        for k in range((-len(frames)) % 3):
            fp = os.path.join(FRAMES_DIR, "boss_%s_blank%d.png" % (anim, k))
            Canvas(fw, fh).save(fp, preview_scale=1)
            sheet_paths.append(fp)
    mp = os.path.join(BOSS_DIR, "manifest.json")
    with open(mp, "w", encoding="utf-8") as f:
        json.dump(MANIFEST, f, indent=2, ensure_ascii=False)
    saved.append(mp)
    print("OK  %s" % os.path.relpath(mp, ROOT))
    contact_sheet(sheet_paths, SHEET_PATH, scale=5, cols=3)
    print("OK  sheet -> %s" % os.path.relpath(SHEET_PATH, ROOT))
    return saved


if __name__ == "__main__":
    main()
