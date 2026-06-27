#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
PixelLab 역동적 콤보/차지 애니 4종을 protagonist_custom 에 통합(2차).
attack(1타 폭발 찌름)/attack2(횡쓸기)/attack3(회전 내려찍기)/charge(기 모으기).
- get_character 의 공개 프레임 URL 에서 직접 받아 92x92 스트립 재생성.
- 기존 idle/walk/jump/hurt/death/run/dodge 스트립·manifest 는 보존, 4종 항목만 갱신.
"""
import os, json, subprocess
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "sprites", "protagonist_custom")
TMP = os.path.join(ROOT, ".pl_tmp", "new")
FW = FH = 92
BASE = ("https://backblaze.pixellab.ai/file/pixellab-characters/"
        "0f5aa30e-1cc6-4d3a-8f94-f19d68385f1b/"
        "f5fd2830-c0f3-48c3-aa17-6171e3559da4/animations/%s/east/%d.png")

# name -> (anim_uuid, frame_count, fps, loop)
NEW = {
    "attack":  ("0dc846a9-c360-44c0-ba59-fa12800630ea", 9, 24, False),  # 1타 폭발 찌름
    "attack2": ("daae20c2-78ec-4981-920b-30dfb41bc409", 9, 24, False),  # 2타 횡쓸기
    "attack3": ("1552a702-6a0c-40cd-9f77-d19ce309bd5f", 13, 24, False), # 3타 도약 회전 내려찍기 v2(역동 강화)
    "charge":  ("8baf25cc-7d2b-4efe-b3c3-080335cbdd99", 7, 9, True),    # 기 모으기(루프)
}


def fetch(uuid, n):
    d = os.path.join(TMP, uuid)
    os.makedirs(d, exist_ok=True)
    frames = []
    for i in range(n):
        p = os.path.join(d, "%d.png" % i)
        if not os.path.exists(p):
            subprocess.run(["curl", "-s", "-f", "-o", p, BASE % (uuid, i)], check=True)
        frames.append(Image.open(p).convert("RGBA"))
    return frames


def canvas(im):
    if im.size == (FW, FH):
        return im
    c = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    c.paste(im, ((FW - im.width) // 2, (FH - im.height) // 2), im)
    return c


def main():
    mpath = os.path.join(OUT, "manifest.json")
    manifest = json.load(open(mpath, encoding="utf-8"))
    for name, (uuid, n, fps, loop) in NEW.items():
        frames = fetch(uuid, n)
        s = Image.new("RGBA", (FW * len(frames), FH), (0, 0, 0, 0))
        for i, f in enumerate(frames):
            s.paste(canvas(f), (i * FW, 0), canvas(f))
        s.save(os.path.join(OUT, name + ".png"))
        manifest["anims"][name] = {"frames": len(frames), "fps": fps, "loop": loop}
        print(f"  {name:8s} {len(frames)} frames  fps={fps} loop={loop}")
    json.dump(manifest, open(mpath, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    print("manifest updated ->", OUT)


if __name__ == "__main__":
    main()
