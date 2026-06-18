#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
PixelLab MCP 산출물(측면 spearman) → protagonist_custom 시트로 통합.

입력: tools/pixel 기준 상대경로의 추출된 zip (.pl_tmp/char/Joseon_Spearman/animations/<folder>/east/frame_*.png)
출력: assets/sprites/protagonist_custom/<anim>.png (가로 스트립) + manifest.json

- 생성(5+1): idle, walk, jump, hurt, death, attack  (east 1방향, 좌측은 코드가 flip_h)
- 파생(무크레딧): run(=walk 빠르게), attack2/attack3(=attack 재사용, 콤보 차별은 SkillFx),
  charge(=attack 윈드업 프레임 홀드 루프), dodge(=jump 웅크림/착지 프레임 발췌)
- 전 프레임 92x92 고정 캔버스(대칭) → flip_h 로 좌향 런지가 올바르게 미러됨.
- foot_offset 는 idle/walk 의 최하단 불투명 행으로 산출(콜리전 바닥 y=+16 정렬).
"""
import os, json, glob
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, ".pl_tmp", "char", "Joseon_Spearman", "animations")
OUT = os.path.join(ROOT, "assets", "sprites", "protagonist_custom")
FW = FH = 92

# 생성된 base 애니 → zip 폴더명 매핑 (프레임 수로 식별)
BASE = {
    "idle":   "animating",                                          # breathing-idle (4)
    "walk":   "animating-65f48186",                                 # walking-6-frames (6)
    "jump":   "animating-9c428414",                                 # jumping-1 (9)
    "hurt":   "taking_a_punch",                                     # (6)
    "death":  "falling_backward",                                   # (7)
    "attack": "thrusting_a_long_spear_straight_forward_in_a_deep",  # v3 thrust (7)
}


def load_east(folder):
    fs = sorted(glob.glob(os.path.join(SRC, folder, "east", "frame_*.png")))
    return [Image.open(f).convert("RGBA") for f in fs]


def canvas(im):
    """92x92 캔버스 중앙 정렬(이미 92면 그대로)."""
    if im.size == (FW, FH):
        return im
    c = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    c.paste(im, ((FW - im.width) // 2, (FH - im.height) // 2), im)
    return c


def strip(frames, name):
    s = Image.new("RGBA", (FW * len(frames), FH), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        s.paste(canvas(f), (i * FW, 0), canvas(f))
    s.save(os.path.join(OUT, name + ".png"))
    return len(frames)


def feet_row(frames):
    lo = 0
    for f in frames:
        bbox = f.getbbox()
        if bbox:
            lo = max(lo, bbox[3])  # bottom
    return lo


def main():
    os.makedirs(OUT, exist_ok=True)
    base = {k: load_east(v) for k, v in BASE.items()}

    manifest = {"frame_w": FW, "frame_h": FH, "anims": {}}

    def add(name, frames, fps, loop):
        n = strip(frames, name)
        manifest["anims"][name] = {"frames": n, "fps": fps, "loop": loop}
        print(f"  {name:8s} {n} frames")

    # --- 생성 base ---
    add("idle",   base["idle"],   5,  True)
    add("walk",   base["walk"],   12, True)
    add("jump",   base["jump"],   12, False)
    add("hurt",   base["hurt"],   14, False)
    add("death",  base["death"],  10, False)
    add("attack", base["attack"], 18, False)

    # --- 파생 (무크레딧) ---
    add("run",     base["walk"],  18, True)                 # 같은 보행, 빠르게
    add("attack2", base["attack"], 16, False)               # 콤보 2타 (SkillFx 가 크레센트로 차별)
    add("attack3", base["attack"], 14, False)               # 콤보 3타 (SkillFx 가 회전 링)
    add("charge",  base["attack"][:2], 6, True)             # 창 당겨 모으는 윈드업 홀드
    # dodge: jump 의 웅크림→런지→착지→회복 발췌 = 낮은 자세 회피 굴림
    j = base["jump"]
    dodge_idx = [2, 3, 7, 8] if len(j) >= 9 else list(range(min(4, len(j))))
    add("dodge",   [j[i] for i in dodge_idx], 16, False)

    fr = feet_row(base["idle"] + base["walk"])
    foot_offset = 62 - fr  # 콜리전 바닥 +16 정렬 (screen_y = r - 46 + off = 16)
    print(f"\nfeet_row(idle+walk) = {fr}  ->  suggested foot_offset = {foot_offset}")

    with open(os.path.join(OUT, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    print("manifest.json written ->", OUT)


if __name__ == "__main__":
    main()
