#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
성불(진혼) VFX 텍스처를 PixelLab 에서 받아 assets/sprites/fx/ 에 배치한다(#3, 2026-07-10).

원혼이 스러질 때 차갑게 흩어지는 대신 따뜻한 빛으로 천도되는 연출('혼을 달램').
`skill_fx.gd`의 soul_ascend() 가 이 텍스처를 상승·확대·페이드로 재생한다.

출처(PixelLab MCP, create_1_direction_object sidescroller 64x64, 16후보 중 선택):
  soul_ascend       = object 790f1f57-64a0-4104-9108-1702b68f4f45 (frame 12: 빛 속 합장한 넋)  ← 게임 채택
  soul_ascend_lotus = object 65ad324c-1a63-4740-b598-14d3aaef7ff7 (frame 4: 연화대 위 넋)     ← 대안 보관
재실행하면 원본을 다시 받아 덮어쓴다(재현용). Godot 에디터/`--import`로 .import 재생성 필요.
"""
import os, subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
FX = os.path.join(ROOT, "assets", "sprites", "fx")
BUCKET = ("https://backblaze.pixellab.ai/file/pixellab-characters/objects/"
          "0f5aa30e-1cc6-4d3a-8f94-f19d68385f1b/%s/rotations/unknown.png")

ASSETS = {
    "soul_ascend":       "790f1f57-64a0-4104-9108-1702b68f4f45",
    "soul_ascend_lotus": "65ad324c-1a63-4740-b598-14d3aaef7ff7",
}


def main():
    os.makedirs(FX, exist_ok=True)
    for name, oid in ASSETS.items():
        out = os.path.join(FX, name + ".png")
        subprocess.run(["curl", "-s", "-f", "-o", out, BUCKET % oid], check=True)
        print("  %-18s <- %s" % (name + ".png", oid))
    print("done ->", FX)


if __name__ == "__main__":
    main()
