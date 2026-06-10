# -*- coding: utf-8 -*-
"""STYLE_BIBLE §1 팔레트 (v1 잠금, 25색) — 모든 생성 에셋은 이 색만 사용한다.

투명은 (0,0,0,0). 새 색 추가 금지 — 필요하면 STYLE_BIBLE 갱신이 먼저다.
"""

def _hex(s: str):
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), 255)

# ── 먹/Ink (외곽선·머리카락·그림자) ──────────────────────────
INK_DEEPEST = _hex("1A1612")   # 가장 진한 먹 — 외곽선·동공·갓
INK_DARK    = _hex("2E2820")   # 진한 먹 — 머리카락·짙은 그림자
INK_MID     = _hex("4A4035")   # 중간 먹 — 일반 그림자
INK_SOFT    = _hex("6B5D4F")   # 옅은 먹 — 약한 음영·한지 외곽
INK_FAINT   = _hex("8C7E6F")   # 가장 옅은 먹 — 회청 그라데이션

# ── 한지/Paper (배경·옷감·UI) ────────────────────────────────
PAPER_BRIGHT = _hex("F5EBD8")  # 밝은 한지 — UI 패널 베이스
PAPER_BASE   = _hex("E8D9BC")  # 중간 한지 — 옷감 베이스 (도포)
PAPER_SHADE  = _hex("D5C4A1")  # 어두운 한지 — 옷감 그림자
PAPER_DEEP   = _hex("B8A483")  # 깊은 한지 — 강한 그림자

# ── 단청/Dancheong (절제된 전통 5색) ─────────────────────────
RED_BASE   = _hex("A8453F")    # 적 — 단청·관복·피니시 이펙트
RED_DEEP   = _hex("7D2E2A")    # 진 적
BLUE_BASE  = _hex("3F6B7D")    # 청 — 갓끈·상민 저고리
BLUE_DEEP  = _hex("2A4F5C")    # 진 청
GOLD_BASE  = _hex("C9A856")    # 황 — 엽전·자수
GOLD_DEEP  = _hex("997F40")    # 진 황
GREEN_BASE = _hex("5F7D45")    # 녹 — 풀·소나무
GREEN_DEEP = _hex("3F5B2E")    # 진 녹

# ── 피부 ─────────────────────────────────────────────────────
SKIN_LIGHT  = _hex("E5C9A6")
SKIN_BASE   = _hex("D4B088")
SKIN_SHADE  = _hex("B89263")
SKIN_DEEP   = _hex("8C6E48")

# ── 자연 보조 (나무·돌) ──────────────────────────────────────
WOOD_BASE  = _hex("B5856B")
WOOD_DEEP  = _hex("7F5640")
GRASS_BASE = _hex("6B7A56")
GRASS_DEEP = _hex("4F5641")

TRANSPARENT = (0, 0, 0, 0)

ALL_COLORS = {
    INK_DEEPEST, INK_DARK, INK_MID, INK_SOFT, INK_FAINT,
    PAPER_BRIGHT, PAPER_BASE, PAPER_SHADE, PAPER_DEEP,
    RED_BASE, RED_DEEP, BLUE_BASE, BLUE_DEEP,
    GOLD_BASE, GOLD_DEEP, GREEN_BASE, GREEN_DEEP,
    SKIN_LIGHT, SKIN_BASE, SKIN_SHADE, SKIN_DEEP,
    WOOD_BASE, WOOD_DEEP, GRASS_BASE, GRASS_DEEP,
}

# 짝색(베이스→그림자) 매핑 — 음영 자동화용
SHADE_OF = {
    PAPER_BRIGHT: PAPER_SHADE, PAPER_BASE: PAPER_SHADE, PAPER_SHADE: PAPER_DEEP,
    RED_BASE: RED_DEEP, BLUE_BASE: BLUE_DEEP, GOLD_BASE: GOLD_DEEP,
    GREEN_BASE: GREEN_DEEP, SKIN_LIGHT: SKIN_BASE, SKIN_BASE: SKIN_SHADE,
    SKIN_SHADE: SKIN_DEEP, WOOD_BASE: WOOD_DEEP, GRASS_BASE: GRASS_DEEP,
    INK_FAINT: INK_SOFT, INK_SOFT: INK_MID, INK_MID: INK_DARK, INK_DARK: INK_DEEPEST,
    PAPER_DEEP: INK_SOFT,
}


def validate(img) -> set:
    """PIL 이미지가 팔레트 밖 색을 쓰면 그 색들의 집합을 반환 (비면 합격).
    알파 0 픽셀은 무시. 부분 알파는 위반으로 취급(픽셀아트는 이진 알파)."""
    bad = set()
    rgba = img.convert("RGBA")
    for px in rgba.getdata():
        if px[3] == 0:
            continue
        if px[3] != 255 or px not in ALL_COLORS:
            bad.add(px)
    return bad
