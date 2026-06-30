#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
「해원」 회상 컷 인물 통합 — PixelLab v3 캐릭터의 측면(east, 우향) 정지 프레임 1장을
회상 씬용 스틸 스프라이트로 떨군다.

회상 컷(cutscene.gd)은 애니메이션 없이 '수묵 한 폭' 같은 정지 인물만 필요하므로,
각 캐릭터의 east 회전 1장만 받아 투명 여백을 잘라(autocrop) 발이 바닥에 맞게 한다.
cutscene.gd 는 sprite 높이만큼 위로 올려(offset=-h) 발(아래중앙)을 figure.y 에 정렬.

산출:
  assets/sprites/cutscene/yunseul/idle.png       (윤슬 — 강가 회상)
  assets/sprites/cutscene/gilson_young/idle.png  (젊은 길손/현감 — 강가·수문 회상 공용)

PNG 가 없으면 cutscene.gd 가 수묵 실루엣으로 폴백하므로, 이 스크립트는 'PC에서 1회'면 된다.
실행: python tools/pixel/integrate_cutscene.py   (PIL + 인터넷 필요)
그 뒤 Godot 한 번 열어 import(.import 생성) → 회상 씬에 실제 인물이 뜬다.
"""
import os
import urllib.request
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "sprites", "cutscene")
TMP = os.path.join(ROOT, ".pl_tmp", "cutscene")

BASE = "https://backblaze.pixellab.ai/file/pixellab-characters/0f5aa30e-1cc6-4d3a-8f94-f19d68385f1b"

# 회상 인물: 폴더명 → PixelLab 캐릭터 east(우향) 공개 URL
CHARS = {
    "yunseul":      "%s/2954c31a-d7de-488a-bdc4-f634a5b67440/rotations/east.png" % BASE,
    "gilson_young": "%s/d61c4810-2f4c-4caa-b9af-e922d503ed95/rotations/east.png" % BASE,
}


def fetch(url, cache_path):
    if os.path.exists(cache_path):
        return cache_path
    os.makedirs(os.path.dirname(cache_path), exist_ok=True)
    print("  download:", url)
    req = urllib.request.Request(url, headers={"User-Agent": "joseon-rpg-integrate"})
    with urllib.request.urlopen(req, timeout=60) as r, open(cache_path, "wb") as f:
        f.write(r.read())
    return cache_path


def main():
    for name, url in CHARS.items():
        print("[%s]" % name)
        cache = os.path.join(TMP, name + "_east.png")
        try:
            fetch(url, cache)
        except Exception as e:
            print("  !! 다운로드 실패 — 건너뜀(폴백 실루엣 유지):", e)
            continue
        im = Image.open(cache).convert("RGBA")
        bbox = im.getbbox()              # 투명 여백 제거 → 발이 PNG 하단에 닿게
        if bbox:
            im = im.crop(bbox)
        dst_dir = os.path.join(OUT, name)
        os.makedirs(dst_dir, exist_ok=True)
        dst = os.path.join(dst_dir, "idle.png")
        im.save(dst)
        print("  -> %s  (%dx%d)" % (os.path.relpath(dst, ROOT), im.width, im.height))
    print("\n완료. Godot 한 번 열어 import 하면 회상 씬에 인물이 뜹니다.")


if __name__ == "__main__":
    main()
