# -*- coding: utf-8 -*-
"""마을 NPC 4종 — idle 2프레임 (호흡 1px), 32x64.

① elder      어르신   : 갓 + 한지 도포 + 흰 수염(PAPER_BRIGHT) + 지팡이
② blacksmith 대장장이 : 머리수건(BLUE_DEEP) + 소매 걷은 저고리 + 가죽 앞치마(WOOD_DEEP) + 망치
③ woman      아낙     : 저고리 PAPER_BRIGHT + 통치마 BLUE_BASE + 쪽진 머리
④ wanderer   떠돌이상인: 패랭이(짚색 GOLD) + 등 봇짐(WOOD_BASE 큰 보따리) + 회청 INK_FAINT 옷

규격(AGENT_GUIDE §1): 캔버스 32x64, 발바닥 y=62, 중심축 x=16, 오른쪽 보기,
외곽선은 베이스보다 진한 짝색(검정 단색 금지), 광원 좌상단.
호흡: 프레임1 = 허리 위(머리·상체·소품)만 1px 아래로. 발·치마·지팡이는 고정.
"""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
import palette as P
from core import Canvas, strip, contact_sheet

W, H = 32, 64
CX = 16
FOOT = 62
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def _feet(c, front_hl=True):
    """짚신/가죽신 — 모든 프레임 고정 (y 59..61)."""
    c.rect(CX - 5, 59, 4, 3, P.WOOD_DEEP)
    c.rect(CX + 1, 59, 5, 3, P.WOOD_DEEP)
    if front_hl:
        c.px(CX + 5, 59, P.WOOD_BASE)


def _face(c, b, hx=CX, hair=True):
    """공통 얼굴 (y 16+b..25+b) — 모자 챙(y15)에 바로 닿는 높이."""
    c.rect(hx - 4, 16 + b, 8, 10, P.SKIN_BASE)
    c.rect(hx + 2, 17 + b, 2, 9, P.SKIN_SHADE)        # 뒤통수쪽 음영
    c.px(hx - 4, 16 + b, P.TRANSPARENT); c.px(hx + 3, 16 + b, P.TRANSPARENT)
    c.px(hx + 1, 20 + b, P.INK_DEEPEST)               # 눈
    c.px(hx + 3, 22 + b, P.SKIN_DEEP)                 # 코점
    if hair:
        c.rect(hx - 4, 17 + b, 2, 5, P.INK_DARK)      # 귀밑 머리칼


# ──────────────────────────────────────────────────────────────
# ① 어르신 — 갓 + 도포 + 흰 수염 + 지팡이 (앞쪽에 짚음)
# ──────────────────────────────────────────────────────────────
def elder(b: int) -> Canvas:
    c = Canvas(W, H)
    hx = CX + 1            # 살짝 앞으로 숙인 머리 (두 프레임 동일 — 축 고정)

    # 도포 자락 (고정, y 43..58)
    for i, y in enumerate(range(43, 59)):
        half = 5 + i // 4
        c.hline(CX - half, y, half * 2, P.PAPER_BASE)
        c.rect(CX + half - 2, y, 2, 1, P.PAPER_SHADE)
    c.dither(CX - 2, 48, 2, 10, P.PAPER_SHADE)
    c.hline(CX - 8, 58, 16, P.PAPER_SHADE)
    _feet(c)

    # 지팡이 (고정 — 땅에 짚음, y 33..61) + 손잡이 옹이
    c.vline(CX + 8, 33, 29, P.WOOD_DEEP)
    c.px(CX + 8, 33, P.WOOD_BASE)                      # 손잡이 머리
    c.px(CX + 7, 34, P.WOOD_BASE)

    # 상체 도포 (y 28+b..42 — 아랫단은 자락에 물림)
    c.rect(CX - 6, 28 + b, 12, 15 - b, P.PAPER_BASE)
    c.px(CX - 6, 28 + b, P.TRANSPARENT); c.px(CX + 5, 28 + b, P.TRANSPARENT)
    c.rect(CX + 3, 29 + b, 3, 13 - b, P.PAPER_SHADE)
    c.px(CX - 5, 27 + b, P.PAPER_BASE)                 # 굽은 등
    c.hline(CX - 6, 38 + b, 12, P.INK_FAINT)           # 세조대(허리끈)

    # 앞팔 — 지팡이를 짚은 손
    c.rect(CX + 4, 30 + b, 3, 6, P.PAPER_BASE)
    c.rect(CX + 5, 31 + b, 2, 5, P.PAPER_SHADE)
    c.rect(CX + 7, 36 + b, 2, 2, P.SKIN_BASE)          # 손 (지팡이 위)
    c.rect(CX - 6, 30 + b, 2, 7, P.PAPER_SHADE)        # 뒷팔 음영

    c.rect(hx - 1, 26 + b, 3, 2, P.SKIN_SHADE)         # 목
    _face(c, b, hx=hx, hair=False)
    c.rect(hx - 4, 18 + b, 2, 5, P.INK_FAINT)          # 흰 구레나룻(잿빛)
    c.hline(hx, 19 + b, 3, P.PAPER_BRIGHT)             # 흰 눈썹

    # 흰 수염 — 턱에서 가슴까지 점점 좁게
    c.rect(hx - 2, 23 + b, 6, 2, P.PAPER_BRIGHT)
    c.rect(hx - 1, 25 + b, 4, 3, P.PAPER_BRIGHT)
    c.rect(hx, 28 + b, 2, 3, P.PAPER_BRIGHT)
    c.px(hx, 31 + b, P.PAPER_BRIGHT)
    c.vline(hx + 2, 25 + b, 3, P.PAPER_SHADE)          # 수염 우측 음영
    c.px(hx + 1, 28 + b, P.PAPER_SHADE)

    # 갓 (y 7+b..15+b) — 넓은 챙 + 모정
    c.hline(hx - 8, 14 + b, 17, P.INK_DEEPEST)
    c.hline(hx - 7, 15 + b, 15, P.INK_DARK)
    c.rect(hx - 4, 8 + b, 9, 6, P.INK_DARK)
    c.hline(hx - 3, 7 + b, 7, P.INK_DARK)
    c.hline(hx - 3, 8 + b, 7, P.INK_DEEPEST)
    c.px(hx - 4, 8 + b, P.TRANSPARENT); c.px(hx + 4, 8 + b, P.TRANSPARENT)
    c.px(hx - 8, 14 + b, P.INK_MID); c.px(hx + 8, 14 + b, P.INK_MID)

    c.outline(P.INK_SOFT, only_color=P.PAPER_BASE)
    return c


# ──────────────────────────────────────────────────────────────
# ② 대장장이 — 머리수건 + 걷은 소매 + 가죽 앞치마 + 망치
# ──────────────────────────────────────────────────────────────
def blacksmith(b: int) -> Canvas:
    c = Canvas(W, H)

    # 바지 (고정, y 44..58) — 통 넓은 잠방이 + 가랑이
    c.rect(CX - 5, 44, 11, 9, P.INK_FAINT)
    c.rect(CX - 5, 53, 4, 6, P.INK_FAINT)
    c.rect(CX + 1, 53, 4, 6, P.INK_FAINT)
    c.vline(CX + 4, 44, 9, P.INK_SOFT)
    c.vline(CX + 3, 53, 6, P.INK_SOFT)
    c.vline(CX - 2, 53, 6, P.INK_SOFT)
    c.hline(CX - 5, 57, 4, P.INK_SOFT)                 # 발목 대님
    c.hline(CX + 1, 57, 4, P.INK_SOFT)
    _feet(c, front_hl=False)

    # 상체 저고리 — 어깨 넓음 (14px)
    c.rect(CX - 7, 28 + b, 14, 16 - b, P.PAPER_SHADE)
    c.px(CX - 7, 28 + b, P.TRANSPARENT); c.px(CX + 6, 28 + b, P.TRANSPARENT)
    c.rect(CX + 4, 29 + b, 3, 15 - b, P.PAPER_DEEP)
    c.rect(CX - 7, 30 + b, 2, 6, P.PAPER_DEEP)         # 뒷팔 음영

    # 가죽 앞치마 (가슴~허벅지)
    c.rect(CX - 3, 31 + b, 8, 18, P.WOOD_DEEP)
    c.vline(CX - 3, 31 + b, 18, P.WOOD_BASE)           # 좌측(광원) 하이라이트
    c.hline(CX - 2, 40 + b, 6, P.INK_MID)              # 재봉선
    c.px(CX, 29 + b, P.WOOD_DEEP); c.px(CX + 1, 30 + b, P.WOOD_DEEP)  # 목끈

    # 앞팔 — 소매 걷어 맨 팔뚝, 주먹
    c.rect(CX + 5, 29 + b, 3, 5, P.PAPER_SHADE)        # 걷은 소매
    c.hline(CX + 5, 33 + b, 3, P.PAPER_DEEP)           # 소매 접단
    c.rect(CX + 6, 34 + b, 2, 4, P.SKIN_BASE)          # 팔뚝
    c.vline(CX + 7, 34 + b, 4, P.SKIN_SHADE)
    c.rect(CX + 6, 38 + b, 2, 2, P.SKIN_SHADE)         # 주먹

    # 망치 — 주먹에서 늘어뜨림 (머리는 다리 옆 바깥)
    c.vline(CX + 7, 40 + b, 8, P.WOOD_BASE)
    c.px(CX + 7, 42 + b, P.WOOD_DEEP)
    c.rect(CX + 5, 48 + b, 6, 3, P.INK_MID)            # 망치 머리
    c.hline(CX + 5, 50 + b, 6, P.INK_DARK)
    c.px(CX + 5, 48 + b, P.INK_FAINT)                  # 쇠 하이라이트

    c.rect(CX - 1, 26 + b, 4, 2, P.SKIN_SHADE)         # 굵은 목
    _face(c, b)
    c.hline(CX, 24 + b, 3, P.SKIN_DEEP)                # 수염 자국

    # 머리수건 (BLUE_DEEP, y 14..17) + 뒤 매듭
    c.rect(CX - 4, 14 + b, 9, 4, P.BLUE_DEEP)
    c.px(CX - 4, 14 + b, P.TRANSPARENT); c.px(CX + 4, 14 + b, P.TRANSPARENT)
    c.hline(CX - 3, 15 + b, 6, P.BLUE_BASE)            # 수건 결
    c.px(CX - 5, 15 + b, P.BLUE_DEEP)
    c.px(CX - 6, 16 + b, P.BLUE_DEEP)
    c.px(CX - 5, 17 + b, P.BLUE_BASE)

    c.outline(P.INK_SOFT, only_color=P.PAPER_SHADE)
    return c


# ──────────────────────────────────────────────────────────────
# ③ 아낙 — 쪽진 머리 + 저고리(PAPER_BRIGHT) + 통치마(BLUE_BASE)
# ──────────────────────────────────────────────────────────────
def woman(b: int) -> Canvas:
    c = Canvas(W, H)

    # 통치마 (고정, y 33..58) — 가슴 높이에서 풍성하게 퍼짐
    for i, y in enumerate(range(33, 59)):
        half = min(4 + i // 3, 9)
        c.hline(CX - half, y, half * 2, P.BLUE_BASE)
        c.rect(CX + half - 2, y, 2, 1, P.BLUE_DEEP)    # 우측 음영
    c.dither(CX - 2, 44, 1, 13, P.BLUE_DEEP)           # 주름 한 줄만 (절제)
    c.dither(CX + 2, 48, 1, 9, P.BLUE_DEEP, parity=1)
    c.hline(CX - 9, 58, 18, P.BLUE_DEEP)               # 밑단
    c.rect(CX + 2, 59, 4, 3, P.PAPER_BRIGHT)           # 신발코(고무신)만 빼꼼
    c.px(CX + 5, 61, P.PAPER_SHADE)

    # 저고리 (y 27+b..34 — 짧은 상의, 치마 위에 겹침)
    c.rect(CX - 5, 27 + b, 11, 8 - b, P.PAPER_BRIGHT)
    c.px(CX - 5, 27 + b, P.TRANSPARENT); c.px(CX + 5, 27 + b, P.TRANSPARENT)
    c.vline(CX - 5, 29 + b, 5, P.PAPER_SHADE)          # 뒷팔 음영
    c.line(CX, 27 + b, CX + 3, 31 + b, P.INK_SOFT)     # 깃/섶선
    # 고름 (붉은 리본)
    c.vline(CX + 1, 31 + b, 5, P.RED_BASE)
    c.px(CX + 2, 32 + b, P.RED_DEEP)
    # 앞 소매 — 손을 앞으로 모음
    c.rect(CX + 3, 28 + b, 3, 6, P.PAPER_BRIGHT)
    c.rect(CX + 4, 29 + b, 2, 5, P.PAPER_SHADE)
    c.rect(CX + 4, 34 + b, 2, 2, P.SKIN_BASE)          # 손

    c.rect(CX - 1, 25 + b, 3, 2, P.SKIN_SHADE)         # 목

    # 얼굴 (y 16+b..24 — 갸름)
    c.rect(CX - 3, 16 + b, 7, 9, P.SKIN_BASE)
    c.rect(CX + 2, 17 + b, 2, 7, P.SKIN_SHADE)
    c.px(CX - 3, 16 + b, P.TRANSPARENT); c.px(CX + 3, 16 + b, P.TRANSPARENT)
    c.px(CX + 1, 19 + b, P.INK_DEEPEST)                # 눈
    c.px(CX - 2, 18 + b, P.SKIN_LIGHT)                 # 볼 하이라이트
    c.px(CX + 2, 22 + b, P.RED_DEEP)                   # 입술 (코점 생략 — 갸름하게)

    # 쪽진 머리 (가르마 정수리 + 뒤통수 + 쪽 + 비녀)
    c.rect(CX - 4, 14 + b, 9, 3, P.INK_DARK)
    c.px(CX - 4, 14 + b, P.TRANSPARENT); c.px(CX + 4, 14 + b, P.TRANSPARENT)
    c.rect(CX - 5, 15 + b, 2, 8, P.INK_DARK)           # 뒷머리
    c.px(CX, 15 + b, P.INK_MID)                        # 머릿결 윤기
    c.rect(CX - 7, 20 + b, 3, 3, P.INK_DARK)           # 쪽(낭자) — 목덜미 높이
    c.px(CX - 7, 20 + b, P.TRANSPARENT)
    c.hline(CX - 9, 21 + b, 3, P.GOLD_BASE)            # 비녀

    c.outline(P.INK_SOFT, only_color=P.PAPER_BRIGHT)
    return c


# ──────────────────────────────────────────────────────────────
# ④ 떠돌이 상인 — 패랭이 + 등 봇짐(실루엣 핵심) + 회청 옷 + 지팡이
# ──────────────────────────────────────────────────────────────
def wanderer(b: int) -> Canvas:
    c = Canvas(W, H)

    # 봇짐 (등 뒤 — 몸보다 먼저 그려 뒤로 깔림, 호흡 따라 +b)
    c.disc(8, 30 + b, 5, P.WOOD_DEEP)                  # 외곽 음영
    c.disc(7, 29 + b, 4, P.WOOD_BASE)                  # 밝은 면
    c.rect(7, 23 + b, 3, 2, P.WOOD_DEEP)               # 윗매듭
    c.px(8, 22 + b, P.WOOD_DEEP)

    # 바지 (고정, y 43..58) + 행전
    c.rect(CX - 5, 43, 10, 8, P.INK_FAINT)
    c.rect(CX - 5, 51, 3, 8, P.INK_FAINT)
    c.rect(CX + 1, 51, 3, 8, P.INK_FAINT)
    c.vline(CX + 3, 43, 8, P.INK_SOFT)
    c.rect(CX - 5, 54, 3, 5, P.PAPER_SHADE)            # 행전(각반)
    c.rect(CX + 1, 54, 3, 5, P.PAPER_SHADE)
    _feet(c, front_hl=False)

    # 지팡이 (고정, 어깨 위까지 — y 28..61)
    c.vline(CX + 8, 28, 34, P.WOOD_DEEP)
    c.px(CX + 8, 29, P.WOOD_BASE)

    # 상체 (회청 INK_FAINT, y 28+b..42)
    c.rect(CX - 6, 28 + b, 12, 15 - b, P.INK_FAINT)
    c.px(CX - 6, 28 + b, P.TRANSPARENT); c.px(CX + 5, 28 + b, P.TRANSPARENT)
    c.rect(CX + 3, 29 + b, 3, 13 - b, P.INK_SOFT)
    # 봇짐 멜빵 — 왼어깨→오른허리 사선
    c.line(CX - 4, 29 + b, CX + 3, 38 + b, P.PAPER_DEEP)
    c.line(CX - 5, 30 + b, CX + 2, 39 + b, P.PAPER_DEEP)
    c.hline(CX - 6, 40 + b, 12, P.INK_SOFT)            # 허리끈

    # 앞팔 — 지팡이 잡음
    c.rect(CX + 4, 29 + b, 3, 6, P.INK_FAINT)
    c.rect(CX + 5, 30 + b, 2, 5, P.INK_SOFT)
    c.rect(CX + 7, 34 + b, 2, 2, P.SKIN_BASE)          # 손 (지팡이 위)

    c.rect(CX - 1, 26 + b, 3, 2, P.SKIN_SHADE)         # 목
    _face(c, b)

    # 패랭이 (짚색 — 챙 y 13, 둥근 모정 y 9..12)
    c.hline(CX - 8, 13 + b, 17, P.GOLD_BASE)
    c.hline(CX - 7, 14 + b, 15, P.GOLD_DEEP)
    c.rect(CX - 3, 9 + b, 7, 4, P.GOLD_BASE)
    c.px(CX - 3, 9 + b, P.TRANSPARENT); c.px(CX + 3, 9 + b, P.TRANSPARENT)
    c.dither(CX - 2, 10 + b, 5, 3, P.GOLD_DEEP)        # 대오리 결
    c.px(CX + 3, 15 + b, P.INK_SOFT)                   # 턱끈
    c.px(CX + 3, 16 + b, P.INK_SOFT)

    c.outline(P.INK_SOFT, only_color=P.INK_FAINT)
    c.outline(P.WOOD_DEEP, only_color=P.WOOD_BASE)
    return c


# ──────────────────────────────────────────────────────────────
NPCS = {
    "elder": elder,
    "blacksmith": blacksmith,
    "woman": woman,
    "wanderer": wanderer,
}

MANIFEST = {
    "frame_w": 32, "frame_h": 64,
    "anims": {"idle": {"frames": 2, "fps": 3, "loop": True}},
}


def main():
    strip_paths = []
    for name, fn in NPCS.items():
        frames = [fn(0), fn(1)]
        s = strip(frames)
        assert s.w == MANIFEST["anims"]["idle"]["frames"] * MANIFEST["frame_w"], \
            "strip width mismatch: %s" % name
        out_dir = os.path.join(ROOT, "assets", "sprites", "npc", name)
        png = os.path.join(out_dir, "idle.png")
        s.save(png)
        with open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8") as f:
            json.dump(MANIFEST, f, ensure_ascii=False, indent=2)
        strip_paths.append(png)
        print("saved:", png)

    sheet = contact_sheet(
        strip_paths,
        os.path.join(ROOT, "shots", "sheets", "npcs_sheet.png"),
        scale=6, cols=4)
    print("sheet:", sheet)


if __name__ == "__main__":
    main()
