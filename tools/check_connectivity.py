# -*- coding: utf-8 -*-
"""월드 그래프 연결성 검증 — 모든 LevelExit 가 실재 씬의 실재 진입점으로 이어지는지.

손으로 짠 .tscn 레벨(Marker2D entry + level_exit.gd) 과
데이터 기반 스테이지(assets/stages/*.json) 양쪽을 읽어,
각 출구의 (target_scene, target_entry) 가 해석 가능한지 보고한다.

실행: python tools/check_connectivity.py   (exit 0 = 모든 링크 정상)
"""
import json, os, re, sys, glob
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
os.chdir(ROOT)

# scene 경로 → {"entries": set, "exits": [(target_path, entry)]}
scenes = {}


def res(path):
    return path.replace("res://", "")


def parse_tscn(path):
    txt = open(path, encoding="utf-8").read()
    entries, exits = set(), []
    # ext_resource id → 스크립트 경로 (level_entry/level_exit 식별용)
    extmap = {}
    for m in re.finditer(r'\[ext_resource type="Script" path="([^"]+)" id="([^"]+)"\]', txt):
        extmap[m.group(2)] = m.group(1)
    blocks = re.split(r"\n\[node ", txt)
    for b in blocks:
        head = b.splitlines()[0] if b else ""
        nm = re.search(r'name="([^"]+)"', head)
        scr = re.search(r'script = ExtResource\("([^"]+)"\)', b)
        scr_path = extmap.get(scr.group(1), "") if scr else ""
        # LevelEntry: 노드 스크립트가 level_entry.gd → name 이 entry 키
        if ("level_entry.gd" in b or "level_entry.gd" in scr_path) and nm:
            entries.add(nm.group(1))
        # LevelExit: target_scene + target_entry
        if "target_scene" in b:
            ts = re.search(r'target_scene = "([^"]+)"', b)
            te = re.search(r'target_entry = &?"([^"]+)"', b)
            if ts:
                exits.append((res(ts.group(1)), te.group(1) if te else "default"))
    sid = re.search(r'stage_id = "([^"]+)"', txt)
    return entries, exits, (sid.group(1) if sid else None)


def parse_stage_json(sid, entries, exits):
    p = "assets/stages/%s.json" % sid
    if not os.path.exists(p):
        return
    d = json.load(open(p, encoding="utf-8"))
    for e in d.get("entries", []):
        entries.add(e.get("name", "default"))
    for x in d.get("exits", []):
        exits.append((res(x.get("target", "")), x.get("entry", "default")))


for path in glob.glob("scenes/levels/*.tscn"):
    entries, exits, sid = parse_tscn(path)
    if sid:
        parse_stage_json(sid, entries, exits)
    scenes[path.replace("\\", "/")] = {"entries": entries, "exits": exits}

problems = []
for path, info in sorted(scenes.items()):
    for target, entry in info["exits"]:
        if target not in scenes:
            problems.append("%s → %s : 대상 씬 없음" % (path, target))
        elif entry not in scenes[target]["entries"]:
            problems.append("%s → %s [%s] : 진입점 없음 (있는 것: %s)"
                            % (path, target, entry, sorted(scenes[target]["entries"])))

print("== 스테이지 %d개, 출구 %d개 검사 ==" % (
    len(scenes), sum(len(i["exits"]) for i in scenes.values())))
for path, info in sorted(scenes.items()):
    print("  %-44s entries=%s exits=%d" % (
        path.split("/")[-1], sorted(info["entries"]), len(info["exits"])))
if problems:
    print("\n!! 연결 문제 %d건:" % len(problems))
    for p in problems:
        print("  -", p)
    sys.exit(1)
print("\nOK — 모든 출구가 실재 진입점으로 연결됨")
