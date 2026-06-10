# -*- coding: utf-8 -*-
"""패럴랙스 배경 3레이어 — 수묵 산수 (640x360, 좌우 타일링).

레이어 (STYLE_BIBLE §1 팔레트 / §4 음영 / §6 시각 정체성):
  bg_far  — 먼 산 능선 2겹, INK_FAINT 단색. 위(뒤) 능선은 50% 디더로 옅게.
  bg_mid  — 중경 산 + 소나무 실루엣 INK_SOFT. 능선·안개는 디더(투명 혼합 금지).
  bg_near — 근경 둔덕 GRASS_DEEP→INK_MID 깊이 디더 + 갈대 실루엣.

타일링 보장: 모든 능선 함수는 주기 W(=640)의 사인/삼각 합성,
나무·갈대는 wpx()(x % W 래핑)로만 찍는다 → x=639 와 x=0 연속.
하늘은 전부 투명 — 게임 코드가 하늘색을 깐다.
"""
import sys, os, math, random, json
sys.path.insert(0, os.path.dirname(__file__))
import palette as P
from core import Canvas, contact_sheet
from PIL import Image

W, H = 640, 360
TAU = math.tau
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(ROOT, "assets", "sprites", "bg")
SHOTS = os.path.join(ROOT, "shots")


# ── 래핑 프리미티브 (타일링 핵심) ────────────────────────────
def wpx(c, x, y, col):
    c.px(x % W, y, col)


def whline(c, x, y, w, col):
    for i in range(w):
        wpx(c, x + i, y, col)


# ── 주기 능선 함수 (k 는 정수 → 주기 W 보장) ─────────────────
def sines(x, base, comps):
    """comps: [(amp, k, phase), ...] — base + 사인 합."""
    y = base
    for amp, k, ph in comps:
        y += amp * math.sin(TAU * k * x / W + ph)
    return y


def peaks(x, amp, k, ph):
    """뾰족 봉우리 — |sin| 골을 위로 뒤집은 첨두. 반환값은 0..-amp (위로)."""
    s = math.sin(TAU * k * x / W + ph)
    return -amp * (1.0 - abs(s))


def ridge_far_back(x):
    return sines(x, 168, [(7, 3, 2.0), (3, 8, 4.0)]) + peaks(x, 22, 1, 0.9)


def ridge_far_front(x):
    return sines(x, 215, [(8, 4, 1.2), (4, 9, 3.3), (3, 15, 5.0)]) + peaks(x, 26, 2, 2.6)


def ridge_mid(x):
    return sines(x, 262, [(9, 5, 0.5), (5, 11, 2.8)]) + peaks(x, 30, 2, 4.4)


def mound_near(x):
    return sines(x, 316, [(10, 3, 1.8), (5, 7, 4.7), (2, 13, 0.3)])


# ── ① bg_far — 먼 산 2겹 ─────────────────────────────────────
def gen_far() -> Canvas:
    c = Canvas(W, H)
    # 뒤 능선: 능선 2px 만 실선, 몸체는 50% 체커 디더 → 옅게 읽힘
    for x in range(W):
        y0 = int(round(ridge_far_back(x)))
        c.px(x, y0, P.INK_FAINT)
        c.px(x, y0 + 1, P.INK_FAINT)
        for y in range(y0 + 2, H):
            if (x + y) % 2 == 0:
                c.px(x, y, P.INK_FAINT)
    # 앞 능선: INK_FAINT 단색 실루엣 (수묵 윤곽 — 디테일 없음)
    for x in range(W):
        y1 = int(round(ridge_far_front(x)))
        for y in range(y1, H):
            c.px(x, y, P.INK_FAINT)
    return c


# ── ② bg_mid — 중경 산 + 소나무 + 안개 디더 ──────────────────
def _pad(c, cx, cy, w, col):
    """소나무 가지층 — 납작하고 위가 평평한 솔잎 덩어리."""
    half = w // 2
    whline(c, cx - half + 1, cy - 1, w - 2, col)
    whline(c, cx - half, cy, w, col)
    whline(c, cx - half + 2, cy + 1, max(2, w - 5), col)


def _pine(c, rnd, x, ground_y, h):
    """굽은 줄기 + 수평 솔잎층 — 한국 소나무 실루엣."""
    col = P.INK_SOFT
    lean = rnd.choice([-1, 1]) * rnd.uniform(0.10, 0.22)
    txs = []
    for i in range(h + 1):
        wob = 1 if (i > h * 0.55 and (i // 3) % 2 == 0) else 0
        tx = int(round(x + lean * i)) + (wob if lean > 0 else -wob)
        txs.append(tx)
    for i, tx in enumerate(txs):
        y = ground_y - i
        wpx(c, tx, y, col)
        if i <= h // 3:                       # 밑동은 2px
            wpx(c, tx + 1, y, col)
    top_x, top_y = txs[-1], ground_y - h
    side = 1 if lean > 0 else -1
    _pad(c, top_x, top_y + 1, rnd.randint(7, 9), col)                          # 우듬지
    _pad(c, top_x + side * rnd.randint(3, 5), top_y + rnd.randint(4, 6),
         rnd.randint(9, 12), col)                                              # 본가지
    if h >= 18:
        _pad(c, top_x - side * rnd.randint(2, 4), top_y + rnd.randint(8, 10),
             rnd.randint(8, 11), col)                                          # 곁가지


def gen_mid(rnd) -> Canvas:
    c = Canvas(W, H)
    ridge = [int(round(ridge_mid(x))) for x in range(W)]
    for x in range(W):
        y0 = ridge[x]
        # 능선 안개 디더 — 위로 갈수록 성기게 (25% → 50% → 75% → 실선)
        if (x + 2 * (y0 - 1)) % 4 == 0:
            c.px(x, y0 - 1, P.INK_SOFT)
        for y in (y0, y0 + 1):
            if (x + y) % 2 == 0:
                c.px(x, y, P.INK_SOFT)
        for y in (y0 + 2, y0 + 3):
            if (x + 2 * y) % 4 != 0:
                c.px(x, y, P.INK_SOFT)
        for y in range(y0 + 4, H):
            c.px(x, y, P.INK_SOFT)
    # 소나무 — 군락 2곳 + 독립수 (실루엣만, 능선 위에서 하늘에 걸림)
    for tx, th in [(40, 22), (120, 18), (148, 24), (310, 20), (342, 26),
                   (470, 16), (552, 23), (588, 18)]:
        _pine(c, rnd, tx, ridge[tx % W] + 3, th)
    # 산허리 안개띠 — 투명으로 '지우는' 디더 (알파 혼합 없이 뒤 레이어가 비침)
    for x in range(W):
        yf = int(round(288 + 6 * math.sin(TAU * 2 * x / W + 1.3)
                       + 3 * math.sin(TAU * 5 * x / W + 4.0)))
        for dy in range(-7, 8):
            y = yf + dy
            ad = abs(dy)
            if ad <= 2:
                if (x + 2 * y) % 4 != 0:                 # 중심 75% 지움
                    c.px(x, y, P.TRANSPARENT)
            elif ad <= 5:
                if (x + y) % 2 == 0:                     # 50%
                    c.px(x, y, P.TRANSPARENT)
            else:
                if (x + 2 * y) % 4 == 0:                 # 가장자리 25%
                    c.px(x, y, P.TRANSPARENT)
    return c


# ── ③ bg_near — 근경 둔덕 + 갈대 ─────────────────────────────
def _reed(c, rnd, x, ground_y, h, lean, col):
    """1px 줄기(끝으로 갈수록 휨) + 처진 이삭."""
    pts = []
    for i in range(h + 1):
        dx = int(round(lean * (i / h) ** 2))
        pts.append((x + dx, ground_y - i))
    for px_, py_ in pts:
        wpx(c, px_, py_, col)
    hx, hy = pts[-1]
    d = 1 if lean >= 0 else -1
    wpx(c, hx + d, hy, col)
    wpx(c, hx + d, hy + 1, col)
    wpx(c, hx + 2 * d, hy + 1, col)
    wpx(c, hx, hy - 1, col)


def gen_near(rnd) -> Canvas:
    c = Canvas(W, H)
    mound = [int(round(mound_near(x))) for x in range(W)]
    for x in range(W):
        y0 = mound[x]
        if (x + y0 - 1) % 2 == 0:                        # 윗단 풀 디더
            c.px(x, y0 - 1, P.GRASS_DEEP)
        for y in range(y0, H):
            d = y - y0
            if d < 9:
                col = P.GRASS_DEEP
            elif d < 13:                                  # 50% 전이
                col = P.INK_MID if (x + y) % 2 == 0 else P.GRASS_DEEP
            elif d < 18:                                  # 75% 전이
                col = P.INK_MID if (x + 2 * y) % 4 != 0 else P.GRASS_DEEP
            else:
                col = P.INK_MID
            c.px(x, y, col)
    # 능선 위 풀잎 1~2px
    for x in range(W):
        if rnd.random() < 0.10:
            hgt = rnd.randint(1, 2)
            col = P.GRASS_DEEP if rnd.random() < 0.8 else P.INK_MID
            for k in range(hgt):
                c.px(x, mound[x] - 1 - k, col)
    # 갈대 군락 — 뒤(GRASS_DEEP) 먼저, 앞(INK_MID) 나중
    clusters = [(55, 9), (175, 8), (298, 11), (422, 7), (540, 10)]
    lone = [(120, 1), (250, 2), (480, 1)]
    for cx0, n in clusters + lone:
        wind = rnd.choice([2, 2, 3])                      # 바람은 오른쪽으로
        backs, fronts = [], []
        for _ in range(n):
            rx = cx0 + rnd.randint(-22, 22)
            rh = rnd.randint(12, 26)
            rl = wind + rnd.choice([-1, 0, 0, 1])
            (backs if rnd.random() < 0.35 else fronts).append((rx, rh, rl))
        for rx, rh, rl in backs:
            _reed(c, rnd, rx, mound[rx % W] + 2, rh, rl, P.GRASS_DEEP)
        for rx, rh, rl in fronts:
            _reed(c, rnd, rx, mound[rx % W] + 2, rh, rl, P.INK_MID)
    return c


# ── 검수용 합성/이음매 샷 (에셋 아님 — shots/) ────────────────
def _hshift(img, s):
    out = Image.new("RGBA", img.size)
    out.paste(img.crop((s, 0, W, H)), (0, 0))
    out.paste(img.crop((0, 0, s, H)), (W - s, 0))
    return out


def composite_shot(layers, path, shift=0, scale=2):
    sky = Image.new("RGBA", (W, H), P.PAPER_BRIGHT)      # 미리보기용 하늘
    for ly in layers:
        sky.alpha_composite(_hshift(ly.img, shift) if shift else ly.img)
    big = sky.resize((W * scale, H * scale), Image.NEAREST)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    big.save(path)
    return path


def main():
    rnd = random.Random(46)
    far, mid, near = gen_far(), gen_mid(rnd), gen_near(rnd)

    paths = []
    for name, cv in (("bg_far", far), ("bg_mid", mid), ("bg_near", near)):
        p = os.path.join(OUT_DIR, name + ".png")
        cv.save(p, preview_scale=2)                       # 팔레트 위반 시 예외
        paths.append(p)
        print("saved:", p)

    # manifest — frames * frame_w == PNG 폭 검증
    manifest = {
        "frame_w": W, "frame_h": H,
        "anims": {
            "bg_far":  {"frames": 1, "fps": 0, "loop": False},
            "bg_mid":  {"frames": 1, "fps": 0, "loop": False},
            "bg_near": {"frames": 1, "fps": 0, "loop": False},
        },
        "parallax": {
            "bg_far":  {"file": "bg_far.png",  "scroll_factor": 0.10, "tile_x": True,
                        "desc": "먼 산 2겹 INK_FAINT — 뒤 능선은 50% 디더로 옅게. 하늘 투명"},
            "bg_mid":  {"file": "bg_mid.png",  "scroll_factor": 0.35, "tile_x": True,
                        "desc": "중경 산+소나무 INK_SOFT — 능선/산허리 안개 디더"},
            "bg_near": {"file": "bg_near.png", "scroll_factor": 0.70, "tile_x": True,
                        "desc": "근경 둔덕 GRASS_DEEP→INK_MID + 갈대 실루엣"},
        },
    }
    for name in ("bg_far", "bg_mid", "bg_near"):
        img = Image.open(os.path.join(OUT_DIR, name + ".png"))
        a = manifest["anims"][name]
        assert img.width == a["frames"] * manifest["frame_w"], name + " 폭 불일치"
        assert img.height == manifest["frame_h"], name + " 높이 불일치"
    mp = os.path.join(OUT_DIR, "manifest.json")
    with open(mp, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    print("saved:", mp)

    # 검수 샷: 합성(정위치) + 이음매 확인(320px 시프트 → 원래 경계가 화면 중앙)
    print("saved:", composite_shot([far, mid, near],
                                   os.path.join(SHOTS, "bg_composite.png")))
    print("saved:", composite_shot([far, mid, near],
                                   os.path.join(SHOTS, "bg_seam_check.png"), shift=320))

    # 콘택트 시트 (640x360 3장 — scale 6 은 23MP 라 검수 불가능, 2로)
    sheet = contact_sheet(paths, os.path.join(SHOTS, "sheets", "background_sheet.png"),
                          scale=2, cols=1)
    print("saved:", sheet)


if __name__ == "__main__":
    main()
