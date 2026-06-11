# -*- coding: utf-8 -*-
"""UI 스킨 — 한지·먹 테마 (「호환기담」).

생성물 (assets/ui/):
  panel_hanji.png     48x48   9-slice 패널 (모서리 12px 안전영역, 단청 점 장식)
  button.png          48x20   한지 버튼
  button_pressed.png  48x20   눌린 상태 (PAPER_SHADE 바탕)
  hp_frame.png        104x12  먹 테두리 HP 바 (내부 투명, 내폭 100px = 1HP/px)
  balloon_tail.png    12x8    말풍선 꼬리 (아래 방향)
  title_logo.png      가변    「호환기담」 Galmuri11 64px + 2px INK_FAINT 그림자
  ending_scroll.png   320x200 펼친 두루마리 (한지 + 양끝 나무 축)
검수 시트: shots/sheets/ui_skin_sheet.png (scale=6)
"""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
import palette as P
from core import Canvas, contact_sheet
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
UI_DIR = os.path.join(ROOT, "assets", "ui")
FONT_PATH = os.path.join(ROOT, "assets", "fonts", "Galmuri11.ttf")


# ── 공용 장식: 단청 점 (작은 십자 — 팔 BLUE_DEEP, 중심 BLUE_BASE) ──
def dancheong_dot(c: Canvas, cx: int, cy: int):
    for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
        c.px(cx + dx, cy + dy, P.BLUE_DEEP)
    c.px(cx, cy, P.BLUE_BASE)


# ── ① panel_hanji 48x48 — 9-slice (모서리 12px 안전영역) ────────
def panel_hanji() -> Canvas:
    S = 48
    c = Canvas(S, S)
    c.rect(0, 0, S, S, P.PAPER_BRIGHT)
    # 1px 먹 테두리
    c.hline(0, 0, S, P.INK_SOFT); c.hline(0, S - 1, S, P.INK_SOFT)
    c.vline(0, 0, S, P.INK_SOFT); c.vline(S - 1, 0, S, P.INK_SOFT)
    # 내부 음영 (광원 좌상단 → 우/하 안쪽 1px) — 가장자리 전체에 균일 (9-slice 안전)
    c.hline(1, S - 2, S - 2, P.PAPER_SHADE)
    c.vline(S - 2, 1, S - 2, P.PAPER_SHADE)
    # 모서리 단청 점 (모두 12px 안전영역 안)
    for cx, cy in ((5, 5), (S - 6, 5), (5, S - 6), (S - 6, S - 6)):
        dancheong_dot(c, cx, cy)
    # 한지 결 점 — 모서리 영역에만 (가운데/가장자리는 늘어나므로 무지)
    for ox, oy in ((0, 0), (S - 12, 0), (0, S - 12), (S - 12, S - 12)):
        c.px(ox + 9, oy + 3, P.PAPER_BASE)
        c.px(ox + 3, oy + 9, P.PAPER_BASE)
        c.px(ox + 8, oy + 8, P.PAPER_BASE)
    # 둥근 모서리 (corner px 제거)
    for x, y in ((0, 0), (S - 1, 0), (0, S - 1), (S - 1, S - 1)):
        c.px(x, y, P.TRANSPARENT)
    return c


# ── ② button / button_pressed 48x20 ────────────────────────────
def button(pressed: bool) -> Canvas:
    W, H = 48, 20
    c = Canvas(W, H)
    base = P.PAPER_SHADE if pressed else P.PAPER_BASE
    c.rect(0, 0, W, H, base)
    # 테두리
    c.hline(0, 0, W, P.INK_SOFT); c.hline(0, H - 1, W, P.INK_SOFT)
    c.vline(0, 0, H, P.INK_SOFT); c.vline(W - 1, 0, H, P.INK_SOFT)
    if pressed:
        # 눌림 — 위/좌 안쪽에 그림자 (빛이 막힘)
        c.hline(1, 1, W - 2, P.PAPER_DEEP)
        c.vline(1, 1, H - 2, P.PAPER_DEEP)
    else:
        # 상단 하이라이트 + 우/하 그림자
        c.hline(1, 1, W - 2, P.PAPER_BRIGHT)
        c.hline(1, H - 2, W - 2, P.PAPER_DEEP)
        c.vline(W - 2, 2, H - 3, P.PAPER_SHADE)
    # 좌우 매듭 점 장식 (눌리면 1px 아래로)
    yy = 10 if pressed else 9
    for x in (4, W - 5):
        c.px(x, yy, P.BLUE_DEEP)
        c.px(x, yy + 1, P.BLUE_DEEP)
    # 둥근 모서리
    for x, y in ((0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)):
        c.px(x, y, P.TRANSPARENT)
    return c


# ── ③ hp_frame 104x12 — 먹 테두리, 내부 투명 ────────────────────
def hp_frame() -> Canvas:
    W, H = 104, 12
    c = Canvas(W, H)
    # 좌상=INK_DARK(밝은 쪽) / 우하=INK_DEEPEST(그림자 쪽)
    c.hline(0, 0, W, P.INK_DARK)
    c.vline(0, 0, H, P.INK_DARK)
    c.hline(0, H - 1, W, P.INK_DEEPEST)
    c.vline(W - 1, 0, H, P.INK_DEEPEST)
    # 양끝 2px 두께 마감 (붓 마감 느낌) → 내부 가용폭 정확히 100px (x2..101)
    c.vline(1, 1, H - 2, P.INK_DARK)
    c.vline(W - 2, 1, H - 2, P.INK_DEEPEST)
    # 둥근 모서리
    for x, y in ((0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)):
        c.px(x, y, P.TRANSPARENT)
    # 내부 (x2..101, y1..10) 는 투명 유지 — 게임이 채움
    return c


# ── ④ balloon_tail 12x8 — 아래로 좁아지는 꼬리 ──────────────────
def balloon_tail() -> Canvas:
    c = Canvas(12, 8)
    # (ink_left, paper_x0, paper_x1, ink_right) — 윗변은 말풍선 패널과 맞닿으므로 열림
    rows = [
        (0, 1, 10, 11),
        (1, 2, 9, 10),
        (1, 2, 9, 10),
        (2, 3, 8, 9),
        (3, 4, 7, 8),
        (4, 5, 6, 7),
    ]
    for y, (il, p0, p1, ir) in enumerate(rows):
        c.px(il, y, P.INK_SOFT)
        c.px(ir, y, P.INK_SOFT)
        c.hline(p0, y, p1 - p0 + 1, P.PAPER_BRIGHT)
        c.px(p1, y, P.PAPER_SHADE)  # 우측(그림자 쪽) 내부 음영
    # 꼬리 끝 — 2px 평탄 팁 (중심 5.5 대칭)
    c.px(5, 6, P.INK_SOFT); c.px(6, 6, P.INK_SOFT)
    c.px(5, 7, P.INK_SOFT); c.px(6, 7, P.INK_SOFT)
    return c


# ── ⑤ title_logo — 「호환기담」 Galmuri11 64px ──────────────────
def title_logo() -> Canvas:
    font = ImageFont.truetype(FONT_PATH, 64)
    text = "호환기담"
    # 넉넉한 캔버스에 렌더 후 내용 bbox 로 크롭
    tmp = Image.new("L", (64 * 6, 160), 0)
    d = ImageDraw.Draw(tmp)
    d.text((16, 16), text, font=font, fill=255)
    bbox = tmp.getbbox()
    if bbox is None:
        raise RuntimeError("폰트 렌더 실패: 빈 비트맵")
    mask = tmp.crop(bbox)
    mw, mh = mask.size
    M, SH = 8, 2  # 여백 8px, 그림자 오프셋 2px
    c = Canvas(mw + SH + M * 2, mh + SH + M * 2)
    mp = mask.load()
    # 그림자 먼저 (INK_FAINT, +2/+2) — 임계값 128 이진화로 AA 제거
    for y in range(mh):
        for x in range(mw):
            if mp[x, y] >= 128:
                c.px(M + x + SH, M + y + SH, P.INK_FAINT)
    # 본문 (INK_DEEPEST)
    for y in range(mh):
        for x in range(mw):
            if mp[x, y] >= 128:
                c.px(M + x, M + y, P.INK_DEEPEST)
    return c


# ── ⑥ ending_scroll 320x200 — 펼친 두루마리 ─────────────────────
def ending_scroll() -> Canvas:
    W, H = 320, 200
    c = Canvas(W, H)
    ROD = 14          # 나무 축 폭
    PT, PB = 10, 190  # 종이 세로 범위 (y10..189)

    # ── 한지 본체 ──
    c.rect(ROD, PT, W - ROD * 2, PB - PT, P.PAPER_BRIGHT)
    # 위/아래 가장자리
    c.hline(ROD, PT, W - ROD * 2, P.PAPER_SHADE)
    c.hline(ROD, PB - 2, W - ROD * 2, P.PAPER_SHADE)
    c.hline(ROD, PB - 1, W - ROD * 2, P.PAPER_DEEP)
    # 축 근처 말림 음영 (양끝 4px 그라데이션)
    for i, col in enumerate((P.PAPER_DEEP, P.PAPER_SHADE, P.PAPER_SHADE, P.PAPER_BASE)):
        c.vline(ROD + i, PT + 1, PB - PT - 2, col)
        c.vline(W - ROD - 1 - i, PT + 1, PB - PT - 2, col)
    # 한지 결 — 성근 세로 섬유 점 (결정적 의사난수)
    for y in range(PT + 3, PB - 4):
        for x in range(ROD + 6, W - ROD - 6):
            if ((x * 73856093) ^ (y * 19349663)) % 89 == 0:
                c.px(x, y, P.PAPER_BASE)
                c.px(x, y + 1, P.PAPER_BASE)
    # 먹선 틀 (글이 들어갈 영역 테두리)
    bx0, by0 = ROD + 14, PT + 14
    bx1, by1 = W - ROD - 15, PB - 15
    c.hline(bx0, by0, bx1 - bx0 + 1, P.INK_FAINT)
    c.hline(bx0, by1, bx1 - bx0 + 1, P.INK_FAINT)
    c.vline(bx0, by0, by1 - by0 + 1, P.INK_FAINT)
    c.vline(bx1, by0, by1 - by0 + 1, P.INK_FAINT)
    # 먹선 모서리 단청 점 — 먹선과 겹치지 않게 틀 안쪽으로 4px 띄움
    for cx, cy in ((bx0 + 4, by0 + 4), (bx1 - 4, by0 + 4),
                   (bx0 + 4, by1 - 4), (bx1 - 4, by1 - 4)):
        dancheong_dot(c, cx, cy)

    # ── 좌우 나무 축 (전체 높이) ──
    for x0 in (0, W - ROD):
        c.rect(x0 + 1, 2, ROD - 2, H - 4, P.WOOD_DEEP)
        # 좌상 광원 — 왼쪽 면 하이라이트
        c.vline(x0 + 3, 5, H - 10, P.WOOD_BASE)
        c.vline(x0 + 4, 5, H - 10, P.WOOD_BASE)
        # 외곽 (진한 먹)
        c.vline(x0, 2, H - 4, P.INK_DARK)
        c.vline(x0 + ROD - 1, 2, H - 4, P.INK_DARK)
        c.hline(x0 + 1, 1, ROD - 2, P.INK_DARK)
        c.hline(x0 + 1, H - 2, ROD - 2, P.INK_DARK)
        # 금장 마구리 (위: 밝음 / 아래: 그림자)
        c.rect(x0 + 3, 0, ROD - 6, 2, P.GOLD_BASE)
        c.rect(x0 + 3, 2, ROD - 6, 2, P.GOLD_DEEP)
        c.rect(x0 + 3, H - 4, ROD - 6, 2, P.GOLD_BASE)
        c.rect(x0 + 3, H - 2, ROD - 6, 2, P.GOLD_DEEP)
    return c


# ── 메인: 생성 → 저장 → manifest → 검증 → 시트 ──────────────────
ASSETS = [
    # (이름, 빌더, 추가 manifest 필드, preview 배율)
    ("panel_hanji",    panel_hanji,           {"nine_slice_margin": 12}, 8),
    ("button",         lambda: button(False), {},                        8),
    ("button_pressed", lambda: button(True),  {},                        8),
    ("hp_frame",       hp_frame,              {"inner_rect": [2, 1, 100, 10]}, 8),
    ("balloon_tail",   balloon_tail,          {},                        8),
    ("title_logo",     title_logo,            {},                        3),
    ("ending_scroll",  ending_scroll,         {},                        3),
]


DARK_ASSETS = {"hp_frame", "title_logo"}  # 먹색 위주 — 시트 검수용 한지 받침 필요


def main():
    manifest = {"type": "ui_skin", "images": {}}
    paths = []
    sheets_dir = os.path.join(ROOT, "shots", "sheets")
    for name, build, extra, scale in ASSETS:
        cv = build()
        path = os.path.join(UI_DIR, name + ".png")
        cv.save(path, preview_scale=scale)  # 팔레트 위반 시 예외
        entry = {"frame_w": cv.w, "frame_h": cv.h, "frames": 1}
        entry.update(extra)
        manifest["images"][name] = entry
        if name in DARK_ASSETS:
            # 시트 전용: 한지 받침 위에 합성 (게임 에셋은 투명 배경 그대로)
            backed = Canvas(cv.w + 8, cv.h + 8)
            backed.rect(0, 0, backed.w, backed.h, P.PAPER_BASE)
            backed.paste(cv, 4, 4)
            tmp = os.path.join(sheets_dir, "_backed_" + name + ".png")
            backed.save(tmp, preview_scale=1)
            paths.append(tmp)
        else:
            paths.append(path)
        print("saved: %s (%dx%d)" % (path, cv.w, cv.h))

    # manifest 검증: frames * frame_w == PNG 폭, frame_h == PNG 높이
    for name, entry in manifest["images"].items():
        img = Image.open(os.path.join(UI_DIR, name + ".png"))
        assert entry["frames"] * entry["frame_w"] == img.width, name + " width mismatch"
        assert entry["frame_h"] == img.height, name + " height mismatch"
    mpath = os.path.join(UI_DIR, "manifest.json")
    with open(mpath, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    print("manifest ok:", mpath)

    sheet = contact_sheet(
        paths, os.path.join(ROOT, "shots", "sheets", "ui_skin_sheet.png"),
        scale=6, cols=3)
    print("sheet:", sheet)


if __name__ == "__main__":
    main()
