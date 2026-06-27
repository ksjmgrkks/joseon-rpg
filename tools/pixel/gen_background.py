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


def ridge_far_farthest(x):
    # 최원경 능선 — 가장 높고 옅게(25% 디더). 깊이감용.
    return sines(x, 150, [(5, 2, 0.4), (3, 6, 2.2)]) + peaks(x, 16, 1, 1.7)


def ridge_far_back(x):
    return sines(x, 168, [(7, 3, 2.0), (3, 8, 4.0)]) + peaks(x, 22, 1, 0.9)


def ridge_far_front(x):
    return sines(x, 215, [(8, 4, 1.2), (4, 9, 3.3), (3, 15, 5.0)]) + peaks(x, 26, 2, 2.6)


def ridge_mid(x):
    return sines(x, 262, [(9, 5, 0.5), (5, 11, 2.8)]) + peaks(x, 30, 2, 4.4)


def mound_near(x):
    return sines(x, 316, [(10, 3, 1.8), (5, 7, 4.7), (2, 13, 0.3)])


def _moon(c, cx, cy, r):
    """보름달 — 한지빛 원반 + 옅은 무리(halo). 능선보다 위(하늘)."""
    for y in range(cy - r - 3, cy + r + 4):
        for x in range(cx - r - 3, cx + r + 4):
            d2 = (x - cx) ** 2 + (y - cy) ** 2
            if d2 <= r * r:
                c.px(x % W, y, P.PAPER_BRIGHT)
            elif d2 <= (r + 1) * (r + 1):
                c.px(x % W, y, P.PAPER_DEEP)            # 달 가장자리
            elif d2 <= (r + 3) * (r + 3) and (x + y) % 2 == 0:
                c.px(x % W, y, P.INK_FAINT)             # 옅은 무리(디더)


def _cloud_band(c, base_y, amp, k, ph, col, thick=3):
    """동양화 구름띠 — 가로로 길게 흐르는 디더 띠 (주기 W 라 타일링)."""
    for x in range(W):
        cy = int(round(base_y + amp * math.sin(TAU * k * x / W + ph)))
        for dy in range(thick):
            if (x + 2 * dy) % 3 != 0:                   # 성긴 디더 → 안개구름 느낌
                c.px(x, cy + dy, col)


def _bird(c, x, y, col):
    """먼 하늘 갈매기형 새 1마리 — 가운데가 낮고 날개가 살짝 올라간 V 실루엣.
    x 는 wpx 로 래핑 → 좌우 이음매 안전."""
    for dx, dy in ((0, 0), (-1, -1), (-2, -1), (-3, -2), (1, -1), (2, -1), (3, -2)):
        wpx(c, x + dx, y + dy, col)


def gen_far() -> Canvas:
    c = Canvas(W, H)
    # 보름달 — 좌상단 하늘 (능선 위)
    _moon(c, 150, 70, 26)
    # 구름띠 3겹 — 위(옅게)·달 주변·중턱
    _cloud_band(c, 88, 5, 4, 1.8, P.PAPER_DEEP, thick=2)
    _cloud_band(c, 110, 6, 2, 0.6, P.PAPER_DEEP, thick=2)
    _cloud_band(c, 150, 8, 3, 3.1, P.INK_FAINT, thick=2)
    # 최원경 능선 — 가장 옅게(25% 디더)부터 그려 뒤로 깔린다(깊이감).
    for x in range(W):
        yb = int(round(ridge_far_farthest(x)))
        for y in range(yb, H):
            if (x + y) % 4 == 0:
                c.px(x, y, P.INK_FAINT)
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
    # 먼 하늘 새 떼 — 수묵 갈매기 실루엣(옅게). 달 부근에 느슨한 한 무리 + 우측 둘.
    for bx, by in ((96, 52), (114, 46), (132, 56), (152, 43), (172, 50),
                   (322, 60), (342, 53)):
        _bird(c, bx, by, P.INK_FAINT)
    return c


# ── ② bg_mid — 중경 산 + 소나무 + 안개 디더 ──────────────────
def _pine(c, rnd, x, ground_y, h):
    """굽은 줄기 + 우산형 솔잎 크라운 — 한국 소나무 실루엣.
    크라운(덩어리)이 나무 높이의 절반을 차지하고 위가 가장 넓다(우산형)."""
    col = P.INK_SOFT
    lean = rnd.choice([-1, 1]) * rnd.uniform(0.08, 0.18)
    txs = [int(round(x + lean * i + 0.7 * math.sin(i * math.pi / max(8, h))))
           for i in range(h + 1)]
    for i, tx in enumerate(txs):
        y = ground_y - i
        wpx(c, tx, y, col)
        if i <= h * 0.5:                      # 밑동~중단은 2px
            wpx(c, tx + 1, y, col)
    top_x, top_y = txs[-1], ground_y - h
    side = 1 if lean > 0 else -1
    w = max(12, int(h * 0.85)) + rnd.randint(-1, 2)
    # 본 크라운 — 5단 덩어리, 둘째 단이 가장 넓은 납작 우산
    for dy, ww in ((0, w - 5), (1, w), (2, w - 1), (3, w - 4), (4, w - 8)):
        off = rnd.randint(-1, 1)
        whline(c, top_x - ww // 2 + off, top_y + dy, ww, col)
    # 곁가지층 — 크라운 바로 아래 좌우 엇갈림 (실루엣이 한 덩어리로 이어짐)
    bw = max(6, w // 2 + 1)
    whline(c, top_x + side * (w // 3) - bw // 2, top_y + 6, bw, col)
    whline(c, top_x + side * (w // 3) - bw // 2 + 1, top_y + 7, bw - 3, col)
    if h >= 16:
        bw2 = max(5, w // 2 - 1)
        whline(c, top_x - side * (w // 3) - bw2 // 2, top_y + 9, bw2, col)


def _peak_spots(ridge, n=5, min_gap=70):
    """능선 배열에서 서로 떨어진 봉우리(작은 y) 후보 x 를 고른다 — 래핑 거리."""
    order = sorted(range(W), key=lambda x: ridge[x])
    chosen = []
    for x in order:
        if all(min(abs(x - c0), W - abs(x - c0)) >= min_gap for c0 in chosen):
            chosen.append(x)
        if len(chosen) >= n:
            break
    return chosen


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
    # 소나무 — 봉우리마다 큰 나무 + 곁나무 (능선 위 하늘에 실루엣이 걸리도록)
    for px_ in _peak_spots(ridge, n=6, min_gap=70):
        big_h = rnd.randint(17, 22)
        _pine(c, rnd, px_, ridge[px_] + 3, big_h)
        if rnd.random() < 0.75:               # 곁나무 (작게, 옆에)
            ox = px_ + rnd.choice([-1, 1]) * rnd.randint(11, 16)
            _pine(c, rnd, ox, ridge[ox % W] + 3, rnd.randint(11, 14))
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


def _rock(c, x, base_y, w, col):
    """둔덕 위 납작한 돌 — 둥근 윗면(가운데가 높음). 주기 W 래핑."""
    for dx in range(-w, w + 1):
        h = int((w - abs(dx)) * 0.6)
        for dy in range(0, h + 1):
            wpx(c, x + dx, base_y - dy, col)


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
    # 근경 돌 몇 개 — 둔덕 위 먹빛 납작돌(풀·갈대가 앞에 겹치도록 먼저).
    for rx, rw in ((95, 6), (210, 5), (355, 7), (470, 4), (560, 6)):
        _rock(c, rx, mound[rx % W] + 2, rw, P.INK_MID)
    # 능선 위 풀잎 1~3px (밀도 약간 상향)
    for x in range(W):
        if rnd.random() < 0.14:
            hgt = rnd.randint(1, 3)
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
                        "desc": "먼 산 3겹 INK_FAINT(최원경 25%·뒤 50% 디더) + 구름 3겹 + 새 떼. 하늘 투명"},
            "bg_mid":  {"file": "bg_mid.png",  "scroll_factor": 0.35, "tile_x": True,
                        "desc": "중경 산+소나무 INK_SOFT — 능선/산허리 안개 디더"},
            "bg_near": {"file": "bg_near.png", "scroll_factor": 0.70, "tile_x": True,
                        "desc": "근경 둔덕 GRASS_DEEP→INK_MID + 갈대 + 납작돌 + 풀잎"},
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
