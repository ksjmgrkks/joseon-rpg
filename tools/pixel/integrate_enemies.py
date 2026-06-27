#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
PixelLab 적/보스 측면 스프라이트 → assets/sprites/enemies/<type>/ 시트로 통합.

주인공(integrate_pixellab.py)과 같은 방식의 적 버전.
- 데이터는 tools/pixel/enemy_pl.json 에서 읽는다(적별 character_uuid + 애니별 anim_uuid/frames/fps/loop).
- 각 애니의 east 프레임을 PixelLab 공개 URL 에서 curl 로 받아(캐시) 가로 스트립 + manifest.json 생성.
- 캔버스 크기는 받은 프레임들의 최대 폭/높이로 자동 산정(잘림 방지). enemy 별로 frame_w/h 강제 가능.
- 좌향은 게임 코드가 flip_h → east 1방향만 받으면 됨.
- derived: 기존 base 스트립 프레임을 잘라 무크레딧 파생(예: telegraph = attack 윈드업 홀드).
- 각 적의 foot_offset 제안값(idle+walk 최하단 불투명 행 기준)을 출력 → 해당 .tscn 의
  Sprite2D foot_offset 을 그 값으로 맞춘다(콜리전 바닥 정렬).

실행(PC, PIL+curl 필요):  python tools/pixel/integrate_enemies.py [enemy_type ...]
  인자 없으면 enemy_pl.json 의 모든 적을 처리. 특정 적만 하려면 이름 나열.
"""
import os, re, sys, json, subprocess
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CFG = os.path.join(os.path.dirname(__file__), "enemy_pl.json")
TMP = os.path.join(ROOT, ".pl_tmp", "enemies")
OUT_BASE = os.path.join(ROOT, "assets", "sprites", "enemies")
SCENES = os.path.join(ROOT, "scenes", "enemies")


def patch_scene_foot_offset(scene_name, fh, fr, coll_half):
    """scenes/enemies/<scene_name>.tscn 의 EnemyVisual foot_offset 을 패치.
    스프라이트 노드 scale 을 읽어 보정: offset = fh/2 - fr + coll_half/scale.
    (콜리전은 부모 바디에 있어 스케일 영향을 안 받으므로 coll_half 를 scale 로 나눈다.)"""
    p = os.path.join(SCENES, scene_name + ".tscn")
    if not os.path.exists(p):
        print("    (scene 없음, 건너뜀: %s)" % scene_name)
        return
    txt = open(p, encoding="utf-8").read()
    m = re.search(r"scale = Vector2\(([0-9.]+),", txt)
    scale = float(m.group(1)) if m else 1.0
    value = round((fh / 2.0) - fr + coll_half / scale, 1)
    new = re.sub(r"foot_offset = -?[0-9]+(?:\.[0-9]+)?",
                 "foot_offset = %.1f" % value, txt, count=1)
    if new != txt:
        open(p, "w", encoding="utf-8").write(new)
        print("    patched %s.tscn  scale=%.2f  foot_offset=%.1f" % (scene_name, scale, value))
    else:
        print("    (%s.tscn foot_offset 라인 없음 — 수동 확인)" % scene_name)
URL = ("https://backblaze.pixellab.ai/file/pixellab-characters/"
       "%s/%s/animations/%s/east/%d.png")   # account, character, anim_uuid, frame_idx


def fetch(account, character, uuid, n):
    d = os.path.join(TMP, character, uuid)
    os.makedirs(d, exist_ok=True)
    frames = []
    for i in range(n):
        p = os.path.join(d, "%d.png" % i)
        if not os.path.exists(p):
            subprocess.run(["curl", "-s", "-f", "-o", p, URL % (account, character, uuid, i)],
                           check=True)
        frames.append(Image.open(p).convert("RGBA"))
    return frames


def pad(im, fw, fh):
    if im.size == (fw, fh):
        return im
    c = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    c.paste(im, ((fw - im.width) // 2, (fh - im.height) // 2), im)
    return c


def feet_row(frames):
    lo = 0
    for f in frames:
        bbox = f.getbbox()
        if bbox:
            lo = max(lo, bbox[3])
    return lo


def build_enemy(name, spec, account):
    out_dir = os.path.join(OUT_BASE, name)
    os.makedirs(out_dir, exist_ok=True)
    print("== %s ==" % name)

    # 1) 모든 base 애니 east 프레임 다운로드
    base = {}
    for anim, a in spec["anims"].items():
        base[anim] = fetch(account, spec["character"], a["uuid"], a["frames"])

    # 2) 캔버스 크기 — 강제값 없으면 받은 전 프레임 최대 폭/높이
    all_frames = [f for fs in base.values() for f in fs]
    fw = spec.get("frame_w") or max(f.width for f in all_frames)
    fh = spec.get("frame_h") or max(f.height for f in all_frames)
    print("  canvas %dx%d" % (fw, fh))

    manifest = {"frame_w": fw, "frame_h": fh, "anims": {}}
    strips = {}   # anim -> padded frame list (파생에서 재사용)

    def write_strip(anim, frames, fps, loop):
        padded = [pad(f, fw, fh) for f in frames]
        s = Image.new("RGBA", (fw * len(padded), fh), (0, 0, 0, 0))
        for i, f in enumerate(padded):
            s.paste(f, (i * fw, 0), f)
        s.save(os.path.join(out_dir, anim + ".png"))
        manifest["anims"][anim] = {"frames": len(padded), "fps": fps, "loop": loop}
        strips[anim] = padded
        print("  %-10s %2d frames  fps=%d loop=%s" % (anim, len(padded), fps, loop))

    # 3) base 스트립
    for anim, a in spec["anims"].items():
        write_strip(anim, base[anim], a["fps"], a["loop"])

    # 4) derived 파생(무크레딧) — base 프레임 슬라이스
    for anim, d in spec.get("derived", {}).items():
        src = strips[d["from"]]
        s0, s1 = d.get("slice", [0, len(src)])
        write_strip(anim, src[s0:s1], d["fps"], d["loop"])

    # 5) foot_offset 제안 (idle+walk 의 최하단). 캔버스 세로 중앙 기준.
    ref = []
    for k in ("idle", "walk"):
        if k in strips:
            ref += strips[k]
    if ref:
        fr = feet_row(ref)
        # 콜리전 바닥 정렬: offset.y = fh/2 + coll_half - feet_row.
        # coll_half = 콜리전 박스 반높이(없으면 16). 주인공은 fh=92, coll≈16 → 62-fr 과 동일.
        coll_half = spec.get("coll_half", 16)
        print("  feet_row(idle+walk)=%d  (1x foot_offset≈%d)" % (fr, (fh // 2) + coll_half - fr))
        # 이 시트를 쓰는 씬들의 foot_offset 자동 패치(scale 보정 포함).
        # 접지가 어긋나면 enemy_pl.json 의 coll_half 조정 후 재실행.
        for sc in spec.get("scenes", []):
            patch_scene_foot_offset(sc, fh, fr, coll_half)

    with open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    print("  manifest.json ->", out_dir)


def main():
    cfg = json.load(open(CFG, encoding="utf-8"))
    account = cfg["account"]
    want = sys.argv[1:]
    for name, spec in cfg["enemies"].items():
        if want and name not in want:
            continue
        build_enemy(name, spec, account)


if __name__ == "__main__":
    main()
