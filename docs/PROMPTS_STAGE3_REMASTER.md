# Stage 3 폐저자 리마스터 생성 기록 (2026-08-22)

## 실행 경로

- 생성 도구: **Codex 내장 고품질 이미지 생성기(ImageGen)**.
- 생성 원본: `.art_gen/stage3/`(git 제외). 원본 파일명은 `*_source.png`로 통일했다.
- 후처리: `tools/pixel/process_stage3_remaster.gd`가 체크무늬 매팅, Nearest 축소, 지면 atlas 조립, 3×3 소품 분리, 적 애니메이션 strip 조립을 수행한다.
- 최종 게임 자산: `assets/sprites/bg/stage3/`, `assets/tilesets/side/market.png`, `assets/tilesets/market_*.png`, `assets/tilesets/dokkaebi_brazier.png`, `assets/tilesets/ssireum_ring.png`, `assets/sprites/enemies/dokkaebi_{minion,brute,fire}/`.

## 공통 제약

모든 생성 프롬프트에 다음 방향을 공통 적용했다.

> Premium hand-crafted 16-bit pixel art for an orthographic side-scrolling action RPG; crisp hard-edged pixel clusters; nearest-neighbor look; limited 24-color charcoal, soot-brown, old hanji, muted indigo, and cold dokkaebi-blue palette; restrained Joseon Korean folk-horror; no modern objects, Japanese or Chinese architectural motifs, text, labels, borders, logos, watermarks, blur, or smooth vector gradients.

## 최종 프롬프트 세트

### 장터 원경 — `market_far_source.png` → `assets/sprites/bg/stage3/far.png`

> A very wide distant silhouette of a ruined late-Joseon Korean mountain market village at midnight: uneven tiled hanok rooflines, one low pass gate, thin leafless trees, remote charcoal ridges and sparse pinprick lanterns. The market must feel deserted and cursed, not festive. Low contrast, broad quiet shapes, transparent sky, seamless mirrored side edges, no people or monsters.

### 장터 중경 — `market_mid_source.png` → `assets/sprites/bg/stage3/mid.png`

> A very wide middle-distance layer of abandoned Joseon market buildings viewed straight from the side: overlapping giwa roofs, timber shop fronts, torn awnings, crooked sign frames without writing, jars, stacked shutters and narrow alleys. Medium contrast with cold moonlight and tiny restrained amber interiors, transparent above the roofs, continuous baseline, tile-friendly left and right edges.

### 장터 근경 — `market_near_source.png` → `assets/sprites/bg/stage3/near.png`

> A shallow wide foreground silhouette strip for a ruined Joseon night market: collapsed stall edges, low broken carts, baskets, jars, ropes, scraps of straw mat and sparse weeds. Keep the upper two thirds transparent and the playable silhouettes low, deep charcoal with sparse blue rim light, no complete characters or tall view-blocking props.

### 폐저자 지면 — `market_ground_source.png` → `assets/tilesets/side/market.png`

> A seamless orthographic side-view ground cross section for an abandoned Joseon market street. The walkable top is irregular packed earth mixed with worn straw, broken giwa fragments, cart-wheel ruts and a few embedded flat stones; below is compact dark brown soil with small roots, pebbles and buried rubble. One continuous natural cross section, never brickwork or a repeating checkerboard, transparent air above.

### 장터 소품 3×3 atlas — `market_props_source.png`

> Create a strict 3×3 transparent prop atlas with one isolated object in each equal cell, identical pixel density, cold upper-left moonlight and a shared bottom baseline. Row 1: collapsed timber market stall with torn straw mat; intact but deserted canopy stall; broken two-wheel handcart. Row 2: round Korean stone-and-wood market well; low oval ssireum sand ring; stacked jars, baskets and tied bundles. Row 3: old balance scale with empty rice measure and stone weight; iron brazier holding a small cold blue dokkaebi flame; narrow weathered market banner with no writing. Joseon Korean forms only, no scenery, cast shadows, labels or Japanese festival motifs.

### 도깨비불 2×3 atlas — `dokkaebi_fire_source.png`

> Create exactly six animation poses of the same Korean dokkaebi fire in a strict 3×2 transparent grid. It is a floating cold-blue ghost flame with a small soot-dark core and restrained pale cyan edge, eerie rather than cute. Poses progress from compact idle flicker through stretched movement to a bright gathered telegraph and forward-firing attack. Same scale and center in every cell, no face, limbs, lantern, smoke cloud, scenery, border or text.

### 장터 도깨비 3×3 pose atlas — `dokkaebi_minion_source.png`

> Create one original adult Korean dokkaebi market thug in a strict 3×3 transparent pose atlas, facing right. Stocky but smaller than the player's major bosses, short dark horns, broad adult face, rough tied hair, worn brown jeogori and baji, rope belt, straw shoes, and a compact wooden club. Row 1: three idle poses; row 2: three walk poses; row 3: clear attack telegraph, horizontal club strike, defeated collapse. Keep identity, costume, palette, camera, scale and foot baseline identical. Never a child, shirtless generic goblin, oni, samurai, Chinese demon, or cartoon mascot.

### 곤봉 도깨비 3×3 pose atlas — `dokkaebi_brute_source.png`

> Create the same large adult Korean dokkaebi ssireum enforcer in a strict 3×3 transparent pose atlas, facing right. He is visibly larger than the common dokkaebi but smaller than the final chief: thick neck and arms, short dark horns, stern Korean folk-mask-like face, sleeveless dark indigo work vest over muted rust sleeves, loose gray baji, cloth belt, straw shoes, and an oversized gnarled wooden club. Row 1: three heavy idle poses; row 2: three stomping walk poses; row 3: raised-club telegraph, sweeping strike, knocked-down defeat. Preserve exact identity and baseline; no armor, oni styling, sumo mawashi, gore, scenery, labels or extra figures.

## 후처리 규격

- 패럴랙스: `640×190 / 640×220 / 640×150`, Nearest 축소. 런타임 alpha는 원·중·근경 `0.42 / 0.68 / 0.50`.
- 지면: `256×224` atlas. 위 `256×32`는 32px 표면 8변형, 아래 `256×192`는 연속 속재질.
- 소품: 각 3×3 셀의 알파 사용 영역을 추출해 지정 캔버스의 하단 중앙에 맞춘다.
- 일반 도깨비: 프레임 `80×80`, idle 4 / walk 6 / telegraph 3 / attack 4 / death 4.
- 곤봉 도깨비: 프레임 `128×128`, idle 4 / walk 6 / telegraph 3 / attack 4 / death 4.
- 도깨비불: 프레임 `64×64`, 각 애니메이션 3~6프레임.
- 생성기가 투명도 대신 그린 흰색·연회색 체크무늬는 밝은 중성색 매팅으로 실제 알파로 변환했다.
