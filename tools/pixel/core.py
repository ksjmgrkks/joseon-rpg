# -*- coding: utf-8 -*-
"""픽셀아트 생성 코어 — Pillow 래퍼.

규칙 (STYLE_BIBLE):
- palette.ALL_COLORS 만 사용 (save 시 자동 검증, 위반이면 예외)
- 이진 알파 (0 또는 255)
- 외곽선 1px, 검정 단색 금지 → 베이스보다 1~2단 진한 짝색 사용
- 광원 좌상단 — 그림자는 우하단

사용 예:
    c = Canvas(32, 64)
    c.rect(10, 20, 12, 16, palette.PAPER_BASE)
    c.outline(palette.INK_SOFT)              # 불투명 영역 자동 외곽선
    c.save("assets/sprites/protagonist/idle_0.png")   # + .preview.png (8x)
"""
import os
from PIL import Image

try:
    from . import palette
except ImportError:  # 스크립트로 직접 실행하는 에이전트용
    import palette


class Canvas:
    def __init__(self, w: int, h: int):
        self.w, self.h = w, h
        self.img = Image.new("RGBA", (w, h), palette.TRANSPARENT)
        self._px = self.img.load()

    # ── 기본 프리미티브 ──────────────────────────────────────
    def px(self, x: int, y: int, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self._px[x, y] = c

    def get(self, x: int, y: int):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self._px[x, y]
        return palette.TRANSPARENT

    def rect(self, x: int, y: int, w: int, h: int, c):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.px(xx, yy, c)

    def hline(self, x: int, y: int, w: int, c):
        self.rect(x, y, w, 1, c)

    def vline(self, x: int, y: int, h: int, c):
        self.rect(x, y, 1, h, c)

    def line(self, x0: int, y0: int, x1: int, y1: int, c):
        """브레젠험 — 칼·지팡이 같은 사선용."""
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.px(x0, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy; x0 += sx
            if e2 <= dx:
                err += dx; y0 += sy

    def disc(self, cx: int, cy: int, r: int, c):
        """채운 원 — 머리·둥근 어깨용."""
        for yy in range(cy - r, cy + r + 1):
            for xx in range(cx - r, cx + r + 1):
                if (xx - cx) ** 2 + (yy - cy) ** 2 <= r * r + r * 0.5:
                    self.px(xx, yy, c)

    # ── 픽셀아트 보조 ────────────────────────────────────────
    def outline(self, c, only_color=None):
        """불투명 영역의 빈 이웃 픽셀에 외곽선. only_color 를 주면 그 색 영역만."""
        src = [[self.get(x, y) for x in range(self.w)] for y in range(self.h)]
        for y in range(self.h):
            for x in range(self.w):
                if src[y][x][3] != 0:
                    continue
                for nx, ny in ((x-1, y), (x+1, y), (x, y-1), (x, y+1)):
                    if 0 <= nx < self.w and 0 <= ny < self.h:
                        n = src[ny][nx]
                        if n[3] != 0 and n != c and (only_color is None or n == only_color):
                            self.px(x, y, c)
                            break

    def shade_bottom_right(self, base, shade, region=None):
        """광원 좌상단 규칙 — base 색 픽셀 중 우/하가 비거나 다른 색이면 shade 로."""
        x0, y0, x1, y1 = region or (0, 0, self.w, self.h)
        src = [[self.get(x, y) for x in range(self.w)] for y in range(self.h)]
        for y in range(y0, y1):
            for x in range(x0, x1):
                if src[y][x] != base:
                    continue
                right = self.get(x + 1, y)
                below = self.get(x, y + 1)
                if right != base or below != base:
                    if right[3] == 0 or below[3] == 0 or right != base:
                        self.px(x, y, shade)

    def dither(self, x: int, y: int, w: int, h: int, c, parity: int = 0):
        """체커보드 디더 — 한지 질감·옷 주름."""
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                if (xx + yy) % 2 == parity:
                    self.px(xx, yy, c)

    def mirror_x(self) -> "Canvas":
        out = Canvas(self.w, self.h)
        out.img = self.img.transpose(Image.FLIP_LEFT_RIGHT)
        out._px = out.img.load()
        return out

    def paste(self, other: "Canvas", x: int, y: int):
        self.img.alpha_composite(other.img, (x, y))
        self._px = self.img.load()

    def shifted(self, dx: int, dy: int) -> "Canvas":
        out = Canvas(self.w, self.h)
        out.img.alpha_composite(self.img, (dx, dy)) if (dx >= 0 and dy >= 0) else None
        if dx < 0 or dy < 0:
            tmp = Image.new("RGBA", (self.w, self.h), palette.TRANSPARENT)
            tmp.paste(self.img, (dx, dy), self.img)
            out.img = tmp
        out._px = out.img.load()
        return out

    # ── 저장/검증 ────────────────────────────────────────────
    def save(self, path: str, preview_scale: int = 8, strict: bool = True):
        bad = palette.validate(self.img)
        if bad and strict:
            raise ValueError("팔레트 위반 색 발견: %s" % sorted(bad))
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
        self.img.save(path)
        if preview_scale > 1:
            big = self.img.resize((self.w * preview_scale, self.h * preview_scale), Image.NEAREST)
            prev = path[:-4] + ".preview.png" if path.endswith(".png") else path + ".preview.png"
            big.save(prev)
        return path


def strip(frames, gap: int = 0) -> Canvas:
    """프레임 리스트 → 가로 스트립 (AnimatedSprite 슬라이스용)."""
    w = sum(f.w for f in frames) + gap * (len(frames) - 1)
    h = max(f.h for f in frames)
    out = Canvas(w, h)
    x = 0
    for f in frames:
        out.paste(f, x, 0)
        x += f.w + gap
    return out


def contact_sheet(paths, out_path: str, scale: int = 4, cols: int = 8, pad: int = 4):
    """여러 PNG 를 한 장의 검수 시트로 — 에이전트/오케스트레이터가 Read 로 한눈에 본다."""
    imgs = [Image.open(p).convert("RGBA") for p in paths]
    cw = max(i.width for i in imgs) + pad
    ch = max(i.height for i in imgs) + pad
    rows = (len(imgs) + cols - 1) // cols
    sheet = Image.new("RGBA", (cw * min(cols, len(imgs)), ch * rows), (40, 36, 30, 255))
    for n, im in enumerate(imgs):
        sheet.alpha_composite(im, ((n % cols) * cw + pad // 2, (n // cols) * ch + pad // 2))
    big = sheet.resize((sheet.width * scale, sheet.height * scale), Image.NEAREST)
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    big.save(out_path)
    return out_path
