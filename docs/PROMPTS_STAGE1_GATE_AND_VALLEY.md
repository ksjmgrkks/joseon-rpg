# Stage 1 금줄·잠긴 골짜기 생성 기록 (2026-08-22)

## 결과물과 파이프라인

- 생성 도구: Codex 내장 고품질 이미지 생성기
- 원본(로컬·git 제외): `.art_gen/stage1_reconcept/`
- 후처리: `tools/pixel/process_stage1_gate_and_mudang.gd`
- 금줄: `assets/sprites/fx/gate_geumjul_release.png` — 192×208, 6프레임
- 잠긴 무당: `assets/sprites/enemies/drowned_mudang/` — 160×176, idle 5 / telegraph 5 / attack 5 / death 6
- 범람수: `assets/tilesets/flood_pool_a.png`~`c.png` — 각 256×56

생성기의 흰 체크무늬 배경은 가장자리 flood-fill과 금줄 시트 전용 중성 밝은색 키로 실제 알파 처리했다. 모든 프레임은 Nearest 축소, 공통 배율, 하단 기준선으로 조립한다.

## 금줄 경계석 제작 프롬프트

```text
Create a production-ready animation source sheet for a Joseon Korean folk-horror side-scrolling RPG. Show the same geumjul boundary structure in exactly six sequential release states arranged as a clean 3×2 grid, left-to-right then top-to-bottom. Two low weathered Korean granite posts remain perfectly fixed in every cell. Start with several thick hand-braided rice-straw ropes stretched taut across the path with plain white hanji streamers and tiny tarnished brass bells; progressively loosen, sag, and lower the ropes without an explosion; end with the rope hanging slack near the ground and a completely readable walkable gap. Orthographic side view, identical camera and scale, common ground baseline, premium hand-crafted 16-bit pixel art, crisp hard-edged clusters, limited 24-color charcoal/hanji/granite/straw palette, cold moonlight, transparent background, no scenery, text, labels, characters, shadows, torii, shimenawa, paifang, roofed gate, portal, light pillar, runes, neon, anti-aliasing, or watermark.
```

## 잠긴 무당 디자인 프롬프트

```text
Design one original Joseon-era drowned mudang spirit as a Stage 1 midboss for a premium 16-bit side-scrolling action RPG. She was a human shaman who tried to calm floodwater at a collapsed mountain shrine and drowned there: stern adult face, wet black hair partly covering it, faded white ritual jacket, desaturated indigo skirt, dark mud and water stains, short broken ritual staff with a few plain hanji streamers, restrained pale water wisps around the feet. Human ghost silhouette, dignified and frightening, never cute, no dragon, serpent, imugi, animal monster, gore, zombie exaggeration, Japanese miko clothing, Chinese robes, fantasy armor, text, scenery, or watermark. Orthographic side view facing right, readable between a normal 48px monster and a large final boss, crisp pixel clusters, limited Joseon sumukhwa/hanji palette, transparent background, common foot baseline.
```

## 잠긴 무당 애니메이션 프롬프트 공통 규격

```text
Using the exact same drowned mudang design, create one horizontal animation strip on transparent background. Keep costume, face, body proportions, weapon, palette, camera, scale, and foot baseline identical in every frame. Premium hand-crafted 16-bit pixel art with hard pixel clusters and no interpolation, labels, frame borders, extra figures, scenery, cast shadow, or watermark.
```

- `idle` 5프레임: 젖은 옷자락과 한지 조각만 작게 흔들리고, 몸은 낮게 호흡한다.
- `telegraph` 5프레임: 지팡이를 들며 발치 물결과 옅은 물기운이 모이고 마지막 프레임에서 공격 직전 정지한다.
- `attack` 5프레임: 지팡이를 전방 아래로 내리쳐 낮은 물결을 밀어내며, 마지막에는 자세를 회수한다.
- `death` 6프레임: 무릎이 꺾이고 몸이 물안개와 젖은 한지 조각으로 낮게 가라앉아 사라진다. 고어 없음.

## 얕은 범람수 프롬프트

```text
Create exactly three separate shallow flooded-valley ground overlays in one horizontal row for a Joseon folk-horror side-scrolling RPG: irregular long puddles of dark cold blue-gray water trapped on packed mountain soil, each with a different shoreline silhouette, tiny reeds or one submerged pebble at most, restrained pale ripple highlights, no waterfall, canal, watergate, bridge, boat, architecture, text, border, character, or cast shadow. Orthographic side view, very low and wide, common ground baseline, seamless-looking edges, premium crisp 16-bit pixel art, limited sumukhwa/hanji palette, transparent background.
```
